@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions
if errorlevel 1 goto NoExtensions

rem clear vars storing parameters
set http_proxy=
set https_proxy=
set JUST_RELOAD=

if "%DIRCMD%" NEQ "" set DIRCMD=

cd /D "%~dp0"

:EvalParams
if "%1"=="" goto NoMoreParams
if /i "%1"=="/reload" set JUST_RELOAD=1
if /i "%1"=="/proxy" (
  set http_proxy=%2
  set https_proxy=%2
  shift /1
)
shift /1
goto EvalParams

:NoMoreParams
if "%JUST_RELOAD%"=="1" goto Reload
set DOWNLOAD_LOGFILE=..\log\download.log
if exist %DOWNLOAD_LOGFILE% (
  echo.>>%DOWNLOAD_LOGFILE%
  echo -------------------------------------------------------------------------------->>%DOWNLOAD_LOGFILE%
  echo.>>%DOWNLOAD_LOGFILE%
)
echo %DATE% %TIME% - Info: Activating Aria2 downloads>>%DOWNLOAD_LOGFILE%

:Reload
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set WGET_PATH=..\bin\wget64.exe) else (
  if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" (set WGET_PATH=..\bin\wget64.exe) else (set WGET_PATH=..\bin\wget.exe)
)
if not exist %WGET_PATH% goto NoWGet
if not exist ..\bin\unzip.exe goto NoUnZip

if exist ..\bin\StaticDownloadLinks-aria2.txt (
  echo n | %SystemRoot%\System32\comp.exe ..\bin\StaticDownloadLinks-aria2.txt ..\static\StaticDownloadLinks-aria2.txt /A /L /C >nul 2>&1
  if errorlevel 1 (
    goto Download
  ) else (
    if "%JUST_RELOAD%"=="1" (goto EoF) else (goto Activate)
  )
) else (
  goto Download
)

:Download
rem *** Activate Aria2 downloads ***
title Activating Aria2 downloads...
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto DLx64
if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" goto DLx64
goto DLx86
:DLx64
echo Downloading most recent version of Aria2 (x64)...
for /F %%i in ('%SystemRoot%\System32\findstr.exe /I "64bit" ..\static\StaticDownloadLinks-aria2.txt') do (
  %WGET_PATH% -N -P ..\bin %%i
  if errorlevel 1 goto DownloadError
  pushd ..\bin
  unzip.exe -o %%~nxi %%~ni\aria2c.exe
  move /Y %%~ni\aria2c.exe .\aria2c-x64.exe >nul
  rd %%~ni
  del %%~nxi
  popd
  copy /Y ..\static\StaticDownloadLinks-aria2.txt ..\bin >nul
  echo %DATE% %TIME% - Info: Downloaded most recent version of Aria2 ^(x64^)>>%DOWNLOAD_LOGFILE%
)
:DLx86
echo Downloading most recent version of Aria2 (x86)...
for /F %%i in ('%SystemRoot%\System32\findstr.exe /I "32bit" ..\static\StaticDownloadLinks-aria2.txt') do (
  %WGET_PATH% -N -P ..\bin %%i
  if errorlevel 1 goto DownloadError
  pushd ..\bin
  unzip.exe -o %%~nxi %%~ni\aria2c.exe
  move /Y %%~ni\aria2c.exe .\aria2c-x86.exe >nul
  rd %%~ni
  del %%~nxi
  popd
  copy /Y ..\static\StaticDownloadLinks-aria2.txt ..\bin >nul
  echo %DATE% %TIME% - Info: Downloaded most recent version of Aria2 ^(x86^)>>%DOWNLOAD_LOGFILE%
)
if "%JUST_RELOAD%"=="1" goto EoF

:Activate
echo if /i "%%PROCESSOR_ARCHITECTURE%%"=="AMD64" goto x64>custom\SetAria2EnvVars.cmd
echo if /i "%%PROCESSOR_ARCHITEW6432%%"=="AMD64" goto x64>>custom\SetAria2EnvVars.cmd
echo goto x86>>custom\SetAria2EnvVars.cmd
echo.>>custom\SetAria2EnvVars.cmd
echo :x64>>custom\SetAria2EnvVars.cmd
echo if exist ..\bin\aria2c-x64.exe (set DLDR_PATH=..\bin\aria2c-x64.exe) else (goto x86)>>custom\SetAria2EnvVars.cmd
echo goto SetParams>>custom\SetAria2EnvVars.cmd
echo.>>custom\SetAria2EnvVars.cmd
echo :x86>>custom\SetAria2EnvVars.cmd
echo set DLDR_PATH=..\bin\aria2c-x86.exe>>custom\SetAria2EnvVars.cmd
echo.>>custom\SetAria2EnvVars.cmd
echo :SetParams>>custom\SetAria2EnvVars.cmd
echo set DLDR_COPT=--conditional-get=true --allow-overwrite=true --file-allocation=none --always-resume=false --max-resume-failure-tries=0 --max-tries=10 --retry-wait=10 --timeout=60 --remote-time=true -x10 -j10 -s10 -k1M -R>>custom\SetAria2EnvVars.cmd
echo set DLDR_LOPT=--log-level=notice -l %%DOWNLOAD_LOGFILE%%>>custom\SetAria2EnvVars.cmd
echo set DLDR_IOPT=-i>>custom\SetAria2EnvVars.cmd
echo set DLDR_POPT=-d>>custom\SetAria2EnvVars.cmd
echo set DLDR_NVOPT=--console-log-level=warn>>custom\SetAria2EnvVars.cmd
rem echo set DLDR_NCOPT=--check-certificate=false>>custom\SetAria2EnvVars.cmd
echo set DLDR_UOPT=-U "Mozilla/5.0 (Windows NT 10.0)">>custom\SetAria2EnvVars.cmd
echo %DATE% %TIME% - Info: Activated Aria2 downloads>>%DOWNLOAD_LOGFILE%
goto EoF

:NoExtensions
echo.
echo ERROR: No command extensions available.
echo.
exit

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

:DownloadError
if exist ..\bin\StaticDownloadLinks-aria2.txt del ..\bin\StaticDownloadLinks-aria2.txt
echo.
echo ERROR: Download of most recent version of Aria2 failed.
echo %DATE% %TIME% - Error: Download of most recent version of Aria2 failed>>%DOWNLOAD_LOGFILE%
echo.
goto EoF

:EoF
title %ComSpec%
endlocal
