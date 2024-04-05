@echo off
rem *** Author: T. Wittrock, Kiel ***

setlocal

if "%UPDATE_LOGFILE%"=="" set UPDATE_LOGFILE=%SystemRoot%\wsusofflineupdate.log

cd /D "%~dp0"

if exist %UPDATE_LOGFILE% echo.>>%UPDATE_LOGFILE%
if not exist RecallUpdate.cmd (
  echo %DATE% %TIME% - Error: Script file RecallUpdate.cmd not found>>%UPDATE_LOGFILE%
  goto Cleanup
)
if not exist ReconnectNetDrive.cmd goto SkipReconnect
%SystemRoot%\System32\timeout.exe /T 2 >nul
for /F "tokens=3*" %%i in (ReconnectNetDrive.cmd) do (
  echo Reconnecting network drive %%i to %%j...
  call ReconnectNetDrive.cmd
  if errorlevel 1 (
    echo %DATE% %TIME% - Error: Reconnection of network drive %%i to %%j failed>>%UPDATE_LOGFILE%
    goto Cleanup
  )
  echo %DATE% %TIME% - Info: Reconnected network drive %%i to %%j>>%UPDATE_LOGFILE%
)
:SkipReconnect
echo Recalling update...
RecallUpdate.cmd
goto EoF

:Cleanup
echo Cleaning up automatic recall...
call CleanupRecall.cmd
if exist %SystemRoot%\System32\bcdedit.exe (
  echo Adjusting boot sequence for next reboot...
  %SystemRoot%\System32\bcdedit.exe /bootsequence {current}
  echo %DATE% %TIME% - Info: Adjusted boot sequence for next reboot>>%UPDATE_LOGFILE%
)
echo Rebooting...
%SystemRoot%\System32\shutdown.exe /r /f /t 1
goto EoF

:EoF
endlocal
