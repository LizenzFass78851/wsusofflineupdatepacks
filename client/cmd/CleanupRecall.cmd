@echo off
rem *** Author: T. Wittrock, Kiel ***

setlocal

if "%UPDATE_LOGFILE%"=="" set UPDATE_LOGFILE=%SystemRoot%\wsusofflineupdate.log

cd /D "%~dp0"

if "%REG_PATH%"=="" (
  if exist %SystemRoot%\Sysnative\reg.exe (
    set REG_PATH=%SystemRoot%\Sysnative\reg.exe
  ) else (
    set REG_PATH=%SystemRoot%\System32\reg.exe
  )
)
if not exist %REG_PATH% goto NoReg
if "%CSCRIPT_PATH%"=="" (
  if exist %SystemRoot%\Sysnative\cscript.exe (
    set CSCRIPT_PATH=%SystemRoot%\Sysnative\cscript.exe
  ) else (
    set CSCRIPT_PATH=%SystemRoot%\System32\cscript.exe
  )
)
if not exist %CSCRIPT_PATH% goto NoCScript

echo Unregistering recall...
%REG_PATH% DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v WSUSOfflineUpdate /f >nul 2>&1
if errorlevel 1 (
  echo Warning: Deregistration of recall failed.
  echo %DATE% %TIME% - Warning: Deregistration of recall failed>>%UPDATE_LOGFILE%
) else (
  echo %DATE% %TIME% - Info: Unregistered recall>>%UPDATE_LOGFILE%
)

echo Disabling autologon...
%REG_PATH% ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d "0" /f >nul 2>&1
if errorlevel 1 (
  echo Warning: Disabling of autologon failed.
  echo %DATE% %TIME% - Warning: Disabling of autologon failed>>%UPDATE_LOGFILE%
) else (
  echo %DATE% %TIME% - Info: Disabled autologon>>%UPDATE_LOGFILE%
)

if exist %SystemRoot%\woubak-winlogon.reg (
  echo Restoring Winlogon registry hive...
  %REG_PATH% DELETE "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /va /f >nul 2>&1
  %REG_PATH% IMPORT %SystemRoot%\woubak-winlogon.reg >nul 2>&1
  del %SystemRoot%\woubak-winlogon.reg
  echo %DATE% %TIME% - Info: Restored Winlogon registry hive>>%UPDATE_LOGFILE%
)

if exist %SystemRoot%\woubak-system-policies.reg (
  echo Restoring System policies registry hive...
  %REG_PATH% DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /f >nul 2>&1
  %REG_PATH% IMPORT %SystemRoot%\woubak-system-policies.reg >nul 2>&1
  if errorlevel 1 (
    echo Warning: Restore of System policies registry hive failed.
    echo %DATE% %TIME% - Warning: Restore of System policies registry hive failed>>%UPDATE_LOGFILE%
  ) else (
    del %SystemRoot%\woubak-system-policies.reg
    echo %DATE% %TIME% - Info: Restored System policies registry hive>>%UPDATE_LOGFILE%
  )
)

echo Deleting WOUTempAdmin account...
%CSCRIPT_PATH% //Nologo //B //E:vbs DetermineTempAdminSID.vbs
if exist "%TEMP%\SetTempAdminSID.cmd" (
  call "%TEMP%\SetTempAdminSID.cmd"
  del "%TEMP%\SetTempAdminSID.cmd"
)
if "%TempAdminSID%"=="" (
  echo %DATE% %TIME% - Warning: Environment variable TempAdminSID not found - skipped deletion of WOUTempAdmin profile>>%UPDATE_LOGFILE%
) else (
  %REG_PATH% QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\%TempAdminSID%" /v ProfileImagePath >nul 2>&1
  if errorlevel 1 (
    echo %DATE% %TIME% - Warning: Registry reference to WOUTempAdmin profile not found - skipped deletion>>%UPDATE_LOGFILE%
  ) else (
    for /F "tokens=2*" %%i in ('%REG_PATH% QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\%TempAdminSID%" /v ProfileImagePath ^| %SystemRoot%\System32\find.exe /I "ProfileImagePath"') do (
      %REG_PATH% ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v DeleteWOUTempAdminProfile /t REG_SZ /d "cmd /c rd /S /Q \"%%j\"" /f >nul 2>&1
      echo %DATE% %TIME% - Info: Registered deletion of WOUTempAdmin profile ^("%%j"^)>>%UPDATE_LOGFILE%
    )
    %REG_PATH% DELETE "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\%TempAdminSID%" /f >nul 2>&1
    echo %DATE% %TIME% - Info: Deleted registry reference to WOUTempAdmin profile>>%UPDATE_LOGFILE%
  )
)
%REG_PATH% ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v DeleteWOURecallDir /t REG_SZ /d "cmd /c rd /S /Q \"%SystemRoot%\Temp\WOURecall\"" /f >nul 2>&1
echo %DATE% %TIME% - Info: Registered deletion of recall directory>>%UPDATE_LOGFILE%
%CSCRIPT_PATH% //Nologo //B //E:vbs DeleteUpdateAdmin.vbs
if errorlevel 1 (
  echo Warning: Deletion of WOUTempAdmin account failed.
  echo %DATE% %TIME% - Warning: Deletion of WOUTempAdmin account failed>>%UPDATE_LOGFILE%
) else (
  echo %DATE% %TIME% - Info: Deleted WOUTempAdmin account>>%UPDATE_LOGFILE%
)
goto EoF

:NoReg
echo.
echo ERROR: Registry tool %REG_PATH% not found.
echo %DATE% %TIME% - Error: Registry tool %REG_PATH% not found>>%UPDATE_LOGFILE%
goto Error

:NoCScript
echo.
echo ERROR: VBScript interpreter %CSCRIPT_PATH% not found.
echo %DATE% %TIME% - Error: VBScript interpreter %CSCRIPT_PATH% not found>>%UPDATE_LOGFILE%
goto Error

:Error
endlocal
exit /b 1

:EoF
endlocal
