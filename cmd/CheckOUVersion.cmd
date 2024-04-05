@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions
if errorlevel 1 goto NoExtensions

rem clear vars storing parameters
set CheckOUVersion_mode=
set QUIET_MODE=
set EXIT_ERR=
set http_proxy=
set https_proxy=

cd /D "%~dp0"

set CSCRIPT_PATH=%SystemRoot%\System32\cscript.exe
if not exist %CSCRIPT_PATH% goto NoCScript
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set WGET_PATH=..\bin\wget64.exe) else (
  if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" (set WGET_PATH=..\bin\wget64.exe) else (set WGET_PATH=..\bin\wget.exe)
)
if not exist %WGET_PATH% goto NoWGet

:EvalParams
if "%1"=="" goto NoMoreParams
if /i "%1"=="/mode:different" set CheckOUVersion_mode=different
if /i "%1"=="/mode:newer" set CheckOUVersion_mode=newer
if /i "%1"=="/quiet" set QUIET_MODE=1
if /i "%1"=="/exitonerror" set EXIT_ERR=1
if /i "%1"=="/proxy" (
  set http_proxy=%2
  set https_proxy=%2
  shift /1
)
shift /1
goto EvalParams

:NoMoreParams
rem *** Check WSUS Offline Update - Community Edition - version ***
if "%CheckOUVersion_mode%"=="" goto MissingArgument
if "%QUIET_MODE%"=="1" goto justCheckForUpdates
title Checking WSUS Offline Update - Community Edition - version...
echo Checking WSUS Offline Update - Community Edition - version...
if exist UpdateOU.new (
  if exist UpdateOU.cmd del UpdateOU.cmd
  ren UpdateOU.new UpdateOU.cmd
)
:justCheckForUpdates
if "%QUIET_MODE%"=="1" (
  %WGET_PATH% -q -N -P ..\static https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/master/SelfUpdateVersion-recent.txt
) else (
  %WGET_PATH% -N -P ..\static https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/master/SelfUpdateVersion-recent.txt
)
if errorlevel 1 goto DownloadError
if not exist ..\static\SelfUpdateVersion-recent.txt goto DownloadError

rem Now compare the versions
set CheckOUVersion_version_this=
set CheckOUVersion_version_recent=
set CheckOUVersion_type_this=
set CheckOUVersion_type_recent=
for /f "tokens=1,2 delims=," %%a in (..\static\SelfUpdateVersion-this.txt) do (
  set CheckOUVersion_version_this=%%a
  set CheckOUVersion_type_this=%%b
)
for /f "tokens=1,2 delims=," %%a in (..\static\SelfUpdateVersion-recent.txt) do (
  set CheckOUVersion_version_recent=%%a
  set CheckOUVersion_type_recent=%%b
)
if "%CheckOUVersion_version_this%"=="" (goto CompError)
if "%CheckOUVersion_version_recent%"=="" (goto CompError)

%CSCRIPT_PATH% //Nologo //B //E:vbs ..\client\cmd\CompareVersions.vbs %CheckOUVersion_version_this% %CheckOUVersion_version_recent%
set CheckOUVersion_result=%errorlevel%
if "%CheckOUVersion_result%"=="0" (
  rem %errorlevel%==0 -> equal
  if "%CheckOUVersion_type_this%"=="%CheckOUVersion_type_recent%" (goto Result_OK) else (goto Result_UpdateAvailable)
) else if "%CheckOUVersion_result%"=="2" (
  rem %errorlevel%==2 -> this > recent
  if "%CheckOUVersion_mode%"=="different" (goto Result_UpdateAvailable) else (goto Result_OK)
) else if "%CheckOUVersion_result%"=="3" (
  rem %errorlevel%==3 -> this < recent
  goto Result_UpdateAvailable
)
rem %errorlevel%==1 -> Error
goto Error

:NoExtensions
if not "%QUIET_MODE%"=="1" (
  echo.
  echo ERROR: No command extensions available.
  echo.
)
exit

:NoCScript
if not "%QUIET_MODE%"=="1" (
  echo.
  echo ERROR: VBScript interpreter %CSCRIPT_PATH% not found.
  echo.
)
goto Error

:NoWGet
if not "%QUIET_MODE%"=="1" (
  echo.
  echo ERROR: Utility %WGET_PATH% not found.
  echo.
)
goto Error

:MissingArgument
if not "%QUIET_MODE%"=="1" (
  echo.
  echo ERROR: Missing argument "/mode:different" or "/mode:newer".
  echo.
)
goto Error

:DownloadError
if not "%QUIET_MODE%"=="1" (
  echo.
  echo ERROR: Download failure for https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/master/SelfUpdateVersion-recent.txt.
  echo.
)
goto Error

:CompError
if not "%QUIET_MODE%"=="1" (
  echo.
  echo Warning: File ..\static\SelfUpdateVersion-this.txt differs from file ..\static\SelfUpdateVersion-recent.txt.
  echo.
)
goto Error

:Error
if "%EXIT_ERR%"=="1" (
  endlocal
  exit 2
) else (
  title %ComSpec%
  endlocal
  exit /b 2
)

:Result_UpdateAvailable
if "%EXIT_ERR%"=="1" (
  endlocal
  exit 1
) else (
  title %ComSpec%
  endlocal
  exit /b 1
)

:Result_OK
title %ComSpec%
endlocal
exit /b 0
