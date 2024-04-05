@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions
if errorlevel 1 goto NoExtensions

rem clear vars storing parameters
set OUTPUT_PATH=
set EXC_SW=
set INC_DOTNET=
set INC_WDDEFS=
set CLEANUP=
set EXIT_ERR=

cd /D "%~dp0"

title %~n0 %1 %2 %3 %4 %5 %6 %7 %8 %9
echo Starting copying for %1 %2 %3 %4 %5 %6 %7 %8 %9...
set DOWNLOAD_LOGFILE=..\log\download.log
rem *** Execute custom initialization hook ***
if exist .\custom\InitializationHook.cmd (
  echo Executing custom initialization hook...
  pushd .\custom
  call InitializationHook.cmd
  set ERR_LEVEL=%errorlevel%
  popd
)
if exist %DOWNLOAD_LOGFILE% (
  echo.>>%DOWNLOAD_LOGFILE%
  echo -------------------------------------------------------------------------------->>%DOWNLOAD_LOGFILE%
  echo.>>%DOWNLOAD_LOGFILE%
)
if exist .\custom\InitializationHook.cmd (
  echo %DATE% %TIME% - Info: Executed custom initialization hook ^(Errorlevel: %ERR_LEVEL%^)>>%DOWNLOAD_LOGFILE%
  set ERR_LEVEL=
)
echo %DATE% %TIME% - Info: Starting copying for %1 %2 %3 %4 %5 %6 %7 %8 %9>>%DOWNLOAD_LOGFILE%

if "%TEMP%"=="" goto NoTemp
pushd "%TEMP%"
if errorlevel 1 goto NoTempDir
popd

