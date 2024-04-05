@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions enabledelayedexpansion
if errorlevel 1 goto NoExtensions

rem clear vars storing parameters
set SELECT_OPTIONS=
set VERIFY_FILES=
set ERRORS_AS_WARNINGS=
set IGNORE_ERRORS=

set RECALL_REQUIRED=
set REBOOT_REQUIRED=

if "%DIRCMD%" NEQ "" set DIRCMD=
if "%UPDATE_LOGFILE%"=="" set UPDATE_LOGFILE=%SystemRoot%\wsusofflineupdate.log
if "%HASHDEEP_PATH%"=="" (
  if /i "%OS_ARCH%"=="x64" (set HASHDEEP_PATH=..\bin\hashdeep64.exe) else (set HASHDEEP_PATH=..\bin\hashdeep.exe)
)

if "%~1"=="" goto NoParam

set FILE_FULL_PATH=%~1

set SpaceHelper=
:RemoveSpaces
if "%FILE_FULL_PATH:~-1%"==" " (
  set FILE_FULL_PATH=%FILE_FULL_PATH:~0,-1%
  set SpaceHelper=%SpaceHelper% 
  goto RemoveSpaces
)

if "%FILE_FULL_PATH%"=="%~1" goto FileFullPathParsed
if not "%SpaceHelper%"=="" if "%FILE_FULL_PATH%%SpaceHelper%"=="%~1" goto FileFullPathParsed
goto InvalidParam
:FileFullPathParsed
if not exist "%FILE_FULL_PATH%" goto ParamFileNotFound

set FILE_NAME=
for /F %%i in ("%FILE_FULL_PATH%") do (
  set FILE_NAME=%%~nxi
)
if "%FILE_NAME%"=="" goto ParamInvalidFileName

if "%TEMP%"=="" goto NoTemp
pushd "%TEMP%"
if errorlevel 1 goto NoTempDir
popd

shift /1
:EvalParams
if "%~1"=="" goto NoMoreParams
if /i "%~1"=="/selectoptions" (
  set SELECT_OPTIONS=1
  shift /1
  goto EvalParams
)
if /i "%~1"=="/verify" (
  set VERIFY_FILES=1
  shift /1
  goto EvalParams
)
if /i "%~1"=="/errorsaswarnings" (
  set ERRORS_AS_WARNINGS=1
  shift /1
  goto EvalParams
)
if /i "%~1"=="/ignoreerrors" (
  set IGNORE_ERRORS=1
  shift /1
  goto EvalParams
)

:NoMoreParams
if "%VERIFY_FILES%" NEQ "1" goto SkipVerification
if not exist %HASHDEEP_PATH% (
  echo Warning: Hash computing/auditing utility %HASHDEEP_PATH% not found.
  echo %DATE% %TIME% - Warning: Hash computing/auditing utility %HASHDEEP_PATH% not found>>%UPDATE_LOGFILE%
  goto SkipVerification
)
echo Verifying integrity of %FILE_FULL_PATH%...
rem FIXME: This expects a relative path and might fail, when an absolute path is passed
for /F "tokens=2,3 delims=\" %%i in ("%FILE_FULL_PATH%") do (
  if exist ..\md\hashes-%%i-%%j.txt (
    %SystemRoot%\System32\findstr.exe /L /I /C:%% /C:%FILE_NAME% ..\md\hashes-%%i-%%j.txt >"%TEMP%\hash-%%i-%%j.txt"
    %HASHDEEP_PATH% -a -b -k "%TEMP%\hash-%%i-%%j.txt" "%FILE_FULL_PATH%"
    if errorlevel 1 (
      if exist "%TEMP%\hash-%%i-%%j.txt" del "%TEMP%\hash-%%i-%%j.txt"
      goto IntegrityError
    )
    if exist "%TEMP%\hash-%%i-%%j.txt" del "%TEMP%\hash-%%i-%%j.txt"
    goto SkipVerification
  )
  if exist ..\md\hashes-%%i.txt (
    %SystemRoot%\System32\findstr.exe /L /I /C:%% /C:%FILE_NAME% ..\md\hashes-%%i.txt >"%TEMP%\hash-%%i.txt"
    %HASHDEEP_PATH% -a -b -k "%TEMP%\hash-%%i.txt" "%FILE_FULL_PATH%"
    if errorlevel 1 (
      if exist "%TEMP%\hash-%%i.txt" del "%TEMP%\hash-%%i.txt"
      goto IntegrityError
    )
    if exist "%TEMP%\hash-%%i.txt" del "%TEMP%\hash-%%i.txt"
    goto SkipVerification
  )
  echo Warning: Hash files ..\md\hashes-%%i-%%j.txt and ..\md\hashes-%%i.txt not found.
  echo %DATE% %TIME% - Warning: Hash files ..\md\hashes-%%i-%%j.txt and ..\md\hashes-%%i.txt not found>>%UPDATE_LOGFILE%
)
:SkipVerification
if "%FILE_FULL_PATH:~-4%"==".exe" goto InstExe
if "%FILE_FULL_PATH:~-4%"==".cab" goto InstCab
if "%FILE_FULL_PATH:~-4%"==".msp" goto InstMsp
goto UnsupType

