@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions enabledelayedexpansion
if errorlevel 1 goto NoExtensions

rem clear vars storing parameters
set RESTART_GENERATOR=
set http_proxy=
set https_proxy=

if "%DIRCMD%" NEQ "" set DIRCMD=

cd /D "%~dp0"

set DOWNLOAD_LOGFILE=..\log\download.log
if exist %DOWNLOAD_LOGFILE% (
  echo.>>%DOWNLOAD_LOGFILE%
  echo -------------------------------------------------------------------------------->>%DOWNLOAD_LOGFILE%
  echo.>>%DOWNLOAD_LOGFILE%
)
echo %DATE% %TIME% - Info: Starting WSUS Offline Update - Community Edition - self update>>%DOWNLOAD_LOGFILE%

set CSCRIPT_PATH=%SystemRoot%\System32\cscript.exe
if not exist %CSCRIPT_PATH% goto NoCScript
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set WGET_PATH=..\bin\wget64.exe) else (
  if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" (set WGET_PATH=..\bin\wget64.exe) else (set WGET_PATH=..\bin\wget.exe)
)
if not exist %WGET_PATH% goto NoWGet
if not exist ..\bin\unzip.exe goto NoUnZip
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set HASHDEEP_EXE=hashdeep64.exe) else (
  if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" (set HASHDEEP_EXE=hashdeep64.exe) else (set HASHDEEP_EXE=hashdeep.exe)
)
if not exist ..\client\bin\%HASHDEEP_EXE% goto NoHashDeep

:EvalParams
if "%1"=="" goto NoMoreParams
if /i "%1"=="/restartgenerator" set RESTART_GENERATOR=1
if /i "%1"=="/proxy" (
  set http_proxy=%2
  set https_proxy=%2
  shift /1
)
shift /1
goto EvalParams

