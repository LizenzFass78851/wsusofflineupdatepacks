@echo off
rem *** Author: T. Wittrock, Kiel ***

if "%UPDATE_LOGFILE%"=="" set UPDATE_LOGFILE=%SystemRoot%\wsusofflineupdate.log

if "%REG_PATH%"=="" goto NoRegPath

echo Registering log file display...
%REG_PATH% ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce /v ShowOfflineUpdateLogFile /t REG_SZ /d "%SystemRoot%\System32\notepad.exe %UPDATE_LOGFILE%" /f >nul 2>&1
if errorlevel 1 goto RegError
echo %DATE% %TIME% - Info: Registered log file display>>%UPDATE_LOGFILE%
goto EoF

:NoRegPath
echo ERROR: Environment variable REG_PATH not set.
echo %DATE% %TIME% - Error: Environment variable REG_PATH not set>>%UPDATE_LOGFILE%
goto Error

:RegError
echo Warning: Registration of log file display failed.
echo %DATE% %TIME% - Warning: Registration of log file display failed>>%UPDATE_LOGFILE%
goto EoF

:Error
exit /b 1

:EoF