:InstExe
if "%SELECT_OPTIONS%" NEQ "1" (
  rem This can be improved by using %*, but %* is not affected by shift-operations
  set INSTALL_SWITCHES=%1 %2 %3 %4 %5 %6 %7 %8 %9
) else (
  set INSTALL_SWITCHES=
)
rem remove spaces at begin/end of "INSTALL_SWITCHES"
:InstExe_CleanSwitchBegin
if "!INSTALL_SWITCHES!"=="" goto InstExe_Cleaned
if "!INSTALL_SWITCHES:~0,1!"==" " (
  set INSTALL_SWITCHES=!INSTALL_SWITCHES:~1!
  goto InstExe_CleanSwitchBegin
)
:InstExe_CleanSwitchEnd
if "!INSTALL_SWITCHES!"=="" goto InstExe_Cleaned
if "!INSTALL_SWITCHES:~-1!"==" " (
  set INSTALL_SWITCHES=!INSTALL_SWITCHES:~0,-1!
  goto InstExe_CleanSwitchEnd
)
:InstExe_Cleaned
if "!INSTALL_SWITCHES!"=="" (
  if exist ..\opt\OptionList.txt (
    for /F "tokens=1,2 delims=," %%a in (..\opt\OptionList.txt) do (
      if "%FILE_NAME%"=="%%a" (
        set INSTALL_SWITCHES=%%b
        rem echo InstallOfficeUpdate: Found match in OptionList.txt for %FILE_NAME%, install switches set to "%%b"
        goto InstExe_FoundOptions
      )
    )
  )
)
if "!INSTALL_SWITCHES!"=="" (
  if exist ..\opt\OptionList-wildcard.txt (
    for /F "tokens=1,2 delims=," %%a in (..\opt\OptionList-wildcard.txt) do (
      echo %FILE_NAME% | %SystemRoot%\System32\find.exe /I "%%a" >nul 2>&1
      if not errorlevel 1 (
        set INSTALL_SWITCHES=%%b
        rem echo InstallOfficeUpdate: Found match in OptionList-wildcard.txt for %FILE_NAME% ^(^*%%a^*^), install switches set to "%%b"
        goto InstExe_FoundOptions
      )
    )
  )
)
if "!INSTALL_SWITCHES!"=="" (
  set INSTALL_SWITCHES=/quiet /norestart
  rem echo InstallOfficeUpdate: Using default install switches "/quiet /norestart"
)
:InstExe_FoundOptions
echo Installing %FILE_FULL_PATH%...
"%FILE_FULL_PATH%" !INSTALL_SWITCHES!
set ERR_LEVEL=%errorlevel%
rem echo InstallOfficeUpdate: ERR_LEVEL=%ERR_LEVEL%
if "%ERR_LEVEL%"=="0" (
  goto InstSuccess
) else if "%ERR_LEVEL%"=="1641" (
  set REBOOT_REQUIRED=1
  goto InstSuccess
) else if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
  goto InstSuccess
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
  goto InstSuccess
)
if "%IGNORE_ERRORS%"=="1" goto InstSuccess
goto InstFailure

:InstCab
echo Installing %FILE_FULL_PATH%...
set ERR_LEVEL=0
for /F "tokens=3 delims=\." %%i in ("%FILE_FULL_PATH%") do (
  call SafeRmDir.cmd "%TEMP%\%%i"
  md "%TEMP%\%%i"
  %SystemRoot%\System32\expand.exe -R "%FILE_FULL_PATH%" -F:* "%TEMP%\%%i" >nul
  for /F %%j in ('dir /A:-D /B "%TEMP%\%%i\*.msp"') do %SystemRoot%\System32\msiexec.exe /qn /norestart /update "%TEMP%\%%i\%%j"
  set ERR_LEVEL=%errorlevel%
  call SafeRmDir.cmd "%TEMP%\%%i"
)
rem echo InstallOfficeUpdate: ERR_LEVEL=%ERR_LEVEL%
if "%ERR_LEVEL%"=="0" (
  goto InstSuccess
) else if "%ERR_LEVEL%"=="1641" (
  set REBOOT_REQUIRED=1
  goto InstSuccess
) else if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
  goto InstSuccess
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
  goto InstSuccess
)
if "%IGNORE_ERRORS%"=="1" goto InstSuccess
goto InstFailure