:NoMoreParams
rem *** Update WSUS Offline Update - Community Edition ***
title Updating WSUS Offline Update - Community Edition...
if "%http_proxy%" NEQ "" (call CheckOUVersion.cmd /mode:newer /proxy %http_proxy%) else (call CheckOUVersion.cmd /mode:newer)
if not "%errorlevel%"=="1" goto NoNewVersion
if not exist ..\static\SelfUpdateVersion-recent.txt goto DownloadError
echo Downloading most recent released version of WSUS Offline Update - Community Edition...
%WGET_PATH% -N -P ..\static https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/master/StaticDownloadLink-recent.txt
if errorlevel 1 goto DownloadError
if not exist ..\static\StaticDownloadLink-recent.txt goto DownloadError
set FILENAME_ZIP=
set FILENAME_HASH=
set bufFILENAME=
for /f "delims=" %%u in (..\static\StaticDownloadLink-recent.txt) do (
  for /f "delims=" %%f in ('%CSCRIPT_PATH% //Nologo //E:vbs ExtractFileNameFromURL.vbs "%%u"') do (
    set bufFILENAME=%%f
    if "!bufFILENAME:~-4!"==".zip" (
      set FILENAME_ZIP=%%f
    ) else if "!bufFILENAME:~-4!"==".txt" (
      set FILENAME_HASH=%%f
    )
  )
)
if "%FILENAME_ZIP%"=="" (
  rem failed to determine file name
  goto DownloadError
)
if "%FILENAME_HASH%"=="" (
  rem failed to determine file name
  goto DownloadError
)
%WGET_PATH% -N -P .. -i ..\static\StaticDownloadLink-recent.txt
if errorlevel 1 goto DownloadError
if not exist "..\%FILENAME_ZIP%" (
  if exist "..\%FILENAME_HASH%" del "..\%FILENAME_HASH%"
  goto DownloadError
)
if not exist "..\%FILENAME_HASH%" (
  if exist "..\%FILENAME_ZIP%" del "..\%FILENAME_ZIP%"
  goto DownloadError
)
echo %DATE% %TIME% - Info: Downloaded most recent released version of WSUS Offline Update - Community Edition>>%DOWNLOAD_LOGFILE%
pushd ..
echo Verifying integrity of %FILENAME_ZIP%...
.\client\bin\%HASHDEEP_EXE% -a -l -vv -k %FILENAME_HASH% %FILENAME_ZIP%
if errorlevel 1 (
  popd
  goto IntegrityError
)
popd
echo %DATE% %TIME% - Info: Verified integrity of %FILENAME_ZIP%>>%DOWNLOAD_LOGFILE%
echo Unpacking %FILENAME_ZIP%...
if exist ..\wsusoffline\nul rd /S /Q ..\wsusoffline
..\bin\unzip.exe -uq ..\%FILENAME_ZIP% -d ..
echo %DATE% %TIME% - Info: Unpacked %FILENAME_ZIP%>>%DOWNLOAD_LOGFILE%
del ..\%FILENAME_ZIP%
echo %DATE% %TIME% - Info: Deleted %FILENAME_ZIP%>>%DOWNLOAD_LOGFILE%
del ..\%FILENAME_HASH%
echo %DATE% %TIME% - Info: Deleted %FILENAME_HASH%>>%DOWNLOAD_LOGFILE%
echo Preserving custom language and architecture additions and removals...
set REMOVE_CMD=
%SystemRoot%\System32\find.exe /I "-deu." ..\static\StaticDownloadLinks-dotnet.txt >nul 2>&1
if errorlevel 1 (
  set REMOVE_CMD=RemoveGermanLanguageSupport.cmd !REMOVE_CMD!
)
set CUST_LANG=
if exist ..\static\custom\StaticDownloadLinks-dotnet.txt (
  for %%i in (fra esn jpn kor rus ptg ptb nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do (
    %SystemRoot%\System32\find.exe /I "%%i" ..\static\custom\StaticDownloadLinks-dotnet.txt >nul 2>&1
    if not errorlevel 1 (
      set CUST_LANG=%%i !CUST_LANG!
      call RemoveCustomLanguageSupport.cmd %%i /quiet
    )
  )
)
set OX64_LANG=
for %%i in (enu fra esn jpn kor rus ptg ptb deu nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do (
  if exist ..\static\custom\StaticDownloadLinks-o2k13-%%i.txt (
    set OX64_LANG=%%i !OX64_LANG!
    call RemoveOffice2010x64Support.cmd %%i /quiet
  )
)
echo %DATE% %TIME% - Info: Preserved custom language and architecture additions and removals>>%DOWNLOAD_LOGFILE%
echo Updating WSUS Offline Update - Community Edition...
%SystemRoot%\System32\xcopy.exe ..\wsusoffline .. /S /Q /Y
rd /S /Q ..\wsusoffline
echo %DATE% %TIME% - Info: Updated WSUS Offline Update - Community Edition>>%DOWNLOAD_LOGFILE%
echo Restoring custom language and architecture additions and removals...
if "%REMOVE_CMD%" NEQ "" (
  for %%i in (%REMOVE_CMD%) do call %%i /quiet
)
if "%CUST_LANG%" NEQ "" (
  for %%i in (%CUST_LANG%) do call AddCustomLanguageSupport.cmd %%i /quiet
)
if "%OX64_LANG%" NEQ "" (
  for %%i in (%OX64_LANG%) do call AddOffice2010x64Support.cmd %%i /quiet
)
echo %DATE% %TIME% - Info: Restored custom language and architecture additions and removals>>%DOWNLOAD_LOGFILE%
if exist ..\exclude\ExcludeList-superseded.txt (
  del ..\exclude\ExcludeList-superseded.txt
  echo %DATE% %TIME% - Info: Deleted deprecated list of superseded updates>>%DOWNLOAD_LOGFILE%
)
if exist ..\static\sdd\StaticDownloadFiles-modified.txt (
  del ..\static\sdd\StaticDownloadFiles-modified.txt
)
if exist ..\static\sdd\ExcludeDownloadFiles-modified.txt (
  del ..\static\sdd\ExcludeDownloadFiles-modified.txt
)
if exist ..\static\sdd\StaticUpdateFiles-modified.txt (
  del ..\static\sdd\StaticUpdateFiles-modified.txt
)
echo %DATE% %TIME% - Info: Ending WSUS Offline Update - Community Edition - self update>>%DOWNLOAD_LOGFILE%
if "%RESTART_GENERATOR%"=="1" (
  cd ..
  start UpdateGenerator.exe
  exit
)
goto EoF

:NoExtensions
echo.
echo ERROR: No command extensions available.
echo.
exit

:NoCScript
echo.
echo ERROR: VBScript interpreter %CSCRIPT_PATH% not found.
echo %DATE% %TIME% - Error: VBScript interpreter %CSCRIPT_PATH% not found>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:NoWGet
echo.
echo ERROR: Download utility %WGET_PATH% not found.
echo %DATE% %TIME% - Error: Download utility %WGET_PATH% not found>>%DOWNLOAD_LOGFILE%
echo.
goto EoF

:NoUnZip
echo.
echo ERROR: Utility ..\bin\unzip.exe not found.
echo %DATE% %TIME% - Error: Utility ..\bin\unzip.exe not found>>%DOWNLOAD_LOGFILE%
echo.
goto EoF

:NoHashDeep
echo.
echo ERROR: Hash computing/auditing utility ..\client\bin\%HASHDEEP_EXE% not found.
echo %DATE% %TIME% - Error: Hash computing/auditing utility ..\client\bin\%HASHDEEP_EXE% not found>>%DOWNLOAD_LOGFILE%
echo.
goto EoF

:NoNewVersion
echo.
echo Info: No new version of WSUS Offline Update - Community Edition - found.
echo %DATE% %TIME% - Info: No new version of WSUS Offline Update - Community Edition - found>>%DOWNLOAD_LOGFILE%
echo.
goto EoF

:DownloadError
echo.
echo ERROR: Download of most recent released version of WSUS Offline Update - Community Edition - failed.
echo %DATE% %TIME% - Error: Download of most recent released version of WSUS Offline Update - Community Edition - failed>>%DOWNLOAD_LOGFILE%
echo.
goto EoF

:IntegrityError
echo.
echo ERROR: File integrity verification of most recent released version of WSUS Offline Update - Community Edition - failed.
echo %DATE% %TIME% - Error: File integrity verification of most recent released version of WSUS Offline Update - Community Edition - failed>>%DOWNLOAD_LOGFILE%
echo.
goto EoF

:EoF
title %ComSpec%
endlocal
