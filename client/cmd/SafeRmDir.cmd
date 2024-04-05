@echo off
rem *** Author: T. Wittrock, Kiel ***

if "%UPDATE_LOGFILE%"=="" set UPDATE_LOGFILE=%SystemRoot%\wsusofflineupdate.log

if '%1'=='' goto NoParam
if not exist %1 goto EoF

if "%CSCRIPT_PATH%"=="" (
  if exist %SystemRoot%\Sysnative\cscript.exe (
    set CSCRIPT_PATH=%SystemRoot%\Sysnative\cscript.exe
  ) else (
    set CSCRIPT_PATH=%SystemRoot%\System32\cscript.exe
  )
)
if not exist %CSCRIPT_PATH% goto NoCScript

pushd "%~dp0"
for /L %%i in (1,1,10) do (
  if exist %1 rd /S /Q %1 >nul 2>&1
  if exist %1 %CSCRIPT_PATH% //Nologo //B //E:vbs Sleep.vbs 100
)
popd
if exist %1 goto RmError
goto EoF

:NoParam
echo ERROR: Invalid parameter. Usage: %~n0 ^<directory^>
echo %DATE% %TIME% - Error: Invalid parameter. Usage: %~n0 ^<directory^>>>%UPDATE_LOGFILE%
goto Error

:NoCScript
echo ERROR: VBScript interpreter %CSCRIPT_PATH% not found.
echo %DATE% %TIME% - Error: VBScript interpreter %CSCRIPT_PATH% not found>>%UPDATE_LOGFILE%
goto Error

:RmError
echo Warning: Removal of temporary directory %1 failed.
echo %DATE% %TIME% - Warning: Removal of temporary directory %1 failed>>%UPDATE_LOGFILE%
goto Error

:Error
exit /b 1

:EoF
exit /b 0