:InstMsp
echo Installing %FILE_FULL_PATH%...
set ERR_LEVEL=0
%SystemRoot%\System32\msiexec.exe /qn /norestart /update "%FILE_FULL_PATH%"
set ERR_LEVEL=%errorlevel%
rem echo InstallOfficeUpdate: ERR_LEVEL=%ERR_LEVEL%
if "%ERR_LEVEL%"=="0" (
  goto InstSuccess
) else if "%ERR_LEVEL%"=="1641" (
  set REBOOT_REQUIRED=1
  goto InstSuccess
) else if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
  goto InstSuccess
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
  goto InstSuccess
)
if "%IGNORE_ERRORS%"=="1" goto InstSuccess
goto InstFailure

:NoExtensions
echo ERROR: No command extensions available.
goto Error

:NoParam
echo ERROR: Invalid parameter. Usage: %~n0 ^<filename^> [/selectoptions] [/verify] [/errorsaswarnings] [/ignoreerrors] [switches]
echo %DATE% %TIME% - Error: Invalid parameter. Usage: %~n0 ^<filename^> [/selectoptions] [/verify] [/errorsaswarnings] [/ignoreerrors] [switches]>>%UPDATE_LOGFILE%
goto Error

:InvalidParam
echo ERROR: Invalid file %FILE_FULL_PATH%
echo %DATE% %TIME% - Error: Invalid file %FILE_FULL_PATH%>>%UPDATE_LOGFILE%
goto Error

:ParamFileNotFound
echo ERROR: File %FILE_FULL_PATH% not found.
echo %DATE% %TIME% - Error: File %FILE_FULL_PATH% not found>>%UPDATE_LOGFILE%
goto Error

:ParamInvalidFileName
echo ERROR: Invalid file name %FILE_FULL_PATH%
echo %DATE% %TIME% - Error: Invalid file name %FILE_FULL_PATH%>>%UPDATE_LOGFILE%
goto Error

:NoTemp
echo ERROR: Environment variable TEMP not set.
echo %DATE% %TIME% - Error: Environment variable TEMP not set>>%UPDATE_LOGFILE%
goto Error

:NoTempDir
echo ERROR: Directory "%TEMP%" not found.
echo %DATE% %TIME% - Error: Directory "%TEMP%" not found>>%UPDATE_LOGFILE%
goto Error

:UnsupType
echo ERROR: Unsupported file type (file: %FILE_FULL_PATH%).
echo %DATE% %TIME% - Error: Unsupported file type (file: %FILE_FULL_PATH%)>>%UPDATE_LOGFILE%
goto InstFailure

:IntegrityError
echo ERROR: File hash does not match stored value (file: %FILE_FULL_PATH%).
echo %DATE% %TIME% - Error: File hash does not match stored value (file: %FILE_FULL_PATH%)>>%UPDATE_LOGFILE%
goto InstFailure

:InstSuccess
echo %DATE% %TIME% - Info: Installed %FILE_FULL_PATH%>>%UPDATE_LOGFILE%
goto EoF

:InstFailure
if "%IGNORE_ERRORS%"=="1" goto EoF
if "%ERRORS_AS_WARNINGS%"=="1" (goto InstWarning) else (goto InstError)

:InstWarning
echo Warning: Installation of %FILE_FULL_PATH% failed (errorlevel: %ERR_LEVEL%).
echo %DATE% %TIME% - Warning: Installation of %FILE_FULL_PATH% failed (errorlevel: %ERR_LEVEL%)>>%UPDATE_LOGFILE%
goto EoF

:InstError
echo ERROR: Installation of %FILE_FULL_PATH% failed (errorlevel: %ERR_LEVEL%).
echo %DATE% %TIME% - Error: Installation of %FILE_FULL_PATH% failed (errorlevel: %ERR_LEVEL%)>>%UPDATE_LOGFILE%
goto Error

:Error
endlocal
exit /b 1

:EoF
if "%RECALL_REQUIRED%"=="1" (
  endlocal
  exit /b 3011
) else if "%REBOOT_REQUIRED%"=="1" (
  endlocal
  exit /b 3010
) else (
  endlocal
  exit /b 0
)
