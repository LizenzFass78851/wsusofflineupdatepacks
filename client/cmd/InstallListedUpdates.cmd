@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions enabledelayedexpansion
if errorlevel 1 goto NoExtensions

if "%UPDATE_LOGFILE%"=="" set UPDATE_LOGFILE=%SystemRoot%\wsusofflineupdate.log

if "%TEMP%"=="" goto NoTemp
pushd "%TEMP%"
if errorlevel 1 goto NoTempDir
popd

if "%OS_NAME%"=="" goto NoOSName

set RECALL_REQUIRED=0
set REBOOT_REQUIRED=0

set UPDATE_STAGE=0
if exist %SystemRoot%\Temp\SetWOUpdateStage.cmd (
  call %SystemRoot%\Temp\SetWOUpdateStage.cmd
  del %SystemRoot%\Temp\SetWOUpdateStage.cmd
)
if not exist "%TEMP%\UpdatesToInstall.txt" goto NoUpdates
set /A SKIP_UPDATES=UPDATE_STAGE*UPDATES_PER_STAGE
set /A STOP_UPDATES=(UPDATE_STAGE+1)*UPDATES_PER_STAGE

for /F "tokens=1* delims=:" %%i in ('%SystemRoot%\System32\findstr.exe /N $ "%TEMP%\UpdatesToInstall.txt"') do set LINES_COUNT=%%i
for /F "tokens=1* delims=:" %%i in ('%SystemRoot%\System32\findstr.exe /N $ "%TEMP%\UpdatesToInstall.txt"') do (
  if %%i GTR %STOP_UPDATES% goto BreakLoop
  if %%i GTR %SKIP_UPDATES% (
    for %%k in (o2k13 o2k16) do (
      echo %%j | %SystemRoot%\System32\find.exe /I "\%%k\" >nul 2>&1
      if not errorlevel 1 (
        echo !TIME! - Installing update %%i of %LINES_COUNT% ^(stage size: %UPDATES_PER_STAGE%^)...
        call InstallOfficeUpdate.cmd "%%j" %*
        set ERR_LEVEL=!errorlevel!
        rem echo InstallListedUpdates: ERR_LEVEL=!ERR_LEVEL!
        if "!ERR_LEVEL!"=="3010" (
          set REBOOT_REQUIRED=1
        ) else if "!ERR_LEVEL!"=="3011" (
          set RECALL_REQUIRED=1
        ) else if "!ERR_LEVEL!" NEQ "0" (
          goto InstError
        )
      )
    )
    for %%k in (dotnet %OS_NAME%-%OS_ARCH% %OS_NAME% win) do (
      echo %%j | %SystemRoot%\System32\find.exe /I "\%%k\" >nul 2>&1
      if not errorlevel 1 (
        echo !TIME! - Installing update %%i of %LINES_COUNT% ^(stage size: %UPDATES_PER_STAGE%^)...
        call InstallOSUpdate.cmd "%%j" %*
        set ERR_LEVEL=!errorlevel!
        rem echo InstallListedUpdates: ERR_LEVEL=!ERR_LEVEL!
        if "!ERR_LEVEL!"=="3010" (
          set REBOOT_REQUIRED=1
        ) else if "!ERR_LEVEL!"=="3011" (
          set RECALL_REQUIRED=1
        ) else if "!ERR_LEVEL!" NEQ "0" (
          goto InstError
        )
      )
    )
  )
)
:BreakLoop
set /A UPDATE_STAGE=UPDATE_STAGE+1
if %STOP_UPDATES% LSS %LINES_COUNT% (
  echo %DATE% %TIME% - Info: Installed %STOP_UPDATES% of %LINES_COUNT% updates>>%UPDATE_LOGFILE%
  if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
  echo @set UPDATE_STAGE=%UPDATE_STAGE% >%SystemRoot%\Temp\SetWOUpdateStage.cmd
  move /Y "%TEMP%\UpdatesToInstall.txt" %SystemRoot%\Temp\WOUpdatesToInstall.txt >nul 2>&1
) else (
  echo %DATE% %TIME% - Info: Installed %LINES_COUNT% updates>>%UPDATE_LOGFILE%
  del "%TEMP%\UpdatesToInstall.txt"
)
goto EoF

:NoExtensions
echo ERROR: No command extensions available.
goto Error

:NoTemp
echo ERROR: Environment variable TEMP not set.
echo %DATE% %TIME% - Error: Environment variable TEMP not set>>%UPDATE_LOGFILE%
goto Error

:NoTempDir
echo ERROR: Directory "%TEMP%" not found.
echo %DATE% %TIME% - Error: Directory "%TEMP%" not found>>%UPDATE_LOGFILE%
goto Error

:NoOSName
echo ERROR: Environment variable OS_NAME not set.
echo %DATE% %TIME% - Error: Environment variable OS_NAME not set>>%UPDATE_LOGFILE%
goto Error

:NoUpdates
echo ERROR: File "%TEMP%\UpdatesToInstall.txt" not found.
echo %DATE% %TIME% - Error: File "%TEMP%\UpdatesToInstall.txt" not found>>%UPDATE_LOGFILE%
goto Error

:InstError
if exist "%TEMP%\UpdatesToInstall.txt" del "%TEMP%\UpdatesToInstall.txt"
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