for %%i in (all all-x86 all-x64 enu fra esn jpn kor rus ptg ptb deu nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do (if /i "%~1"=="%%i" goto V1EvalParams)
for %%i in (o2k13) do (
  if /i "%~1"=="%%i" (
    for %%j in (glb enu fra esn jpn kor rus ptg ptb deu nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do (if /i "%~2"=="%%j" goto V2EvalParams)
    goto V1EvalParams
  )
)
for %%i in (w60 w60-x64 w61 w61-x64 w62-x64 w63 w63-x64 w100 w100-x64 o2k16) do (
  if /i "%~1"=="%%i" (
    if /i "%~2"=="glb" shift /2
    goto V1EvalParams
  )
)
goto InvalidParams

:V1EvalParams
if %OUTPUT_PATH%~==~ (
  if %2~==~ (goto InvalidParams) else (set OUTPUT_PATH=%2)
  shift /2
)
if "%2"=="" goto V1CreateFilter
if /i "%2"=="/excludesw" set EXC_SW=1
if /i "%2"=="/includedotnet" set INC_DOTNET=1
if /i "%2"=="/includewddefs" set INC_WDDEFS=1
if /i "%2"=="/cleanup" set CLEANUP=1
if /i "%2"=="/exitonerror" set EXIT_ERR=1
shift /2
goto V1EvalParams

:V2EvalParams
if %OUTPUT_PATH%~==~ (
  if %3~==~ (goto InvalidParams) else (set OUTPUT_PATH=%3)
  shift /3
)
if "%3"=="" goto V2CreateFilter
if /i "%3"=="/excludesw" set EXC_SW=1
if /i "%3"=="/includedotnet" set INC_DOTNET=1
if /i "%3"=="/includewddefs" set INC_WDDEFS=1
if /i "%3"=="/cleanup" set CLEANUP=1
if /i "%3"=="/exitonerror" set EXIT_ERR=1
shift /3
goto V2EvalParams

:CopyFilter
rem *** Copy USB filter ***
if exist ..\exclude\ExcludeListUSB-%1.txt (
  copy /Y ..\exclude\ExcludeListUSB-%1.txt %USB_FILTER% >nul
) else (
  copy /Y ..\exclude\ExcludeListUSB-%1-x86.txt %USB_FILTER% >nul
)
if exist ..\exclude\custom\ExcludeListUSB-%1.txt (
  type ..\exclude\custom\ExcludeListUSB-%1.txt >>%USB_FILTER%
)
if exist ..\exclude\custom\ExcludeListUSB-%1-x86.txt (
  type ..\exclude\custom\ExcludeListUSB-%1-x86.txt >>%USB_FILTER%
)
goto :eof

:LocaleFilter
for %%i in (enu fra esn jpn kor rus ptg ptb deu nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do (
  if /i "%1" NEQ "%%i" (
    echo %%i\>>%USB_FILTER%
  )
)
goto :eof

:ExtendFilter
if "%EXC_SW%"=="1" (
  type ..\exclude\ExcludeList-software.txt >>%USB_FILTER%
)
if "%INC_DOTNET%" NEQ "1" (
  type ..\exclude\ExcludeListISO-dotnet.txt >>%USB_FILTER%
)
if "%INC_WDDEFS%" NEQ "1" (
  type ..\exclude\ExcludeList-wddefs.txt >>%USB_FILTER%
)
goto :eof

:V1CreateFilter
rem *** Create USB filter ***
echo Creating USB filter for %1...
set USB_FILTER="%TEMP%\ExcludeListUSB-%1.txt"
for %%i in (all all-x86 all-x64 w60 w60-x64 w61 w61-x64 w62-x64 w63 w63-x64 w100 w100-x64 o2k13 o2k16) do (if /i "%1"=="%%i" goto V1CopyFilter)
copy /Y ..\exclude\ExcludeListUSB-all-x86.txt %USB_FILTER% >nul
if exist ..\exclude\custom\ExcludeListUSB-all-x86.txt (
  type ..\exclude\custom\ExcludeListUSB-all-x86.txt >>%USB_FILTER%
)
call :LocaleFilter %1
call :ExtendFilter
goto CreateImage

:V1CopyFilter
call :CopyFilter %1
call :ExtendFilter
goto CreateImage

:V2CreateFilter
rem *** Create USB filter ***
echo Creating USB filter for %1 %2...
set USB_FILTER="%TEMP%\ExcludeListUSB-%1-%2.txt"
call :CopyFilter %1
call :LocaleFilter %2
call :ExtendFilter
goto CreateImage

:CreateImage
rem *** Copy client tree ***
if not exist %SystemRoot%\System32\xcopy.exe goto NoXCopy
echo Copying client tree for %1 %2 %3 %4 %5 %6 %7 %8 %9...
for %%i in (%USB_FILTER%) do (
  pushd "%%~dpi"
  %SystemRoot%\System32\xcopy.exe "%~dp0..\client\*.*" %OUTPUT_PATH% /D /E /I /Y /EXCLUDE:%%~nxi
  if errorlevel 1 (
    popd
    if exist %USB_FILTER% del %USB_FILTER%
    goto XCopyError
  )
)
popd
if exist %USB_FILTER% del %USB_FILTER%
echo %DATE% %TIME% - Info: Copied client tree for %1 %2 %3 %4 %5 %6 %7 %8 %9>>%DOWNLOAD_LOGFILE%

rem *** Clean up target directory ***
if "%CLEANUP%" NEQ "1" goto NoCleanup
echo Cleaning up target directory %OUTPUT_PATH%...
dir ..\client /A:-D /B /S >"%TEMP%\ValidClientFiles.txt"
for /F "tokens=*" %%i in ('dir %OUTPUT_PATH% /A:-D /B /S') do (
  %SystemRoot%\System32\find.exe /I "%%~nxi" "%TEMP%\ValidClientFiles.txt" >nul 2>&1
  if errorlevel 1 (
    del "%%i"
    echo %DATE% %TIME% - Info: Deleted file "%%i">>%DOWNLOAD_LOGFILE%
  )
)
del "%TEMP%\ValidClientFiles.txt"
echo %DATE% %TIME% - Info: Cleaned up target directory %OUTPUT_PATH%>>%DOWNLOAD_LOGFILE%

:NoCleanup
goto EoF

:NoExtensions
echo.
echo ERROR: No command extensions available.
echo.
exit /b 1

:NoTemp
echo.
echo ERROR: Environment variable TEMP not set.
echo %DATE% %TIME% - Error: Environment variable TEMP not set>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:NoTempDir
echo.
echo ERROR: Directory "%TEMP%" not found.
echo %DATE% %TIME% - Error: Directory "%TEMP%" not found>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:InvalidParams
echo.
echo ERROR: Invalid parameter: %*
echo Usage1: %~n0 {all ^| all-x86 ^| all-x64 ^| enu ^| fra ^| esn ^| jpn ^| kor ^| rus ^| ptg ^| ptb ^| deu ^| nld ^| ita ^| chs ^| cht ^| plk ^| hun ^| csy ^| sve ^| trk ^| ell ^| ara ^| heb ^| dan ^| nor ^| fin} ^<OutputPath^> [/excludesw] [/includedotnet] [/includewddefs] [/cleanup]
echo Usage2: %~n0 {o2k13} {glb ^| enu ^| fra ^| esn ^| jpn ^| kor ^| rus ^| ptg ^| ptb ^| deu ^| nld ^| ita ^| chs ^| cht ^| plk ^| hun ^| csy ^| sve ^| trk ^| ell ^| ara ^| heb ^| dan ^| nor ^| fin} ^<OutputPath^> [/excludesw] [/includedotnet] [/includewddefs] [/cleanup]
echo Usage3: %~n0 {w60 ^| w60-x64 ^| w61 ^| w61-x64 ^| w62-x64 ^| w63 ^| w63-x64 ^| w100 ^| w100-x64 ^| o2k16} [glb] ^<OutputPath^> [/excludesw] [/includedotnet] [/includewddefs] [/cleanup]
echo %DATE% %TIME% - Error: Invalid parameter: %*>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:NoXCopy
echo.
echo ERROR: Utility %SystemRoot%\System32\xcopy.exe not found.
echo %DATE% %TIME% - Error: Utility %SystemRoot%\System32\xcopy.exe not found>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:XCopyError
echo.
echo ERROR: Copying failed.
echo %DATE% %TIME% - Error: Copying failed>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:Error
if "%EXIT_ERR%"=="1" (
  endlocal
  pause
  verify other 2>nul
  exit
) else (
  title %ComSpec%
  endlocal
  verify other 2>nul
  goto :eof
)

:EoF
rem *** Execute custom finalization hook ***
if exist .\custom\FinalizationHook.cmd (
  echo Executing custom finalization hook...
  pushd .\custom
  call FinalizationHook.cmd
  popd
  echo %DATE% %TIME% - Info: Executed custom finalization hook ^(Errorlevel: %errorlevel%^)>>%DOWNLOAD_LOGFILE%
)
echo %DATE% %TIME% - Info: Ending copying for %1 %2 %3 %4 %5 %6 %7 %8 %9>>%DOWNLOAD_LOGFILE%
title %ComSpec%
endlocal
