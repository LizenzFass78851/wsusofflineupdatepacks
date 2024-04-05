@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions enabledelayedexpansion
if errorlevel 1 goto NoExtensions

rem clear vars storing parameters
set UPDATE_RCERTS=
set INSTALL_DOTNET35=
set INSTALL_DOTNET4=
set INSTALL_WMF=
set UPDATE_CPP=
set INSTALL_MSSE=
set UPDATE_TSC=
set SKIP_IEINST=
set SKIP_DEFS=
set SKIP_DYNAMIC=
set LIST_MODE_IDS=
set LIST_MODE_UPDATES=
set VERIFY_MODE=
set BOOT_MODE=
set FINISH_MODE=
set SHOW_LOG=
set DISM_MODE=
set MONITOR_ON=
set INSTALL_MSI=

if "%DIRCMD%" NEQ "" set DIRCMD=

cd /D "%~dp0"

set WSUSOFFLINE_VERSION=11.9.11hf5
title %~n0 %*
echo Starting WSUS Offline Update - Community Edition - v. %WSUSOFFLINE_VERSION% at %TIME%...
set UPDATE_LOGFILE=%SystemRoot%\wsusofflineupdate.log
goto Start

:Log
echo %DATE% %TIME% - %~1>>%UPDATE_LOGFILE%
goto :eof

:Start
rem *** Execute custom initialization hook ***
if exist .\custom\InitializationHook.cmd (
  echo Executing custom initialization hook...
  pushd .\custom
  call InitializationHook.cmd
  set ERR_LEVEL=%errorlevel%
  popd
)
if exist %UPDATE_LOGFILE% (
  echo.>>%UPDATE_LOGFILE%
  echo -------------------------------------------------------------------------------->>%UPDATE_LOGFILE%
  echo.>>%UPDATE_LOGFILE%
)
if exist .\custom\InitializationHook.cmd (
  call :Log "Info: Executed custom initialization hook (Errorlevel: %ERR_LEVEL%)"
  set ERR_LEVEL=
)
call :Log "Info: Starting WSUS Offline Update - Community Edition - v. %WSUSOFFLINE_VERSION%"
call :Log "Info: Used path "%~dp0" on %COMPUTERNAME% (user: %USERNAME%)"

:EvalParams
if "%1"=="" goto NoMoreParams
for %%i in (/updatercerts /instdotnet35 /instdotnet4 /instwmf /updatecpp /instmsse /updatetsc /skipieinst /skipdefs /skipdynamic /all /excludestatics /seconly /verify /autoreboot /shutdown /showlog /showdismprogress /monitoron /instmsi) do (
  if /i "%1"=="%%i" call :Log "Info: Option %%i detected"
)
if /i "%1"=="/updatercerts" set UPDATE_RCERTS=/updatercerts
if /i "%1"=="/instdotnet35" set INSTALL_DOTNET35=/instdotnet35
if /i "%1"=="/instdotnet4" set INSTALL_DOTNET4=/instdotnet4
if /i "%1"=="/instwmf" set INSTALL_WMF=/instwmf
if /i "%1"=="/updatecpp" set UPDATE_CPP=/updatecpp
if /i "%1"=="/instmsse" set INSTALL_MSSE=/instmsse
if /i "%1"=="/updatetsc" set UPDATE_TSC=/updatetsc
if /i "%1"=="/skipieinst" set SKIP_IEINST=/skipieinst
if /i "%1"=="/skipdefs" set SKIP_DEFS=/skipdefs
if /i "%1"=="/skipdynamic" set SKIP_DYNAMIC=/skipdynamic
if /i "%1"=="/all" set LIST_MODE_IDS=/all
if /i "%1"=="/excludestatics" set LIST_MODE_UPDATES=/excludestatics
if /i "%1"=="/seconly" set LIST_MODE_IDS=/seconly
if /i "%1"=="/verify" set VERIFY_MODE=/verify
if /i "%1"=="/autoreboot" set BOOT_MODE=/autoreboot
if /i "%1"=="/shutdown" set FINISH_MODE=/shutdown
if /i "%1"=="/showlog" set SHOW_LOG=/showlog
if /i "%1"=="/showdismprogress" set DISM_MODE=/showdismprogress
if /i "%1"=="/monitoron" set MONITOR_ON=/monitoron
if /i "%1"=="/instmsi" set INSTALL_MSI=/instmsi
shift /1
goto EvalParams

:NoMoreParams
if "%TEMP%"=="" goto NoTemp
pushd "%TEMP%"
if errorlevel 1 goto NoTempDir
popd

if exist %SystemRoot%\Sysnative\cscript.exe (
  set CSCRIPT_PATH=%SystemRoot%\Sysnative\cscript.exe
) else (
  set CSCRIPT_PATH=%SystemRoot%\System32\cscript.exe
)
if not exist %CSCRIPT_PATH% goto NoCScript
if exist %SystemRoot%\Sysnative\reg.exe (
  set REG_PATH=%SystemRoot%\Sysnative\reg.exe
) else (
  set REG_PATH=%SystemRoot%\System32\reg.exe
)
if not exist %REG_PATH% goto NoReg
if exist %SystemRoot%\Sysnative\sc.exe (
  set SC_PATH=%SystemRoot%\Sysnative\sc.exe
) else (
  set SC_PATH=%SystemRoot%\System32\sc.exe
)
if not exist %SC_PATH% goto NoSc

rem *** Check user's privileges ***
echo Checking user's privileges...
if not exist ..\bin\IfAdmin.exe goto NoIfAdmin
..\bin\IfAdmin.exe
if not errorlevel 1 goto NoAdmin

rem *** Determine system's properties ***
echo Determining system's properties...
%CSCRIPT_PATH% //Nologo //B //E:vbs DetermineSystemProperties.vbs /nodebug
if errorlevel 1 goto NoSysEnvVars
if not exist "%TEMP%\SetSystemEnvVars.cmd" goto NoSysEnvVars

rem *** Set environment variables for system's properties ***
call "%TEMP%\SetSystemEnvVars.cmd"
del "%TEMP%\SetSystemEnvVars.cmd"
if "%SystemDirectory%"=="" set SystemDirectory=%SystemRoot%\system32
if "%OS_ARCH%"=="" (
  if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set OS_ARCH=x64) else (
    if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" (set OS_ARCH=x64) else (set OS_ARCH=x86)
  )
)
if /i "%OS_ARCH%"=="x64" (set HASHDEEP_PATH=..\bin\hashdeep64.exe) else (set HASHDEEP_PATH=..\bin\hashdeep.exe)

rem *** Set target environment variables ***
if "%OS_VER_MAJOR%"=="" goto UnsupOS
call SetTargetEnvVars.cmd

rem *** Check Operating System ***
if "%OS_NAME%"=="" goto UnsupOS
if "%OS_NAME%"=="w2k" goto UnsupOS
if "%OS_NAME%"=="wxp" goto UnsupOS
if "%OS_NAME%"=="w2k3" goto UnsupOS
if "%OS_NAME%"=="w62" (
  if /i "%OS_ARCH%"=="x86" goto UnsupOS
)
if "%OS_NAME%"=="w110" goto UnsupOS
for %%i in (x86 x64) do (if /i "%OS_ARCH%"=="%%i" goto ValidArch)
goto UnsupArch
:ValidArch
if "%OS_LANG%"=="" goto UnsupLang

rem *** Check number of automatic recalls ***
if "%USERNAME%"=="WOUTempAdmin" (
  echo Checking number of automatic recalls...
  if exist %SystemRoot%\Temp\WOURecall\wourecall.%WOU_ENDLESS% goto EndlessLoop
  if exist %SystemRoot%\Temp\WOURecall\wourecall.8 ren %SystemRoot%\Temp\WOURecall\wourecall.8 wourecall.9
  if exist %SystemRoot%\Temp\WOURecall\wourecall.7 ren %SystemRoot%\Temp\WOURecall\wourecall.7 wourecall.8
  if exist %SystemRoot%\Temp\WOURecall\wourecall.6 ren %SystemRoot%\Temp\WOURecall\wourecall.6 wourecall.7
  if exist %SystemRoot%\Temp\WOURecall\wourecall.5 ren %SystemRoot%\Temp\WOURecall\wourecall.5 wourecall.6
  if exist %SystemRoot%\Temp\WOURecall\wourecall.4 ren %SystemRoot%\Temp\WOURecall\wourecall.4 wourecall.5
  if exist %SystemRoot%\Temp\WOURecall\wourecall.3 ren %SystemRoot%\Temp\WOURecall\wourecall.3 wourecall.4
  if exist %SystemRoot%\Temp\WOURecall\wourecall.2 ren %SystemRoot%\Temp\WOURecall\wourecall.2 wourecall.3
  if exist %SystemRoot%\Temp\WOURecall\wourecall.1 ren %SystemRoot%\Temp\WOURecall\wourecall.1 wourecall.2
  if not exist %SystemRoot%\Temp\WOURecall\nul md %SystemRoot%\Temp\WOURecall
  if not exist %SystemRoot%\Temp\WOURecall\wourecall.* echo. >%SystemRoot%\Temp\WOURecall\wourecall.1
)

rem *** Determine Windows licensing info ***
if exist %SystemRoot%\System32\slmgr.vbs (
  echo Determining Windows licensing info...
  %CSCRIPT_PATH% //Nologo //E:vbs %SystemRoot%\System32\slmgr.vbs -dli >"%TEMP%\slmgr-dli.txt"
  %SystemRoot%\System32\findstr.exe /N ":" "%TEMP%\slmgr-dli.txt" >"%TEMP%\wou_slmgr.txt"
  del "%TEMP%\slmgr-dli.txt"
)

rem *** Echo OS properties ***
echo Found Microsoft Windows version: %OS_VER_MAJOR%.%OS_VER_MINOR%.%OS_VER_BUILD%.%OS_VER_REVIS% (%OS_NAME% %OS_ARCH% %OS_LANG% sp%OS_SP_VER_MAJOR%)
if exist "%TEMP%\wou_slmgr.txt" (
  echo Found Microsoft Windows Software Licensing Management Tool info...
  for /F "tokens=1* delims=:" %%i in ('%SystemRoot%\System32\findstr.exe /B /L /I "1: 2: 3: 4: 5: 6:" "%TEMP%\wou_slmgr.txt"') do echo %%j
)
rem echo Found total physical memory: %OS_RAM_GB% GB
rem echo Found Servicing Stack version: %SERVICING_VER_MAJOR%.%SERVICING_VER_MINOR%.%SERVICING_VER_BUILD%.%SERVICING_VER_REVIS%
rem echo Found Windows Update Agent version: %WUA_VER_MAJOR%.%WUA_VER_MINOR%.%WUA_VER_BUILD%.%WUA_VER_REVIS%
rem echo Found Windows Installer version: %MSI_VER_MAJOR%.%MSI_VER_MINOR%.%MSI_VER_BUILD%.%MSI_VER_REVIS%
rem echo Found Internet Explorer version: %IE_VER_MAJOR%.%IE_VER_MINOR%.%IE_VER_BUILD%.%IE_VER_REVIS%
rem echo Found Remote Desktop Client version: %TSC_VER_MAJOR%.%TSC_VER_MINOR%.%TSC_VER_BUILD%.%TSC_VER_REVIS%
rem echo Found Microsoft .NET Framework 3.5 version: %DOTNET35_VER_MAJOR%.%DOTNET35_VER_MINOR%.%DOTNET35_VER_BUILD%.%DOTNET35_VER_REVIS%
rem echo Found Microsoft .NET Framework 4 version: %DOTNET4_VER_MAJOR%.%DOTNET4_VER_MINOR%.%DOTNET4_VER_BUILD% (release: %DOTNET4_RELEASE%)
rem echo Found Windows Management Framework version: %WMF_VER_MAJOR%.%WMF_VER_MINOR%.%WMF_VER_BUILD%.%WMF_VER_REVIS%
rem echo Found Microsoft Security Essentials version: %MSSE_VER_MAJOR%.%MSSE_VER_MINOR%.%MSSE_VER_BUILD%.%MSSE_VER_REVIS%
rem echo Found Microsoft Security Essentials definitions version: %MSSEDEFS_VER_MAJOR%.%MSSEDEFS_VER_MINOR%.%MSSEDEFS_VER_BUILD%.%MSSEDEFS_VER_REVIS%
rem echo Found Network Inspection System definitions version: %NISDEFS_VER_MAJOR%.%NISDEFS_VER_MINOR%.%NISDEFS_VER_BUILD%.%NISDEFS_VER_REVIS%
rem echo Found Windows Defender definitions version: %WDDEFS_VER_MAJOR%.%WDDEFS_VER_MINOR%.%WDDEFS_VER_BUILD%.%WDDEFS_VER_REVIS%
if "%O2K13_VER_MAJOR%" NEQ "" (
  echo Found Microsoft Office 2013 version: %O2K13_VER_MAJOR%.%O2K13_VER_MINOR%.%O2K13_VER_BUILD%.%O2K13_VER_REVIS% ^(o2k13 %O2K13_ARCH% %O2K13_LANG% sp%O2K13_SP_VER%^)
)
if "%O2K16_VER_MAJOR%" NEQ "" (
  echo Found Microsoft Office 2016 version: %O2K16_VER_MAJOR%.%O2K16_VER_MINOR%.%O2K16_VER_BUILD%.%O2K16_VER_REVIS% ^(o2k16 %O2K16_ARCH% %O2K16_LANG% sp%O2K16_SP_VER%^)
)
call :Log "Info: Found Microsoft Windows version %OS_VER_MAJOR%.%OS_VER_MINOR%.%OS_VER_BUILD%.%OS_VER_REVIS% (%OS_NAME% %OS_ARCH% %OS_LANG% sp%OS_SP_VER_MAJOR%)"
if exist "%TEMP%\wou_slmgr.txt" (
  call :Log "Info: Found Microsoft Windows Software Licensing Management Tool info..."
  for /F "tokens=1* delims=:" %%i in ('%SystemRoot%\System32\findstr.exe /B /L /I "1: 2: 3: 4: 5: 6:" "%TEMP%\wou_slmgr.txt"') do call :Log "Info: %%j"
  del "%TEMP%\wou_slmgr.txt"
)
call :Log "Info: Found total physical memory: %OS_RAM_GB% GB"
call :Log "Info: Found Servicing Stack version %SERVICING_VER_MAJOR%.%SERVICING_VER_MINOR%.%SERVICING_VER_BUILD%.%SERVICING_VER_REVIS%"
call :Log "Info: Found Windows Update Agent version %WUA_VER_MAJOR%.%WUA_VER_MINOR%.%WUA_VER_BUILD%.%WUA_VER_REVIS%"
call :Log "Info: Found Windows Installer version %MSI_VER_MAJOR%.%MSI_VER_MINOR%.%MSI_VER_BUILD%.%MSI_VER_REVIS%"
call :Log "Info: Found Internet Explorer version %IE_VER_MAJOR%.%IE_VER_MINOR%.%IE_VER_BUILD%.%IE_VER_REVIS%"
call :Log "Info: Found Remote Desktop Client version %TSC_VER_MAJOR%.%TSC_VER_MINOR%.%TSC_VER_BUILD%.%TSC_VER_REVIS%"
call :Log "Info: Found Microsoft .NET Framework 3.5 version %DOTNET35_VER_MAJOR%.%DOTNET35_VER_MINOR%.%DOTNET35_VER_BUILD%.%DOTNET35_VER_REVIS%"
call :Log "Info: Found Microsoft .NET Framework 4 version %DOTNET4_VER_MAJOR%.%DOTNET4_VER_MINOR%.%DOTNET4_VER_BUILD% (release: %DOTNET4_RELEASE%)"
call :Log "Info: Found Windows Management Framework version %WMF_VER_MAJOR%.%WMF_VER_MINOR%.%WMF_VER_BUILD%.%WMF_VER_REVIS%"
if "%OS_NAME%"=="w62" goto SkipLogMSSEVer
if "%OS_NAME%"=="w63" goto SkipLogMSSEVer
if "%OS_NAME%"=="w100" goto SkipLogMSSEVer
call :Log "Info: Found Microsoft Security Essentials version %MSSE_VER_MAJOR%.%MSSE_VER_MINOR%.%MSSE_VER_BUILD%.%MSSE_VER_REVIS%"
call :Log "Info: Found Microsoft Security Essentials definitions version %MSSEDEFS_VER_MAJOR%.%MSSEDEFS_VER_MINOR%.%MSSEDEFS_VER_BUILD%.%MSSEDEFS_VER_REVIS%"
call :Log "Info: Found Network Inspection System definitions version %NISDEFS_VER_MAJOR%.%NISDEFS_VER_MINOR%.%NISDEFS_VER_BUILD%.%NISDEFS_VER_REVIS%"
:SkipLogMSSEVer
call :Log "Info: Found Windows Defender definitions version %WDDEFS_VER_MAJOR%.%WDDEFS_VER_MINOR%.%WDDEFS_VER_BUILD%.%WDDEFS_VER_REVIS%"
if "%O2K13_VER_MAJOR%" NEQ "" (
  call :Log "Info: Found Microsoft Office 2013 version %O2K13_VER_MAJOR%.%O2K13_VER_MINOR%.%O2K13_VER_BUILD%.%O2K13_VER_REVIS% (o2k13 %O2K13_ARCH% %O2K13_LANG% sp%O2K13_SP_VER%)"
)
if "%O2K16_VER_MAJOR%" NEQ "" (
  call :Log "Info: Found Microsoft Office 2016 version %O2K16_VER_MAJOR%.%O2K16_VER_MINOR%.%O2K16_VER_BUILD%.%O2K16_VER_REVIS% (o2k16 %O2K16_ARCH% %O2K16_LANG% sp%O2K16_SP_VER%)"
)

rem ***  Check compatibility mode ***
if "%__COMPAT_LAYER%"=="" goto NoCompatLayer
echo %__COMPAT_LAYER% | %SystemRoot%\System32\find.exe /I "ElevateCreateProcess" >nul 2>&1
if not errorlevel 1 goto NoCompatLayer
echo %__COMPAT_LAYER% | %SystemRoot%\System32\find.exe /I "Installer" >nul 2>&1
if not errorlevel 1 goto NoCompatLayer
echo Warning: The compatibility mode is active (__COMPAT_LAYER=%__COMPAT_LAYER%).
call :Log "Warning: The compatibility mode is active (__COMPAT_LAYER=%__COMPAT_LAYER%)"
:NoCompatLayer

rem *** Check medium content ***
echo Checking medium content...
if exist ..\catalogdate.txt (
  for /F %%i in ('type ..\catalogdate.txt') do (
    echo Catalog date: %%i
    call :Log "Info: Catalog date: %%i"
  )
)
if exist ..\builddate.txt (
  for /F %%i in ('type ..\builddate.txt') do (
    echo Medium build date: %%i
    call :Log "Info: Medium build date: %%i"
  )
)
if /i "%OS_ARCH%"=="x64" (
  if exist ..\%OS_NAME%-%OS_ARCH%\%OS_LANG%\nul (
    echo Medium supports Microsoft Windows ^(%OS_NAME% %OS_ARCH% %OS_LANG%^).
    call :Log "Info: Medium supports Microsoft Windows (%OS_NAME% %OS_ARCH% %OS_LANG%)"
    goto CheckOfficeMedium
  )
  if exist ..\%OS_NAME%-%OS_ARCH%\glb\nul (
    echo Medium supports Microsoft Windows ^(%OS_NAME% %OS_ARCH% glb^).
    call :Log "Info: Medium supports Microsoft Windows (%OS_NAME% %OS_ARCH% glb)"
    goto CheckOfficeMedium
  )
) else (
  if exist ..\%OS_NAME%\%OS_LANG%\nul (
    echo Medium supports Microsoft Windows ^(%OS_NAME% %OS_ARCH% %OS_LANG%^).
    call :Log "Info: Medium supports Microsoft Windows (%OS_NAME% %OS_ARCH% %OS_LANG%)"
    goto CheckOfficeMedium
  )
  if exist ..\%OS_NAME%\glb\nul (
    echo Medium supports Microsoft Windows ^(%OS_NAME% %OS_ARCH% glb^).
    call :Log "Info: Medium supports Microsoft Windows (%OS_NAME% %OS_ARCH% glb)"
    goto CheckOfficeMedium
  )
)
echo Medium does not support Microsoft Windows (%OS_NAME% %OS_ARCH% %OS_LANG%).
call :Log "Info: Medium does not support Microsoft Windows (%OS_NAME% %OS_ARCH% %OS_LANG%)"
if not "%OFC_INSTALLED%"=="1" goto InvalidMedium
set JUST_OFFICE=1

:CheckOfficeMedium
if not "%OFC_INSTALLED%"=="1" (if "%JUST_OFFICE%"=="1" (goto InvalidMedium) else (goto ProperMedium))
set OFFICE_SUPPORTED=0
if not "%O2K13_VER_MAJOR%"=="" (
  if exist ..\o2k13\%O2K13_LANG%\nul (
    echo Medium supports Microsoft Office ^(o2k13 %O2K13_LANG%^).
    call :Log "Info: Medium supports Microsoft Office (o2k13 %O2K13_LANG%)"
    set OFFICE_SUPPORTED=1
  ) else if exist ..\o2k13\glb\nul (
    echo Medium supports Microsoft Office ^(o2k13 glb^).
    call :Log "Info: Medium supports Microsoft Office (o2k13 glb)"
    set OFFICE_SUPPORTED=1
  )
)
if not "%O2K16_VER_MAJOR%"=="" (
  if exist ..\o2k16\glb\nul (
    echo Medium supports Microsoft Office ^(o2k16 glb^).
    call :Log "Info: Medium supports Microsoft Office (o2k16 glb)"
    set OFFICE_SUPPORTED=1
  )
)
if "%OFFICE_SUPPORTED%"=="1" goto ProperMedium

echo Medium does not support Microsoft Office.
call :Log "Info: Medium does not support Microsoft Office"
if "%JUST_OFFICE%"=="1" goto InvalidMedium
:ProperMedium

rem *** Disable screensaver ***
echo Disabling screensaver...
for /F "tokens=3" %%i in ('%REG_PATH% QUERY "HKCU\Control Panel\Desktop" /v ScreenSaveActive 2^>nul ^| %SystemRoot%\System32\find.exe /I "ScreenSaveActive"') do set CUPOL_SSA=%%i
%REG_PATH% ADD "HKCU\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 0 /f >nul 2>&1
call :Log "Info: Disabled screensaver"

rem *** Adjust power management settings ***
if not exist %SystemRoot%\System32\powercfg.exe goto SkipPowerCfg
if exist %SystemRoot%\woubak-pwrscheme-act.txt goto SkipPowerCfg
if exist %SystemRoot%\woubak-pwrscheme-temp.txt goto SkipPowerCfg
echo Creating temporary power scheme...
for /F "tokens=2 delims=:(" %%i in ('%SystemRoot%\System32\powercfg.exe -getactivescheme') do echo %%i>%SystemRoot%\woubak-pwrscheme-act.txt
for /F %%i in (%SystemRoot%\woubak-pwrscheme-act.txt) do (
  for /F "tokens=2 delims=:(" %%j in ('%SystemRoot%\System32\powercfg.exe -duplicatescheme %%i') do echo %%j>%SystemRoot%\woubak-pwrscheme-temp.txt
)
for /F %%i in (%SystemRoot%\woubak-pwrscheme-temp.txt) do (
  %SystemRoot%\System32\powercfg.exe -changename %%i WOUTemp
  %SystemRoot%\System32\powercfg.exe -setacvalueindex %%i sub_none consolelock 0
  %SystemRoot%\System32\powercfg.exe -setdcvalueindex %%i sub_none consolelock 0
  %SystemRoot%\System32\powercfg.exe -setactive %%i
)
if errorlevel 1 (
  echo Warning: Creation of temporary power scheme failed.
  call :Log "Warning: Creation of temporary power scheme failed"
  goto SkipPowerCfg
) else (
  call :Log "Info: Created temporary power scheme"
)
echo Adjusting power management settings...
for %%i in (disk standby hibernate) do (
  for %%j in (ac dc) do %SystemRoot%\System32\powercfg.exe -X -%%i-timeout-%%j 0
)
for %%i in (monitor) do (
  if "%MONITOR_ON%"=="/monitoron" (
    for %%j in (ac dc) do %SystemRoot%\System32\powercfg.exe -X -%%i-timeout-%%j 0
  ) else (
    for %%j in (ac dc) do %SystemRoot%\System32\powercfg.exe -X -%%i-timeout-%%j 1
  )
)
call :Log "Info: Adjusted power management settings"
:SkipPowerCfg

rem *** Determine Windows Update Agent (WUA) support for SHA2-signed wsusscn2.cab ***
if "%WUA_SHA2_SUPPORT%" NEQ "1" (
  if %WUA_VER_MAJOR% GTR %WUA_VER_TARGET_MAJOR% set WUA_SHA2_SUPPORT=1
  if %WUA_VER_MAJOR% EQU %WUA_VER_TARGET_MAJOR% if %WUA_VER_MINOR% GTR %WUA_VER_TARGET_MINOR% set WUA_SHA2_SUPPORT=1
  if %WUA_VER_MAJOR% EQU %WUA_VER_TARGET_MAJOR% if %WUA_VER_MINOR% EQU %WUA_VER_TARGET_MINOR% if %WUA_VER_BUILD% GTR %WUA_VER_TARGET_BUILD% set WUA_SHA2_SUPPORT=1
  if %WUA_VER_MAJOR% EQU %WUA_VER_TARGET_MAJOR% if %WUA_VER_MINOR% EQU %WUA_VER_TARGET_MINOR% if %WUA_VER_BUILD% EQU %WUA_VER_TARGET_BUILD% if %WUA_VER_REVIS% GEQ %WUA_VER_TARGET_REVIS% set WUA_SHA2_SUPPORT=1
)

if "%JUST_OFFICE%"=="1" goto JustOffice

rem *** Install Windows Service Pack ***
if "%OS_NAME%"=="w63" goto SPw63
echo Checking Windows Service Pack version...
if %OS_SP_VER_MAJOR% GEQ %OS_SP_VER_TARGET_MAJOR% goto SkipSPInst
if "%OS_SP_TARGET_ID%"=="" goto NoSPTargetId
echo %OS_SP_TARGET_ID%>"%TEMP%\MissingUpdateIds.txt"
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if not exist "%TEMP%\UpdatesToInstall.txt" (
  echo Warning: Windows Service Pack installation file ^(kb%OS_SP_TARGET_ID%^) not found.
  call :Log "Warning: Windows Service Pack installation file (kb%OS_SP_TARGET_ID%) not found"
  goto SkipSPInst
)
echo Installing most recent Windows Service Pack...
goto SP%OS_NAME%

:SPw60
:SPw61
:SPw62
if "%BOOT_MODE%" NEQ "/autoreboot" goto SPw6Now
if "%USERNAME%"=="WOUTempAdmin" goto SPw6Now
call :Log "Info: Preparing installation of most recent Service Pack"
set RECALL_REQUIRED=1
goto SPInstalled
:SPw6Now
call :Log "Info: Installing most recent Service Pack"
call InstallListedUpdates.cmd %VERIFY_MODE% %DISM_MODE% /unattend /forcerestart
set ERR_LEVEL=%errorlevel%
rem echo DoUpdate: ERR_LEVEL=%ERR_LEVEL%
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
) else if "%ERR_LEVEL%" NEQ "0" (
  goto InstError
)
rem FIXME 11.9.8 (b69)
set RECALL_REQUIRED=1
goto SPInstalled

:SPw63
echo Checking Windows 8.1 / Server 2012 R2 Update Rollup April 2014 installation state...
if %OS_VER_REVIS% GEQ %OS_UPD1_TARGET_REVIS% goto Upd2w63
if exist %SystemRoot%\Temp\wou_w63upd1_tried.txt goto SkipSPInst
%CSCRIPT_PATH% //Nologo //B //E:vbs ListInstalledUpdateIds.vbs
if exist "%TEMP%\InstalledUpdateIds.txt" (
  %SystemRoot%\System32\find.exe /I "%OS_SP_TARGET_ID%" "%TEMP%\InstalledUpdateIds.txt" >nul 2>&1
  if errorlevel 1 (
    copy /Y ..\static\StaticUpdateIds-w63-upd1.txt "%TEMP%\MissingUpdateIds.txt" >nul
    del "%TEMP%\InstalledUpdateIds.txt"
  ) else (
    %SystemRoot%\System32\findstr.exe /I /V "2939087 %OS_SP_PREREQ_ID% clearcompressionflag %OS_SP_TARGET_ID%" ..\static\StaticUpdateIds-w63-upd1.txt >"%TEMP%\MissingUpdateIds.txt"
    del "%TEMP%\InstalledUpdateIds.txt"
  )
) else (
  copy /Y ..\static\StaticUpdateIds-w63-upd1.txt "%TEMP%\MissingUpdateIds.txt" >nul
)
for %%i in ("%TEMP%\MissingUpdateIds.txt") do if %%~zi==0 del %%i
if not exist "%TEMP%\MissingUpdateIds.txt" goto Upd2w63
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if exist "%TEMP%\UpdatesToInstall.txt" (
  echo Installing Windows 8.1 / Server 2012 R2 Update Rollup April 2014...
  call :Log "Info: Installing Windows 8.1 / Server 2012 R2 Update Rollup April 2014"
  call InstallListedUpdates.cmd %VERIFY_MODE% %DISM_MODE% /errorsaswarnings
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
  if "!ERR_LEVEL!"=="3010" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_w63upd1_tried.txt
    set REBOOT_REQUIRED=1
    goto Installed
  ) else if "!ERR_LEVEL!"=="3011" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_w63upd1_tried.txt
    set RECALL_REQUIRED=1
    goto Installed
  ) else if "!ERR_LEVEL!" GEQ "0" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_w63upd1_tried.txt
    set RECALL_REQUIRED=1
    goto Installed
  ) else (
    goto InstError
  )
) else (
  echo Warning: Windows 8.1 / Server 2012 R2 Update Rollup April 2014 installation files not found.
  call :Log "Warning: Windows 8.1 / Server 2012 R2 Update Rollup April 2014 installation files not found"
  if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
  echo. >%SystemRoot%\Temp\wou_w63upd1_tried.txt
)
:Upd2w63
echo Checking Windows 8.1 / Server 2012 R2 Update Rollup Nov. 2014 installation state...
if %OS_VER_REVIS% GEQ %OS_UPD2_TARGET_REVIS% goto SkipSPInst
if exist %SystemRoot%\Temp\wou_w63upd2_tried.txt goto SkipSPInst
copy /Y ..\static\StaticUpdateIds-w63-upd2.txt "%TEMP%\StaticUpdateIds-w63-upd2.txt" >nul
if %OS_DOMAIN_ROLE% GEQ 2 echo 3016437>>"%TEMP%\StaticUpdateIds-w63-upd2.txt"
%CSCRIPT_PATH% //Nologo //B //E:vbs ListInstalledUpdateIds.vbs
if exist "%TEMP%\InstalledUpdateIds.txt" (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\InstalledUpdateIds.txt" "%TEMP%\StaticUpdateIds-w63-upd2.txt" >"%TEMP%\MissingUpdateIds.txt"
  del "%TEMP%\InstalledUpdateIds.txt"
) else (
  copy /Y "%TEMP%\StaticUpdateIds-w63-upd2.txt" "%TEMP%\MissingUpdateIds.txt" >nul
)
del "%TEMP%\StaticUpdateIds-w63-upd2.txt"
for %%i in ("%TEMP%\MissingUpdateIds.txt") do if %%~zi==0 del %%i
if not exist "%TEMP%\MissingUpdateIds.txt" goto SkipSPInst
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if exist "%TEMP%\UpdatesToInstall.txt" (
  echo Installing Windows 8.1 / Server 2012 R2 Update Rollup Nov. 2014...
  call :Log "Info: Installing Windows 8.1 / Server 2012 R2 Update Rollup Nov. 2014"
  call InstallListedUpdates.cmd %VERIFY_MODE% %DISM_MODE% /errorsaswarnings
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
  if "!ERR_LEVEL!"=="3010" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_w63upd2_tried.txt
    set REBOOT_REQUIRED=1
    goto Installed
  ) else if "!ERR_LEVEL!"=="3011" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_w63upd2_tried.txt
    set RECALL_REQUIRED=1
    goto Installed
  ) else if "!ERR_LEVEL!" GEQ "0" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_w63upd2_tried.txt
    set RECALL_REQUIRED=1
    goto Installed
  ) else (
    goto InstError
  )
) else (
  echo Warning: Windows 8.1 / Server 2012 R2 Update Rollup Nov. 2014 installation files not found.
  call :Log "Warning: Windows 8.1 / Server 2012 R2 Update Rollup Nov. 2014 installation files not found"
  if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
  echo. >%SystemRoot%\Temp\wou_w63upd2_tried.txt
)
goto SPInstalled
:SPw100
goto SkipSPInst
:SPw110
goto SkipSPInst
:SPInstalled
if "%RECALL_REQUIRED%"=="1" goto Installed
if "%REBOOT_REQUIRED%"=="1" goto Installed
:SkipSPInst

rem *** Install Trusted Root Certificates and Certificate revocation lists ***
if "%UPDATE_RCERTS%" NEQ "/updatercerts" goto SkipTRCertsInst
echo Installing Trusted Root Certificates...
for /F "tokens=*" %%i in ('dir /B ..\win\glb\*.crt') do (
  if exist %SystemRoot%\Sysnative\certutil.exe (
    %SystemRoot%\Sysnative\certutil.exe -f -addstore Root "..\win\glb\%%i"
  ) else (
    %SystemRoot%\System32\certutil.exe -f -addstore Root "..\win\glb\%%i"
  )
  call :Log "Info: Installed ..\win\glb\%%i"
)
echo Installing Certificate revocation lists...
for /F "tokens=*" %%i in ('dir /B ..\win\glb\*.crl') do (
  if exist %SystemRoot%\Sysnative\certutil.exe (
    %SystemRoot%\Sysnative\certutil.exe -f -addstore Root "..\win\glb\%%i"
  ) else (
    %SystemRoot%\System32\certutil.exe -f -addstore Root "..\win\glb\%%i"
  )
  call :Log "Info: Installed ..\win\glb\%%i"
)
:SkipTRCertsInst

rem *** Install Servicing Stack ***
echo Checking Servicing Stack version...
if %OS_VER_MAJOR% LSS 6 goto SkipServicingStack
set SERVICING_VER=%SERVICING_VER_MAJOR%.%SERVICING_VER_MINOR%.%SERVICING_VER_BUILD%.%SERVICING_VER_REVIS%
:CheckServicingStack
if exist ..\static\StaticUpdateIds-servicing-%OS_NAME%.txt (
  for /f "tokens=1,2,3 delims=," %%a in (..\static\StaticUpdateIds-servicing-%OS_NAME%.txt) do (
    %CSCRIPT_PATH% //Nologo //B //E:vbs CompareVersions.vbs %SERVICING_VER% %%a
    if "!errorlevel!"=="3" (
      echo Installing %%c...
      call :Log "Info: Installing %%c"
      echo %%b>"%TEMP%\MissingUpdateIds.txt"
      set SERVICING_VER_NEW=%%a
      goto InstallServicingStack
    )
  )
)
if "%OS_SHA2_SUPPORT%"=="1" (
  if exist ..\static\StaticUpdateIds-servicing-%OS_NAME%-sha2.txt (
    for /f "tokens=1,2,3 delims=," %%a in (..\static\StaticUpdateIds-servicing-%OS_NAME%-sha2.txt) do (
      %CSCRIPT_PATH% //Nologo //B //E:vbs CompareVersions.vbs %SERVICING_VER% %%a
      if "!errorlevel!"=="3" (
        echo Installing %%c...
        call :Log "Info: Installing %%c"
        echo %%b>"%TEMP%\MissingUpdateIds.txt"
        set SERVICING_VER_NEW=%%a
        goto InstallServicingStack
      )
    )
  )
)
if exist ..\static\StaticUpdateIds-servicing-%OS_NAME%-%OS_VER_BUILD%.txt (
  for /f "tokens=1,2,3 delims=," %%a in (..\static\StaticUpdateIds-servicing-%OS_NAME%-%OS_VER_BUILD%.txt) do (
    %CSCRIPT_PATH% //Nologo //B //E:vbs CompareVersions.vbs %SERVICING_VER% %%a
    if "!errorlevel!"=="3" (
      echo Installing %%c...
      call :Log "Info: Installing %%c"
      echo %%b>"%TEMP%\MissingUpdateIds.txt"
      set SERVICING_VER_NEW=%%a
      goto InstallServicingStack
    )
  )
)
if "%OS_SHA2_SUPPORT%"=="1" (
  if exist ..\static\StaticUpdateIds-servicing-%OS_NAME%-%OS_VER_BUILD%-sha2.txt (
    for /f "tokens=1,2,3 delims=," %%a in (..\static\StaticUpdateIds-servicing-%OS_NAME%-%OS_VER_BUILD%-sha2.txt) do (
      %CSCRIPT_PATH% //Nologo //B //E:vbs CompareVersions.vbs %SERVICING_VER% %%a
      if "!errorlevel!"=="3" (
        echo Installing %%c...
        call :Log "Info: Installing %%c"
        echo %%b>"%TEMP%\MissingUpdateIds.txt"
        set SERVICING_VER_NEW=%%a
        goto InstallServicingStack
      )
    )
  )
)
goto ServicingStackInstalled
:InstallServicingStack
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if not exist "%TEMP%\UpdatesToInstall.txt" (
  goto SkipServicingStack
)
call InstallListedUpdates.cmd %VERIFY_MODE% %DISM_MODE%
set ERR_LEVEL=%errorlevel%
rem echo DoUpdate: ERR_LEVEL=%ERR_LEVEL%
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
) else if "%ERR_LEVEL%" NEQ "0" (
  goto SkipServicingStack
)
call :Log "Info: Updated Servicing Stack to %SERVICING_VER_NEW%"
set SERVICING_VER=%SERVICING_VER_NEW%
goto CheckServicingStack
:ServicingStackInstalled
if "%RECALL_REQUIRED%"=="1" goto Installed
if "%REBOOT_REQUIRED%"=="1" goto Installed
:SkipServicingStack

rem *** Update Windows Update Agent ***
if "%OS_SHA2_SUPPORT%" NEQ "1" (
  echo Skipping installation of most recent Windows Update Agent due to missing SHA2 support...
  call :Log "Info: Skipped installation of most recent Windows Update Agent due to missing SHA2 support"
  goto SkipWUAInst
)
echo Checking Windows Update Agent version...
if %WUA_VER_MAJOR% LSS %WUA_VER_TARGET_MAJOR% goto InstallWUA
if %WUA_VER_MAJOR% GTR %WUA_VER_TARGET_MAJOR% goto SkipWUAInst
if %WUA_VER_MINOR% LSS %WUA_VER_TARGET_MINOR% goto InstallWUA
if %WUA_VER_MINOR% GTR %WUA_VER_TARGET_MINOR% goto SkipWUAInst
if %WUA_VER_BUILD% LSS %WUA_VER_TARGET_BUILD% goto InstallWUA
if %WUA_VER_BUILD% GTR %WUA_VER_TARGET_BUILD% goto SkipWUAInst
if %WUA_VER_REVIS% LSS %WUA_VER_TARGET_REVIS% goto InstallWUA
if %WUA_VER_REVIS% GEQ %WUA_VER_TARGET_REVIS% goto SkipWUAInst
:InstallWUA
if exist %SystemRoot%\Temp\wou_wua_tried.txt goto SkipWUAInst
if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
echo. >%SystemRoot%\Temp\wou_wua_tried.txt
if "%WUA_TARGET_ID%"=="" (
  echo Warning: Environment variable WUA_TARGET_ID not set.
  call :Log "Warning: Environment variable WUA_TARGET_ID not set"
  goto SkipWUAInst
)
echo %WUA_TARGET_ID%>"%TEMP%\MissingUpdateIds.txt"
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if exist "%TEMP%\UpdatesToInstall.txt" (
  echo Installing most recent Windows Update Agent...
  call InstallListedUpdates.cmd /selectoptions %VERIFY_MODE% %DISM_MODE% /errorsaswarnings
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=%ERR_LEVEL%
  if "!ERR_LEVEL!"=="3010" (
    set REBOOT_REQUIRED=1
  ) else if "!ERR_LEVEL!"=="3011" (
    set RECALL_REQUIRED=1
  ) else if "!ERR_LEVEL!" NEQ "0" (
    goto InstError
  )
  set WUA_SHA2_SUPPORT=1
) else (
  echo Warning: Windows Update Agent installation file ^(kb%WUA_TARGET_ID%^) not found.
  call :Log "Warning: Windows Update Agent installation file (kb%WUA_TARGET_ID%) not found"
  goto SkipWUAInst
)
rem FIXME 11.9.8 (b69)
set RECALL_REQUIRED=1
:SkipWUAInst
if "%RECALL_REQUIRED%"=="1" goto Installed

rem *** Install Internet Explorer ***
if "%OS_SRV_CORE%"=="1" goto SkipIEInst
if "%SKIP_IEINST%"=="/skipieinst" (
  echo Skipping installation of most recent Internet Explorer on demand...
  call :Log "Info: Skipped installation of most recent Internet Explorer on demand"
  goto SkipIEInst
)
echo Checking Internet Explorer version...
if not exist "%ProgramFiles%\Internet Explorer\iexplore.exe" (
  echo Skipping installation of most recent Internet Explorer ^(seems to be disabled on this system^)...
  call :Log "Info: Skipped installation of most recent Internet Explorer (seems to be disabled on this system)"
  goto SkipIEInst
)
if %IE_VER_MAJOR% LSS %IE_VER_TARGET_MAJOR% goto InstallIE
if %IE_VER_MAJOR% GTR %IE_VER_TARGET_MAJOR% goto SkipIEInst
if %IE_VER_MINOR% LSS %IE_VER_TARGET_MINOR% goto InstallIE
if %IE_VER_MINOR% GTR %IE_VER_TARGET_MINOR% goto SkipIEInst
if %IE_VER_BUILD% LSS %IE_VER_TARGET_BUILD% goto InstallIE
if %IE_VER_BUILD% GTR %IE_VER_TARGET_BUILD% goto SkipIEInst
if %IE_VER_REVIS% GEQ %IE_VER_TARGET_REVIS% goto SkipIEInst
:InstallIE
goto IE%OS_NAME%

:IEw60
if exist %SystemRoot%\Temp\wou_ie_tried.txt goto SkipIEInst
if /i "%OS_ARCH%"=="x64" (
  set IE_FILENAME=..\%OS_NAME%-%OS_ARCH%\glb\wu-ie9-windowsvista-%OS_ARCH%*.exe
  set IE_LANG_FILENAME=..\%OS_NAME%-%OS_ARCH%\glb\ie9-langpack-windowsvista-%OS_ARCH%-%OS_LANG%*.exe
) else (
  set IE_FILENAME=..\%OS_NAME%\glb\wu-ie9-windowsvista-%OS_ARCH%*.exe
  set IE_LANG_FILENAME=..\%OS_NAME%\glb\ie9-langpack-windowsvista-%OS_ARCH%-%OS_LANG%*.exe
)
dir /B %IE_FILENAME% >nul 2>&1
if errorlevel 1 (
  echo Warning: File %IE_FILENAME% not found.
  call :Log "Warning: File %IE_FILENAME% not found"
  goto SkipIEInst
)
for /F %%i in ('dir /B %IE_FILENAME%') do (
  if not "%%i"=="" set IE_FILENAME_REAL=%%i
)
if "%IE_FILENAME_REAL%"=="" (
  echo Warning: File %IE_FILENAME% not found.
  call :Log "Warning: File %IE_FILENAME% not found"
  goto SkipIEInst
)
if /i "%OS_ARCH%"=="x64" (
  set IE_FILENAME_REAL=..\%OS_NAME%-%OS_ARCH%\glb\%IE_FILENAME_REAL%
) else (
  set IE_FILENAME_REAL=..\%OS_NAME%\glb\%IE_FILENAME_REAL%
)

if /i "%OS_LANG%"=="enu" (goto SkipIEw60LPSearch)
dir /B %IE_LANG_FILENAME% >nul 2>&1
if errorlevel 1 (
  echo Warning: File %IE_LANG_FILENAME% not found.
  call :Log "Warning: File %IE_LANG_FILENAME% not found"
  goto SkipIEInst
)
for /F %%i in ('dir /B %IE_LANG_FILENAME%') do (
  if not "%%i"=="" set IE_LANG_FILENAME_SHORT=%%i
)
if "%IE_LANG_FILENAME_SHORT%"=="" (
  echo Warning: File %IE_LANG_FILENAME% not found.
  call :Log "Warning: File %IE_LANG_FILENAME% not found"
  goto SkipIEInst
)
if /i "%OS_ARCH%"=="x64" (
  set IE_LANG_FILENAME_FULL=..\%OS_NAME%-%OS_ARCH%\glb\%IE_LANG_FILENAME_SHORT%
) else (
  set IE_LANG_FILENAME_FULL=..\%OS_NAME%\glb\%IE_LANG_FILENAME_SHORT%
)
:SkipIEw60LPSearch
if exist %SystemRoot%\Temp\wou_iepre_tried.txt goto SkipIEw60Pre
echo Checking Internet Explorer 9 prerequisites...
%CSCRIPT_PATH% //Nologo //B //E:vbs ListInstalledUpdateIds.vbs
if exist "%TEMP%\InstalledUpdateIds.txt" (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\InstalledUpdateIds.txt" ..\static\StaticUpdateIds-ie9-w60.txt >"%TEMP%\MissingUpdateIds.txt"
  del "%TEMP%\InstalledUpdateIds.txt"
) else (
  copy /Y ..\static\StaticUpdateIds-ie9-w60.txt "%TEMP%\MissingUpdateIds.txt" >nul
)
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if exist "%TEMP%\UpdatesToInstall.txt" (
  echo Installing Internet Explorer 9 prerequisites...
  call InstallListedUpdates.cmd /selectoptions %VERIFY_MODE% %DISM_MODE% /ignoreerrors
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
  if "!ERR_LEVEL!"=="3010" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_iepre_tried.txt
    set REBOOT_REQUIRED=1
    goto IEInstalled
  ) else if "!ERR_LEVEL!"=="3011" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_iepre_tried.txt
    set RECALL_REQUIRED=1
    goto IEInstalled
  ) else if "!ERR_LEVEL!" GEQ "0" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_iepre_tried.txt
    rem FIXME 11.9.8 (b69)
    set RECALL_REQUIRED=1
    goto IEInstalled
  )
)
:SkipIEw60Pre
echo Installing Internet Explorer 9...
call InstallOSUpdate.cmd "%IE_FILENAME_REAL%" %VERIFY_MODE% /ignoreerrors /passive /update-no /closeprograms /no-default /norestart
set ERR_LEVEL=%errorlevel%
rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
) else if "%ERR_LEVEL%" NEQ "0" (
  if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
  echo. >%SystemRoot%\Temp\wou_ie_tried.txt
  goto IEInstalled
)
rem FIXME 11.9.8 (b69)
set RECALL_REQUIRED=1
if /i "%OS_LANG%"=="enu" (goto SkipIEw60LPInst)
echo Installing Internet Explorer 9 Language Pack...
if "%VERIFY_MODE%" NEQ "/verify" (goto SkipIEw60LPVerify)
if /i "%OS_ARCH%"=="x64" (
  set HASH_FILE_NAME=..\md\hashes-%OS_NAME%-%OS_ARCH%-glb.txt
) else (
  set HASH_FILE_NAME=..\md\hashes-%OS_NAME%-glb.txt
)
if not exist "%HASH_FILE_NAME%" (
  echo Warning: Hash file %HASH_FILE_NAME% not found.
  call :Log "Warning: Hash file %HASH_FILE_NAME% not found"
  goto SkipIEw60LPVerify
)
if exist "%TEMP%\hash-ieLangPack.txt" del "%TEMP%\hash-ieLangPack.txt"
%SystemRoot%\System32\findstr.exe /L /I /C:%% /C:"%IE_LANG_FILENAME_SHORT%" %HASH_FILE_NAME% >"%TEMP%\hash-ieLangPack.txt"
%HASHDEEP_PATH% -a -b -k "%TEMP%\hash-ieLangPack.txt" "%IE_LANG_FILENAME_FULL%"
if errorlevel 1 (
  if exist "%TEMP%\hash-ieLangPack.txt" del "%TEMP%\hash-ieLangPack.txt"
  echo ERROR: File hash does not match stored value ^(%IE_LANG_FILENAME_FULL%^).
  call :Log "Error: File hash does not match stored value (%IE_LANG_FILENAME_FULL%)"
  goto SkipIEw60LPInst
)
if exist "%TEMP%\hash-ieLangPack.txt" del "%TEMP%\hash-ieLangPack.txt"
:SkipIEw60LPVerify
if exist "%TEMP%\ie9-langpack-windowsvista-%OS_ARCH%-%OS_LANG%" rmdir /s /q "%TEMP%\ie9-langpack-windowsvista-%OS_ARCH%-%OS_LANG%"
mkdir "%TEMP%\ie9-langpack-windowsvista-%OS_ARCH%-%OS_LANG%"
start /wait %IE_LANG_FILENAME_FULL% /T:"%TEMP%\ie9-langpack-windowsvista-%OS_ARCH%-%OS_LANG%" /C
call InstallOSUpdate.cmd "%TEMP%\ie9-langpack-windowsvista-%OS_ARCH%-%OS_LANG%\ieLangPack-%OS_LANG%.cab" /ignoreerrors
set ERR_LEVEL=%errorlevel%
rmdir /s /q "%TEMP%\ie9-langpack-windowsvista-%OS_ARCH%-%OS_LANG%"
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
)
:SkipIEw60LPInst
if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
echo. >%SystemRoot%\Temp\wou_ie_tried.txt
goto IEInstalled

:IEw61
if exist %SystemRoot%\Temp\wou_ie_tried.txt goto SkipIEInst
if /i "%OS_ARCH%"=="x64" (
  set IE_FILENAME=..\%OS_NAME%-%OS_ARCH%\glb\IE11-Windows6.1-%OS_ARCH%-%OS_LANG_EXT%*.exe
) else (
  set IE_FILENAME=..\%OS_NAME%\glb\IE11-Windows6.1-%OS_ARCH%-%OS_LANG_EXT%*.exe
)
dir /B %IE_FILENAME% >nul 2>&1
if errorlevel 1 (
  echo Warning: File %IE_FILENAME% not found.
  call :Log "Warning: File %IE_FILENAME% not found"
  goto SkipIEInst
)
if exist %SystemRoot%\Temp\wou_iepre_tried.txt goto SkipIEw61Pre
echo Checking Internet Explorer 11 prerequisites...
%CSCRIPT_PATH% //Nologo //B //E:vbs ListInstalledUpdateIds.vbs
if exist "%TEMP%\InstalledUpdateIds.txt" (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\InstalledUpdateIds.txt" ..\static\StaticUpdateIds-ie11-w61.txt >"%TEMP%\MissingUpdateIds.txt"
  del "%TEMP%\InstalledUpdateIds.txt"
) else (
  copy /Y ..\static\StaticUpdateIds-ie11-w61.txt "%TEMP%\MissingUpdateIds.txt" >nul
)
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if exist "%TEMP%\UpdatesToInstall.txt" (
  echo Installing Internet Explorer 11 prerequisites...
  call InstallListedUpdates.cmd /selectoptions %VERIFY_MODE% %DISM_MODE% /ignoreerrors
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
  if "!ERR_LEVEL!"=="3010" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_iepre_tried.txt
    set REBOOT_REQUIRED=1
    goto IEInstalled
  ) else if "!ERR_LEVEL!"=="3011" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_iepre_tried.txt
    set RECALL_REQUIRED=1
    goto IEInstalled
  ) else if "!ERR_LEVEL!" GEQ "0" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_iepre_tried.txt
    rem FIXME 11.9.8 (b69)
    set RECALL_REQUIRED=1
    goto IEInstalled
  )
)
:SkipIEw61Pre
echo Installing Internet Explorer 11...
for /F %%i in ('dir /B %IE_FILENAME%') do (
  if /i "%OS_ARCH%"=="x64" (
    call InstallOSUpdate.cmd "..\%OS_NAME%-%OS_ARCH%\glb\%%i" %VERIFY_MODE% /ignoreerrors /passive /update-no /closeprograms /no-default /norestart
  ) else (
    call InstallOSUpdate.cmd "..\%OS_NAME%\glb\%%i" %VERIFY_MODE% /ignoreerrors /passive /update-no /closeprograms /no-default /norestart
  )
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
  if "!ERR_LEVEL!"=="3010" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_ie_tried.txt
    set REBOOT_REQUIRED=1
    goto IEInstalled
  ) else if "!ERR_LEVEL!"=="3011" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_ie_tried.txt
    set RECALL_REQUIRED=1
    goto IEInstalled
  ) else if "!ERR_LEVEL!" GEQ "0" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_ie_tried.txt
    rem FIXME 11.9.8 (b69)
    set RECALL_REQUIRED=1
    goto IEInstalled
  )
)
goto IEInstalled

:IEw62
if /i "%OS_ARCH%" NEQ "x64" goto SkipIEInst
if exist %SystemRoot%\Temp\wou_ie_tried.txt goto SkipIEInst
set IE_FILENAME=..\%OS_NAME%-%OS_ARCH%\glb\ie11-win6.2*.msu
set IE_LANG_FILENAME=..\%OS_NAME%-%OS_ARCH%\glb\ie11-windows6.2-languagepack-%OS_ARCH%-%OS_LANG_EXT%*.msu
dir /B %IE_FILENAME% >nul 2>&1
if errorlevel 1 (
  echo Warning: File %IE_FILENAME% not found.
  call :Log "Warning: File %IE_FILENAME% not found"
  goto SkipIEInst
)
if exist %SystemRoot%\Temp\wou_iepre_tried.txt goto SkipIEw62Pre
echo Checking Internet Explorer 11 prerequisites...
%CSCRIPT_PATH% //Nologo //B //E:vbs ListInstalledUpdateIds.vbs
if exist "%TEMP%\InstalledUpdateIds.txt" (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\InstalledUpdateIds.txt" ..\static\StaticUpdateIds-ie11-w62.txt >"%TEMP%\MissingUpdateIds.txt"
  del "%TEMP%\InstalledUpdateIds.txt"
) else (
  copy /Y ..\static\StaticUpdateIds-ie11-w62.txt "%TEMP%\MissingUpdateIds.txt" >nul
)
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if exist "%TEMP%\UpdatesToInstall.txt" (
  echo Installing Internet Explorer 11 prerequisites...
  call InstallListedUpdates.cmd /selectoptions %VERIFY_MODE% %DISM_MODE% /ignoreerrors
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
  if "!ERR_LEVEL!"=="3010" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_iepre_tried.txt
    set REBOOT_REQUIRED=1
    goto IEInstalled
  ) else if "!ERR_LEVEL!"=="3011" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_iepre_tried.txt
    set RECALL_REQUIRED=1
    goto IEInstalled
  ) else if "!ERR_LEVEL!" GEQ "0" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_iepre_tried.txt
    rem FIXME 11.9.8 (b69)
    set RECALL_REQUIRED=1
    goto IEInstalled
  )
)
:SkipIEw62Pre
echo Installing Internet Explorer 11...
for /F %%i in ('dir /B %IE_FILENAME%') do (
  call InstallOSUpdate.cmd "..\%OS_NAME%-%OS_ARCH%\glb\%%i" %VERIFY_MODE% /ignoreerrors /passive /qn /norestart
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
  if "!ERR_LEVEL!"=="3010" (
    set REBOOT_REQUIRED=1
  ) else if "!ERR_LEVEL!"=="3011" (
    set RECALL_REQUIRED=1
  ) else if "!ERR_LEVEL!" NEQ "0" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_ie_tried.txt
    goto IEInstalled
  )

  rem FIXME 11.9.8 (b69)
  set RECALL_REQUIRED=1

  dir /B %IE_LANG_FILENAME% >nul 2>&1
  if not errorlevel 1 (
    echo Installing Internet Explorer 11 language pack...
    for /F %%i in ('dir /B %IE_LANG_FILENAME%') do (
      call InstallOSUpdate.cmd "..\%OS_NAME%-%OS_ARCH%\glb\%%i" %VERIFY_MODE% /ignoreerrors /passive /qn /norestart
      set ERR_LEVEL=!errorlevel!
      rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
      if "!ERR_LEVEL!"=="3010" (
        set REBOOT_REQUIRED=1
      ) else if "!ERR_LEVEL!"=="3011" (
        set RECALL_REQUIRED=1
      )
    )
  )

  if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
  echo. >%SystemRoot%\Temp\wou_ie_tried.txt
)
goto IEInstalled

:IEw63
:IEw100
:IEInstalled
set IE_FILENAME=
if "%RECALL_REQUIRED%"=="1" goto Installed
if "%REBOOT_REQUIRED%"=="1" goto Installed
:SkipIEInst

rem *** Install .NET Framework 3.5 SP1 ***
if "%INSTALL_DOTNET35%" NEQ "/instdotnet35" goto SkipDotNet35Inst
if "%OS_NAME%"=="w61" goto SkipDotNet35Inst
echo Checking .NET Framework 3.5 installation state...
if %DOTNET35_VER_MAJOR% LSS %DOTNET35_VER_TARGET_MAJOR% goto InstallDotNet35
if %DOTNET35_VER_MAJOR% GTR %DOTNET35_VER_TARGET_MAJOR% goto SkipDotNet35Inst
if %DOTNET35_VER_MINOR% LSS %DOTNET35_VER_TARGET_MINOR% goto InstallDotNet35
if %DOTNET35_VER_MINOR% GTR %DOTNET35_VER_TARGET_MINOR% goto SkipDotNet35Inst
if %DOTNET35_VER_BUILD% LSS %DOTNET35_VER_TARGET_BUILD% goto InstallDotNet35
if %DOTNET35_VER_BUILD% GTR %DOTNET35_VER_TARGET_BUILD% goto SkipDotNet35Inst
if %DOTNET35_VER_REVIS% GEQ %DOTNET35_VER_TARGET_REVIS% goto SkipDotNet35Inst
:InstallDotNet35
if exist %SystemRoot%\Temp\wou_net35_tried.txt goto SkipDotNet35Inst
if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
echo. >%SystemRoot%\Temp\wou_net35_tried.txt
if "%OS_NAME%"=="w62" goto InstallDotNet35%OS_NAME%
if "%OS_NAME%"=="w63" goto InstallDotNet35%OS_NAME%
if "%OS_NAME%"=="w100" goto InstallDotNet35%OS_NAME%
set DOTNET35_FILENAME=..\dotnet\dotnetfx35.exe
set DOTNET35LP_FILENAME=..\dotnet\dotnetfx35langpack_%OS_ARCH%%OS_LANG_SHORT%*.exe
if not exist %DOTNET35_FILENAME% (
  echo Warning: .NET Framework 3.5 SP1 installation file ^(%DOTNET35_FILENAME%^) not found.
  call :Log "Warning: .NET Framework 3.5 SP1 installation file (%DOTNET35_FILENAME%) not found"
  goto SkipDotNet35Inst
)
echo Installing .NET Framework 3.5 SP1...
call InstallOSUpdate.cmd "%DOTNET35_FILENAME%" %VERIFY_MODE% /ignoreerrors /passive /norestart /lang:enu
set ERR_LEVEL=%errorlevel%
rem echo DoUpdate: ERR_LEVEL=%ERR_LEVEL%
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
) else if "%ERR_LEVEL%" NEQ "0" (
  goto SkipDotNet35Inst
)
if "%OS_LANG%" NEQ "enu" (
  dir /B %DOTNET35LP_FILENAME% >nul 2>&1
  if errorlevel 1 (
    echo Warning: .NET Framework 3.5 SP1 Language Pack installation file ^(%DOTNET35LP_FILENAME%^) not found.
    call :Log "Warning: .NET Framework 3.5 SP1 Language Pack installation file (%DOTNET35LP_FILENAME%) not found"
  ) else (
    echo Installing .NET Framework 3.5 SP1 Language Pack...
    for /F %%i in ('dir /B %DOTNET35LP_FILENAME%') do (
      call InstallOSUpdate.cmd "..\dotnet\%%i" %VERIFY_MODE% /ignoreerrors /passive /norestart /nopatch /lang:%OS_LANG%
      set ERR_LEVEL=!errorlevel!
      rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
      if "!ERR_LEVEL!"=="3010" (
        set REBOOT_REQUIRED=1
      ) else if "!ERR_LEVEL!"=="3011" (
        set RECALL_REQUIRED=1
      )
    )
  )
)
copy /Y ..\static\StaticUpdateIds-dotnet35.txt "%TEMP%\MissingUpdateIds.txt" >nul
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if exist "%TEMP%\UpdatesToInstall.txt" (
  echo Installing .NET Framework 3.5 SP1 Family Update...
  call InstallListedUpdates.cmd /selectoptions %VERIFY_MODE% %DISM_MODE% /ignoreerrors
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
  if "!ERR_LEVEL!"=="3010" (
    set REBOOT_REQUIRED=1
  ) else if "!ERR_LEVEL!"=="3011" (
    set RECALL_REQUIRED=1
  )
)
rem FIXME 11.9.8 (b69)
set RECALL_REQUIRED=1
set DOTNET35_FILENAME=
set DOTNET35LP_FILENAME=
goto SkipDotNet35Inst

:InstallDotNet35w62
:InstallDotNet35w63
:InstallDotNet35w100
if /i "%OS_ARCH%"=="x64" (
  if exist ..\%OS_NAME%-%OS_ARCH%\%OS_LANG%\sxs\nul (
    if exist %SystemRoot%\Sysnative\Dism.exe (
      echo Enabling .NET Framework 3.5 feature...
      %SystemRoot%\Sysnative\Dism.exe /Online /Quiet /NoRestart /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:..\%OS_NAME%-%OS_ARCH%\%OS_LANG%\sxs
      set ERR_LEVEL=!errorlevel!
      rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
      if "!ERR_LEVEL!"=="3010" (
        call :Log "Info: Enabled .NET Framework 3.5 feature"
        set REBOOT_REQUIRED=1
      ) else if "!ERR_LEVEL!"=="3011" (
        call :Log "Info: Enabled .NET Framework 3.5 feature"
        set RECALL_REQUIRED=1
      ) else if "!ERR_LEVEL!" NEQ "0" (
        call :Log "Warning: Failed to enable .NET Framework 3.5 feature"
      ) else (
        call :Log "Info: Enabled .NET Framework 3.5 feature"
      )
    ) else (
      if exist %SystemRoot%\System32\Dism.exe (
        echo Enabling .NET Framework 3.5 feature...
        %SystemRoot%\System32\Dism.exe /Online /Quiet /NoRestart /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:..\%OS_NAME%-%OS_ARCH%\%OS_LANG%\sxs
        set ERR_LEVEL=!errorlevel!
        rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
        if "!ERR_LEVEL!"=="3010" (
          call :Log "Info: Enabled .NET Framework 3.5 feature"
          set REBOOT_REQUIRED=1
        ) else if "!ERR_LEVEL!"=="3011" (
          call :Log "Info: Enabled .NET Framework 3.5 feature"
          set RECALL_REQUIRED=1
        ) else if "!ERR_LEVEL!" NEQ "0" (
          call :Log "Warning: Failed to enable .NET Framework 3.5 feature"
        ) else (
          call :Log "Info: Enabled .NET Framework 3.5 feature"
        )
      ) else (
        echo Warning: Utility %SystemRoot%\System32\Dism.exe not found. Unable to enable .NET Framework 3.5 feature.
        call :Log "Warning: Utility %SystemRoot%\System32\Dism.exe not found. Unable to enable .NET Framework 3.5 feature"
        goto SkipDotNet35Inst
      )
    )
  ) else (
    echo Warning: Directory ..\%OS_NAME%-%OS_ARCH%\%OS_LANG%\sxs not found. Unable to enable .NET Framework 3.5 feature.
    call :Log "Warning: Directory ..\%OS_NAME%-%OS_ARCH%\%OS_LANG%\sxs not found. Unable to enable .NET Framework 3.5 feature"
    goto SkipDotNet35Inst
  )
) else (
  if exist ..\%OS_NAME%\%OS_LANG%\sxs\nul (
    if exist %SystemRoot%\System32\Dism.exe (
      echo Enabling .NET Framework 3.5 feature...
      %SystemRoot%\System32\Dism.exe /Online /Quiet /NoRestart /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:..\%OS_NAME%\%OS_LANG%\sxs
      set ERR_LEVEL=!errorlevel!
      rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
      if "!ERR_LEVEL!"=="3010" (
        call :Log "Info: Enabled .NET Framework 3.5 feature"
        set REBOOT_REQUIRED=1
      ) else if "!ERR_LEVEL!"=="3011" (
        call :Log "Info: Enabled .NET Framework 3.5 feature"
        set RECALL_REQUIRED=1
      ) else if "!ERR_LEVEL!" NEQ "0" (
        call :Log "Warning: Failed to enable .NET Framework 3.5 feature"
      ) else (
        call :Log "Info: Enabled .NET Framework 3.5 feature"
      )
    ) else (
      echo Warning: Utility %SystemRoot%\System32\Dism.exe not found. Unable to enable .NET Framework 3.5 feature.
      call :Log "Warning: Utility %SystemRoot%\System32\Dism.exe not found. Unable to enable .NET Framework 3.5 feature"
      goto SkipDotNet35Inst
    )
  ) else (
    echo Warning: Directory ..\%OS_NAME%\%OS_LANG%\sxs not found. Unable to enable .NET Framework 3.5 feature.
    call :Log "Warning: Directory ..\%OS_NAME%\%OS_LANG%\sxs not found. Unable to enable .NET Framework 3.5 feature"
    goto SkipDotNet35Inst
  )
)
rem FIXME 11.9.8 (b69)
set REBOOT_REQUIRED=1
:SkipDotNet35Inst

rem *** Install .NET Framework 4 ***
if "%INSTALL_DOTNET4%" NEQ "/instdotnet4" goto SkipDotNet4Inst
echo Checking .NET Framework 4 installation state...
if %DOTNET4_VER_MAJOR% LSS %DOTNET4_VER_TARGET_MAJOR% goto InstallDotNet4
if %DOTNET4_VER_MAJOR% GTR %DOTNET4_VER_TARGET_MAJOR% goto SkipDotNet4Inst
if %DOTNET4_VER_MINOR% LSS %DOTNET4_VER_TARGET_MINOR% goto InstallDotNet4
if %DOTNET4_VER_MINOR% GTR %DOTNET4_VER_TARGET_MINOR% goto SkipDotNet4Inst
if %DOTNET4_VER_BUILD% GEQ %DOTNET4_VER_TARGET_BUILD% goto SkipDotNet4Inst
:InstallDotNet4
if exist %SystemRoot%\Temp\wou_net4_tried.txt goto SkipDotNet4Inst
if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
echo. >%SystemRoot%\Temp\wou_net4_tried.txt
if "%OS_NAME%"=="w60" (
  echo Checking .NET Framework 4 prerequisite...
  if "%DOTNET4_PREREQ_ID%"=="" (
    echo Warning: Environment variable DOTNET4_PREREQ_ID not set.
    call :Log "Warning: Environment variable DOTNET4_PREREQ_ID not set"
    goto SkipDotNet4Inst
  )
  %CSCRIPT_PATH% //Nologo //B //E:vbs ListInstalledUpdateIds.vbs
  if exist "%TEMP%\InstalledUpdateIds.txt" (
    rem check, if KB956250 is installed installed
    type "%TEMP%\InstalledUpdateIds.txt" | find "%DOTNET4_PREREQ_ID%" >nul 2>&1
    if errorlevel 1 (
      echo Installing .NET Framework 4 prerequisite...
      echo %DOTNET4_PREREQ_ID%>"%TEMP%\MissingUpdateIds.txt"
      call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
      if errorlevel 1 goto ListError
      if exist "%TEMP%\UpdatesToInstall.txt" (
        call InstallListedUpdates.cmd /selectoptions %VERIFY_MODE% %DISM_MODE% /errorsaswarnings
        set ERR_LEVEL=!errorlevel!
        rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
        if "!ERR_LEVEL!"=="3010" (
          set REBOOT_REQUIRED=1
        ) else if "!ERR_LEVEL!"=="3011" (
          set RECALL_REQUIRED=1
        ) else if "!ERR_LEVEL!" NEQ "0" (
          goto InstError
        )
      ) else (
        echo Warning: .NET Framework 4 prerequisite installation file ^(kb%DOTNET4_PREREQ_ID%^) not found.
        call :Log "Warning: .NET Framework 4 prerequisite installation file (kb%DOTNET4_PREREQ_ID%) not found"
        goto SkipDotNet4Inst
      )
    )
    if exist "%TEMP%\InstalledUpdateIds.txt" del "%TEMP%\InstalledUpdateIds.txt"
  )
)
if "%OS_NAME%"=="w60" (
  set DOTNET4_FILENAME=..\dotnet\ndp462-kb3151800-x86-x64-allos-enu.exe
  set DOTNET4LP_FILENAME=..\dotnet\ndp462-kb3151800-x86-x64-allos-%OS_LANG%.exe
) else if "%OS_NAME%"=="w100" (
  if %OS_VER_BUILD_INTERNAL% LSS 14393 (
    set DOTNET4_FILENAME=..\dotnet\ndp462-kb3151800-x86-x64-allos-enu.exe
    set DOTNET4LP_FILENAME=..\dotnet\ndp462-kb3151800-x86-x64-allos-%OS_LANG%.exe
  ) else (
    set DOTNET4_FILENAME=..\dotnet\ndp48-x86-x64-allos-enu.exe
    set DOTNET4LP_FILENAME=..\dotnet\ndp48-x86-x64-allos-%OS_LANG%.exe
  )
) else (
  set DOTNET4_FILENAME=..\dotnet\ndp48-x86-x64-allos-enu.exe
  set DOTNET4LP_FILENAME=..\dotnet\ndp48-x86-x64-allos-%OS_LANG%.exe
)
if "%OS_SRV_CORE%"=="1" (
  set DOTNET4_INSTOPTS=/q /norestart
) else (
  set DOTNET4_INSTOPTS=/passive /norestart
)
if not exist %DOTNET4_FILENAME% (
  echo Warning: .NET Framework 4 installation file ^(%DOTNET4_FILENAME%^) not found.
  call :Log "Warning: .NET Framework 4 installation file (%DOTNET4_FILENAME%) not found"
  goto SkipDotNet4Inst
)
echo Installing .NET Framework 4...
call InstallOSUpdate.cmd "%DOTNET4_FILENAME%" %VERIFY_MODE% /errorsaswarnings %DOTNET4_INSTOPTS% /lcid 1033
set ERR_LEVEL=%errorlevel%
rem echo DoUpdate: ERR_LEVEL=%ERR_LEVEL%
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
) else if "%ERR_LEVEL%" NEQ "0" (
  goto SkipDotNet4Inst
)
if "%OS_LANG%" NEQ "enu" (
  if exist %DOTNET4LP_FILENAME% (
    echo Installing .NET Framework 4 Language Pack...
    for /F %%i in ('dir /B %DOTNET4LP_FILENAME%') do (
      call InstallOSUpdate.cmd "..\dotnet\%%i" %VERIFY_MODE% /errorsaswarnings %DOTNET4_INSTOPTS%
      set ERR_LEVEL=!errorlevel!
      rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
      if "!ERR_LEVEL!"=="3010" (
        set REBOOT_REQUIRED=1
      ) else if "!ERR_LEVEL!"=="3011" (
        set RECALL_REQUIRED=1
      )
    )
  ) else (
    echo Warning: .NET Framework 4 Language Pack installation file ^(%DOTNET4LP_FILENAME%^) not found.
    call :Log "Warning: .NET Framework 4 Language Pack installation file (%DOTNET4LP_FILENAME%) not found"
  )
)
rem FIXME 11.9.8 (b69)
set RECALL_REQUIRED=1
set DOTNET4_FILENAME=
set DOTNET4LP_FILENAME=
set DOTNET4_INSTOPTS=
:SkipDotNet4Inst

rem *** Install .NET Framework 3.5 - Custom ***
if "%INSTALL_DOTNET35%"=="/instdotnet35" goto InstallDotNet35Custom
if "%DOTNET35_VER_MAJOR%%DOTNET35_VER_MINOR%"=="%DOTNET35_VER_TARGET_MAJOR%%DOTNET35_VER_TARGET_MINOR%" goto InstallDotNet35Custom
goto SkipDotNet35CustomInst
:InstallDotNet35Custom
if not exist ..\static\custom\StaticUpdateIds-dotnet35.txt goto SkipDotNet35CustomInst
echo Checking .NET Framework 3.5 custom updates...
%CSCRIPT_PATH% //Nologo //B //E:vbs ListInstalledUpdateIds.vbs
if exist "%TEMP%\InstalledUpdateIds.txt" (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\InstalledUpdateIds.txt" ..\static\custom\StaticUpdateIds-dotnet35.txt >"%TEMP%\MissingUpdateIds.txt"
  del "%TEMP%\InstalledUpdateIds.txt"
) else (
  copy /Y ..\static\custom\StaticUpdateIds-dotnet35.txt "%TEMP%\MissingUpdateIds.txt" >nul
)
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if exist "%TEMP%\UpdatesToInstall.txt" (
  echo Installing .NET Framework 3.5 custom updates...
  call InstallListedUpdates.cmd /selectoptions %VERIFY_MODE% %DISM_MODE% /ignoreerrors
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
)
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
) else if "%ERR_LEVEL%" NEQ "0" (
  goto InstError
)
:SkipDotNet35CustomInst
rem *** Install .NET Framework 4 - Custom ***
if "%INSTALL_DOTNET4%"=="/instdotnet4" goto InstallDotNet4Custom
if %DOTNET4_VER_MAJOR% EQU %DOTNET4_VER_TARGET_MAJOR% goto InstallDotNet4Custom
goto SkipDotNet4CustomInst
:InstallDotNet4Custom
if not exist ..\static\custom\StaticUpdateIds-dotnet4.txt goto SkipDotNet4CustomInst
echo Checking .NET Framework 4 custom updates...
%CSCRIPT_PATH% //Nologo //B //E:vbs ListInstalledUpdateIds.vbs
if exist "%TEMP%\InstalledUpdateIds.txt" (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\InstalledUpdateIds.txt" ..\static\custom\StaticUpdateIds-dotnet4.txt >"%TEMP%\MissingUpdateIds.txt"
  del "%TEMP%\InstalledUpdateIds.txt"
) else (
  copy /Y ..\static\custom\StaticUpdateIds-dotnet4.txt "%TEMP%\MissingUpdateIds.txt" >nul
)
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if exist "%TEMP%\UpdatesToInstall.txt" (
  echo Installing .NET Framework 4 custom updates...
  call InstallListedUpdates.cmd /selectoptions %VERIFY_MODE% %DISM_MODE% /ignoreerrors
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
)
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
) else if "%ERR_LEVEL%" NEQ "0" (
  goto InstError
)
:SkipDotNet4CustomInst
if "%RECALL_REQUIRED%"=="1" goto Installed
if "%REBOOT_REQUIRED%"=="1" goto Installed

rem *** Install Windows Management Framework ***
if "%INSTALL_WMF%" NEQ "/instwmf" goto SkipWMFInst
if "%OS_NAME%"=="w100" goto SkipWMFInst
if "%OS_NAME%"=="w60" (if %OS_DOMAIN_ROLE% LSS 2 goto SkipWMFInst)
if %DOTNET4_VER_MAJOR% LSS %DOTNET4_VER_TARGET_MAJOR% (
  echo Warning: Missing Windows Management Framework prerequisite .NET Framework 4.
  call :Log "Warning: Missing Windows Management Framework prerequisite .NET Framework ^4"
  goto SkipWMFInst
)
echo Checking Windows Management Framework installation state...
if %WMF_VER_MAJOR% LSS %WMF_VER_TARGET_MAJOR% goto InstallWMF
if %WMF_VER_MAJOR% GTR %WMF_VER_TARGET_MAJOR% goto SkipWMFInst
if %WMF_VER_MINOR% LSS %WMF_VER_TARGET_MINOR% goto InstallWMF
if %WMF_VER_MINOR% GEQ %WMF_VER_TARGET_MINOR% goto SkipWMFInst
:InstallWMF
if exist %SystemRoot%\Temp\wou_wmf_tried.txt goto SkipWMFInst
if exist "%SystemRoot%\Temp\wou_wmf_tried_kb%WMF_TARGET_ID%.txt" goto SkipWMFInst
if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
if "%WMF_TARGET_ID%"=="" (
  echo. >%SystemRoot%\Temp\wou_wmf_tried.txt
  echo Warning: Environment variable WMF_TARGET_ID not set.
  call :Log "Warning: Environment variable WMF_TARGET_ID not set"
  goto SkipWMFInst
)
echo. >%SystemRoot%\Temp\wou_wmf_tried_kb%WMF_TARGET_ID%.txt
if "%OS_NAME%"=="w61" (
  if %WMF_VER_MAJOR% EQU 3 (
    echo Warning: WMF 5.1 must not be installed over WMF 3.0. Please uninstall WMF 3.0 first.
    call :Log "Warning: WMF 5.1 must not be installed over WMF 3.0. Please uninstall WMF 3.0 first."
    goto SkipWMFInst
  )
)
echo %WMF_TARGET_ID%>"%TEMP%\MissingUpdateIds.txt"
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if exist "%TEMP%\UpdatesToInstall.txt" (
  echo Installing Windows Management Framework...
  call InstallListedUpdates.cmd /selectoptions %VERIFY_MODE% %DISM_MODE% /errorsaswarnings
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
) else (
  echo Warning: Windows Management Framework installation file ^(kb%WMF_TARGET_ID%^) not found.
  call :Log "Warning: Windows Management Framework installation file (kb%WMF_TARGET_ID%) not found"
  goto SkipWMFInst
)
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
) else if "%ERR_LEVEL%" NEQ "0" (
  goto InstError
)
rem FIXME 11.9.8 (b69)
set RECALL_REQUIRED=1
:SkipWMFInst

rem *** MSI-detection based products (such as CPP and dotNet5) ***
set CURRENT_MSIPRODUCT_ATTEMPTINSTALL=
set CURRENT_MSIPRODUCT_NEEDSINSTALL=
set CURRENT_MSIPRODUCT_ID=
set CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL=
set CURRENT_MSIPRODUCT_FILENAME_FINAL=
for /f "tokens=1,2,3 delims=," %%a in (..\static\StaticUpdateIds-MSIProducts.txt) do (
  rem echo MSI a: %%a
  rem echo MSI b: %%b
  rem echo MSI c: %%c

  set CURRENT_MSIPRODUCT_ID=%%a
  
  rem The idea behind this is, that every token of the for loop is a folder name as long as it is not the last one
  rem FIXME: This mus be possible with some kind of "for /L"-loop
  set CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL=
  if "%%c" NEQ "" (
    for /f "tokens=1,2,3,4,5,6 delims=\" %%f in ('echo %%c') do (
      if "%%f"=="" (
        rem ERROR (kein Pfad angegeben)
        set CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL=
      ) else if "%%g"=="" (
        set CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL=.
      ) else if "%%h"=="" (
        set CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL=%%f
      ) else if "%%i"=="" (
        set CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL=%%f\%%g
      ) else if "%%j"=="" (
        set CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL=%%f\%%g\%%h
      ) else if "%%k"=="" (
        set CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL=%%f\%%g\%%h\%%i
      ) else (
	    rem ERROR (maximale Iterationstiefe erreicht)
        set CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL=
      )
    )
  ) else (
    set CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL=
  )
  rem echo CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL=!CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL!
  
  rem check user options
  if /i "!CURRENT_MSIPRODUCT_ID:~0,3!"=="cpp" (
    rem C++ runtimes
    if "%UPDATE_CPP%"=="/updatecpp" (set CURRENT_MSIPRODUCT_ATTEMPTINSTALL=1) else (set CURRENT_MSIPRODUCT_ATTEMPTINSTALL=0)
    if exist %SystemRoot%\Temp\wou_cpp_tried.txt (set CURRENT_MSIPRODUCT_ATTEMPTINSTALL=0)
  ) else (
    rem nothing else supported yet
    set CURRENT_MSIPRODUCT_ATTEMPTINSTALL=0
  )
  
  rem echo CURRENT_MSIPRODUCT_ATTEMPTINSTALL [1]: !CURRENT_MSIPRODUCT_ATTEMPTINSTALL!
  
  rem some additional checking just to be sure
  if "%%b"=="" (set CURRENT_MSIPRODUCT_ATTEMPTINSTALL=0)
  if "%%c"=="" (set CURRENT_MSIPRODUCT_ATTEMPTINSTALL=0)
  if "!CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL!"=="" (set CURRENT_MSIPRODUCT_ATTEMPTINSTALL=0)
  
  rem echo CURRENT_MSIPRODUCT_ATTEMPTINSTALL [2]: !CURRENT_MSIPRODUCT_ATTEMPTINSTALL!
  
  rem check system architecture
  if /i "!CURRENT_MSIPRODUCT_ID:~-3!"=="x64" (
    if "%OS_ARCH%" NEQ "x64" (set CURRENT_MSIPRODUCT_ATTEMPTINSTALL=0)
  ) else if /i "!CURRENT_MSIPRODUCT_ID:~-3!"=="x86" (
    rem should always work
  ) else (
    rem unknown architecture
    set CURRENT_MSIPRODUCT_ATTEMPTINSTALL=0
  )
  
  rem echo CURRENT_MSIPRODUCT_ATTEMPTINSTALL [3]: !CURRENT_MSIPRODUCT_ATTEMPTINSTALL!
  
  rem check, if DetermineSystemProperties.vbs listed the component as outdated
  if "!CURRENT_MSIPRODUCT_ATTEMPTINSTALL!"=="1" (
    call set "CURRENT_MSIPRODUCT_NEEDSINSTALL=%%!CURRENT_MSIPRODUCT_ID!%%"
  ) else (
    set CURRENT_MSIPRODUCT_NEEDSINSTALL=0
  )
  
  rem echo CURRENT_MSIPRODUCT_NEEDSINSTALL: !CURRENT_MSIPRODUCT_NEEDSINSTALL!
  
  if "!CURRENT_MSIPRODUCT_NEEDSINSTALL!"=="1" (
    rem try to find file
    dir /B "%%c" >nul 2>&1
    if not errorlevel 1 (
      rem if found, try to get complete file name
      set CURRENT_MSIPRODUCT_FILENAME_FINAL=
      for /F %%i in ('dir /B %%c') do (
        if not "%%i"=="" set CURRENT_MSIPRODUCT_FILENAME_FINAL=%%i
      )
      if not "!CURRENT_MSIPRODUCT_FILENAME_FINAL!"=="" (
        rem using full file name, try to install
        echo Installing most recent version of %%b...
        call InstallOSUpdate.cmd "!CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL!\!CURRENT_MSIPRODUCT_FILENAME_FINAL!" %VERIFY_MODE% /errorsaswarnings
        set ERR_LEVEL=!errorlevel!
        rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
        if "!ERR_LEVEL!"=="3010" (
          set REBOOT_REQUIRED=1
        ) else if "!ERR_LEVEL!"=="3011" (
          set RECALL_REQUIRED=1
        )
      ) else (
        echo Warning: File %%c not found.
        call :Log "Warning: File %%c not found"
      )
    ) else (
      echo Warning: File %%c not found.
      call :Log "Warning: File %%c not found"
    )
  )
)
if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
if "%UPDATE_CPP%"=="/updatecpp" echo. >%SystemRoot%\Temp\wou_cpp_tried.txt
set CURRENT_MSIPRODUCT_SHOULDINSTALL=
set CURRENT_MSIPRODUCT_NEEDSINSTALL=
set CURRENT_MSIPRODUCT_ID=
set CURRENT_MSIPRODUCT_FILEDIRECTORY_FINAL=
set CURRENT_MSIPRODUCT_FILENAME_FINAL=

rem *** Install most recent Remote Desktop Client ***
if "%UPDATE_TSC%" NEQ "/updatetsc" goto SkipTSCInst
echo Checking Remote Desktop Client version...
if %TSC_VER_MAJOR% LSS %TSC_VER_TARGET_MAJOR% goto InstallTSC
if %TSC_VER_MAJOR% GTR %TSC_VER_TARGET_MAJOR% goto SkipTSCInst
if %TSC_VER_MINOR% LSS %TSC_VER_TARGET_MINOR% goto InstallTSC
if %TSC_VER_MINOR% GEQ %TSC_VER_TARGET_MINOR% goto SkipTSCInst
:InstallTSC
if "%TSC_TARGET_ID%"=="" (
  if "%TSC_TARGET_ID_FILE%"=="" (
    echo Warning: Environment variables TSC_TARGET_ID and TSC_TARGET_ID_FILE not set.
    call :Log "Warning: Environment variables TSC_TARGET_ID and TSC_TARGET_ID_FILE not set"
    goto SkipTSCInst
  ) else (
    echo Checking Remote Desktop Client components...
    %CSCRIPT_PATH% //Nologo //B //E:vbs ListInstalledUpdateIds.vbs
    if exist "%TEMP%\InstalledUpdateIds.txt" (
      %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\InstalledUpdateIds.txt" %TSC_TARGET_ID_FILE% >"%TEMP%\MissingUpdateIds.txt"
      del "%TEMP%\InstalledUpdateIds.txt"
    ) else (
      copy /Y %TSC_TARGET_ID_FILE% "%TEMP%\MissingUpdateIds.txt" >nul
    )
  )
) else (
  echo %TSC_TARGET_ID%>"%TEMP%\MissingUpdateIds.txt"
)
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if exist "%TEMP%\UpdatesToInstall.txt" (
  echo Installing most recent Remote Desktop Client...
  call InstallListedUpdates.cmd /selectoptions %VERIFY_MODE% %DISM_MODE% /errorsaswarnings
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
  if "!ERR_LEVEL!"=="3010" (
    set REBOOT_REQUIRED=1
  ) else if "!ERR_LEVEL!"=="3011" (
    set RECALL_REQUIRED=1
  )
) else (
  echo Warning: Remote Desktop Client installation file^(s^) not found.
  call :Log "Warning: Remote Desktop Client installation file(s) not found"
  goto SkipTSCInst
)
rem FIXME 11.9.8 (b69)
set RECALL_REQUIRED=1
:SkipTSCInst
if "%REBOOT_REQUIRED%"=="1" goto Installed
if "%RECALL_REQUIRED%"=="1" goto Installed

rem *** Update Windows Defender definitions ***
echo Checking Windows Defender installation state...
if "%WD_INSTALLED%" NEQ "1" goto SkipWDInst
if "%WD_DISABLED%"=="1" goto SkipWDInst
if "%SKIP_DEFS%"=="/skipdefs" goto SkipWDInst
if "%OS_NAME%"=="w62" goto WDmpam
if "%OS_NAME%"=="w63" goto WDmpam
if "%OS_NAME%"=="w100" goto WDmpam
set WDDEFS_FILENAME=..\wddefs\%OS_ARCH%-glb\mpas-fe.exe
goto WDmpas
:WDmpam
set WDDEFS_FILENAME=..\msse\%OS_ARCH%-glb\mpam-fe.exe
:WDmpas
if not exist %WDDEFS_FILENAME% (
  echo Warning: Windows Defender definition file ^(%WDDEFS_FILENAME%^) not found.
  call :Log "Warning: Windows Defender definition file (%WDDEFS_FILENAME%) not found"
  goto SkipWDInst
)
rem *** Determine Windows Defender definition file version ***
echo Determining Windows Defender definition file version...
%CSCRIPT_PATH% //Nologo //B //E:vbs DetermineFileVersion.vbs %WDDEFS_FILENAME% WDDEFS_VER_TARGET
if not exist "%TEMP%\SetFileVersion.cmd" goto SkipWDInst
call "%TEMP%\SetFileVersion.cmd"
del "%TEMP%\SetFileVersion.cmd"
if %WDDEFS_VER_MAJOR% LSS %WDDEFS_VER_TARGET_MAJOR% goto InstallWDDefs
if %WDDEFS_VER_MAJOR% GTR %WDDEFS_VER_TARGET_MAJOR% goto SkipWDInst
if %WDDEFS_VER_MINOR% LSS %WDDEFS_VER_TARGET_MINOR% goto InstallWDDefs
if %WDDEFS_VER_MINOR% GTR %WDDEFS_VER_TARGET_MINOR% goto SkipWDInst
if %WDDEFS_VER_BUILD% LSS %WDDEFS_VER_TARGET_BUILD% goto InstallWDDefs
if %WDDEFS_VER_BUILD% GTR %WDDEFS_VER_TARGET_BUILD% goto SkipWDInst
if %WDDEFS_VER_REVIS% GEQ %WDDEFS_VER_TARGET_REVIS% goto SkipWDInst
:InstallWDDefs
echo Installing Windows Defender definition file...
call InstallOSUpdate.cmd "%WDDEFS_FILENAME%" %VERIFY_MODE% /ignoreerrors -q
set ERR_LEVEL=%errorlevel%
rem echo DoUpdate: ERR_LEVEL=%ERR_LEVEL%
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
)
set WDDEFS_FILENAME=
:SkipWDInst
set WDDEFS_VER_TARGET_MAJOR=
set WDDEFS_VER_TARGET_MINOR=
set WDDEFS_VER_TARGET_BUILD=
set WDDEFS_VER_TARGET_REVIS=

:JustOffice
if not "%OFC_INSTALLED%"=="1" goto SkipOffice
rem *** Check Office Service Pack versions ***
echo Checking Office Service Pack versions...
if exist "%TEMP%\MissingUpdateIds.txt" del "%TEMP%\MissingUpdateIds.txt"
if "%O2K13_VER_MAJOR%"=="" goto SkipSPo2k13
if %O2K13_SP_VER% LSS %O2K13_SP_VER_TARGET% echo %O2K13_SP_TARGET_ID%>>"%TEMP%\MissingUpdateIds.txt"
:SkipSPo2k13
if "%O2K16_VER_MAJOR%"=="" goto SkipSPo2k16
if %O2K16_SP_VER% LSS %O2K16_SP_VER_TARGET% echo %O2K16_SP_TARGET_ID%>>"%TEMP%\MissingUpdateIds.txt"
:SkipSPo2k16
if not exist "%TEMP%\MissingUpdateIds.txt" goto SkipSPOfc
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if exist "%TEMP%\UpdatesToInstall.txt" (
  echo Installing most recent Office Service Pack^(s^)...
  call InstallListedUpdates.cmd %VERIFY_MODE% %DISM_MODE% /errorsaswarnings
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
) else (
  echo Warning: Office Service Pack installation file^(s^) not found.
  call :Log "Warning: Office Service Pack installation file(s) not found"
  goto SkipSPOfc
)
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
) else if "%ERR_LEVEL%" NEQ "0" (
  goto InstError
)
rem FIXME 11.9.8 (b69)
set RECALL_REQUIRED=1
:SkipSPOfc
:SkipOffice

rem *** Install MSI packages and custom software ***
if exist %SystemRoot%\Temp\wouselmsi.txt (
  echo Installing selected MSI packages...
  call TouchMSITree.cmd /instselected
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
  call :Log "Info: Installed selected MSI packages"
  del %SystemRoot%\Temp\wouselmsi.txt
  rem set REBOOT_REQUIRED=1
) else (
  if "%INSTALL_MSI%"=="/instmsi" (
    echo Installing all MSI packages...
    call TouchMSITree.cmd /install
    set ERR_LEVEL=!errorlevel!
    rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
    call :Log "Info: Installed all MSI packages"
    rem set REBOOT_REQUIRED=1
  )
)
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
)
if exist ..\software\custom\InstallCustomSoftware.cmd (
  echo Installing custom software...
  pushd ..\software\custom
  call InstallCustomSoftware.cmd
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
  popd
  call :Log "Info: Executed custom software installation hook (Errorlevel: %errorlevel%)"
  set REBOOT_REQUIRED=1
)
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
)
goto UpdateSystem

:EnableWUSvc
if "%WUSVC_ENABLED%"=="1" goto :eof
for /F "tokens=3" %%i in ('%REG_PATH% QUERY HKLM\SYSTEM\CurrentControlSet\services\wuauserv /v Start 2^>nul ^| %SystemRoot%\System32\find.exe /I "Start"') do set WUSVC_STVAL=%%i
for /F "tokens=3" %%i in ('%REG_PATH% QUERY HKLM\SYSTEM\CurrentControlSet\services\wuauserv /v DelayedAutoStart 2^>nul ^| %SystemRoot%\System32\find.exe /I "DelayedAutoStart"') do set WUSVC_STDEL=%%i
if /i "%WU_START_MODE%"=="Disabled" (
  echo Enabling service 'Windows Update' ^(wuauserv^) - previous state will be recovered later...
  call :Log "Info: Enabling service 'Windows Update' (wuauserv)"
  %SC_PATH% config wuauserv start= demand >nul 2>&1
  if errorlevel 1 (
    echo Warning: Enabling of service 'Windows Update' ^(wuauserv^) failed.
    call :Log "Warning: Enabling of service 'Windows Update' (wuauserv) failed"
  ) else (
    call :Log "Info: Enabled service 'Windows Update' (wuauserv)"
    set WUSVC_ENABLED=1
    if "%WUSVC_STVAL%" NEQ "" (
      %REG_PATH% ADD HKLM\SYSTEM\CurrentControlSet\services\wuauserv /v Start /t REG_DWORD /d %WUSVC_STVAL% /f >nul 2>&1
    )
    if "%WUSVC_STDEL%" NEQ "" (
      %REG_PATH% ADD HKLM\SYSTEM\CurrentControlSet\services\wuauserv /v DelayedAutoStart /t REG_DWORD /d %WUSVC_STDEL% /f >nul 2>&1
    )
  )
)
set WUSVC_STVAL=
set WUSVC_STDEL=
goto :eof

:WaitService
echo Waiting for service '%1' to reach state '%2' (timeout: %3s)...
call :Log "Info: Waiting for service '%1' to reach state '%2' (timeout: %3s)"
echo WScript.Sleep(2000)>"%TEMP%\Sleep2Seconds.vbs"
for /L %%i in (2,2,%3) do (
  for /F %%j in ('%CSCRIPT_PATH% //Nologo //E:vbs DetermineServiceState.vbs %1') do (
    if /i "%%j"=="%2" (
      call :Log "Info: Service '%1' reached state '%2'"
      del "%TEMP%\Sleep2Seconds.vbs"
      goto :eof
    )
  )
  %CSCRIPT_PATH% //Nologo //B //E:vbs "%TEMP%\Sleep2Seconds.vbs"
)
echo Warning: Service '%1' did not reach state '%2' in time
call :Log "Warning: Service '%1' did not reach state '%2' in time"
del "%TEMP%\Sleep2Seconds.vbs"
verify other 2>nul
goto :eof

:StopWUSvc
for /F %%i in ('%CSCRIPT_PATH% //Nologo //E:vbs DetermineServiceState.vbs wuauserv') do (
  if /i "%%i"=="Stopped" goto :eof
)
echo Stopping service 'Windows Update' (wuauserv)...
call :Log "Info: Stopping service 'Windows Update' (wuauserv)"
%SC_PATH% stop wuauserv >nul 2>&1
if errorlevel 1 (
  echo Warning: Stopping of service 'Windows Update' ^(wuauserv^) failed.
  call :Log "Warning: Stopping of service 'Windows Update' (wuauserv) failed"
) else (
  call :WaitService wuauserv Stopped 180
  if not errorlevel 1 call :Log "Info: Stopped service 'Windows Update' (wuauserv)"
)
goto :eof

:StartWUSvc
for /F %%i in ('%CSCRIPT_PATH% //Nologo //E:vbs DetermineServiceState.vbs wuauserv') do (
  if /i "%%i"=="Running" goto :eof
)
echo Starting service 'Windows Update' (wuauserv)...
call :Log "Info: Starting service 'Windows Update' (wuauserv)"
%SC_PATH% start wuauserv >nul 2>&1
if errorlevel 1 (
  echo Warning: Starting of service 'Windows Update' ^(wuauserv^) failed.
  call :Log "Warning: Starting of service 'Windows Update' (wuauserv) failed"
) else (
  call :WaitService wuauserv Running 60
  if not errorlevel 1 call :Log "Info: Started service 'Windows Update' (wuauserv)"
)
goto :eof

:AdjustWUSvc
for /F "tokens=3" %%i in ('%REG_PATH% QUERY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions 2^>nul ^| %SystemRoot%\System32\find.exe /I "AUOptions"') do set WUPOL_AUOP=%%i
for /F "tokens=3" %%i in ('%REG_PATH% QUERY HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoRebootWithLoggedOnUsers 2^>nul ^| %SystemRoot%\System32\find.exe /I "NoAutoRebootWithLoggedOnUsers"') do set WUPOL_NOAR=%%i
for /F "tokens=3" %%i in ('%REG_PATH% QUERY HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoUpdate 2^>nul ^| %SystemRoot%\System32\find.exe /I "NoAutoUpdate"') do set WUPOL_NOAU=%%i
if "%WUPOL_AUOP%" NEQ "" (
  %REG_PATH% ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 1 /f >nul 2>&1
)
if "%WUPOL_NOAR%" NEQ "" (
  %REG_PATH% ADD HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d 1 /f >nul 2>&1
)
if "%WUPOL_NOAU%" NEQ "" (
  %REG_PATH% ADD HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul 2>&1
)
call :StopWUSvc
call :StartWUSvc
if "%WUPOL_AUOP%" NEQ "" (
  %REG_PATH% ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d %WUPOL_AUOP% /f >nul 2>&1
)
if "%WUPOL_NOAR%" NEQ "" (
  %REG_PATH% ADD HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d %WUPOL_NOAR% /f >nul 2>&1
)
if "%WUPOL_NOAU%" NEQ "" (
  %REG_PATH% ADD HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoUpdate /t REG_DWORD /d %WUPOL_NOAU% /f >nul 2>&1
)
set WUPOL_AUOP=
set WUPOL_NOAR=
set WUPOL_NOAU=
goto :eof

:UpdateSystem
rem *** Determine and install missing Microsoft updates ***
if exist %SystemRoot%\Temp\WOUpdatesToInstall.txt (
  for %%i in ("%SystemRoot%\Temp\WOUpdatesToInstall.txt") do if %%~zi==0 del %%i
  if exist %SystemRoot%\Temp\WOUpdatesToInstall.txt (
    move /Y %SystemRoot%\Temp\WOUpdatesToInstall.txt "%TEMP%\UpdatesToInstall.txt" >nul 2>&1
  )
  goto InstallUpdates
)
if "%SKIP_DYNAMIC%"=="/skipdynamic" (
  echo Skipping determination of missing updates on demand...
  call :Log "Info: Skipped determination of missing updates on demand"
  goto ListInstalledIds
)
if exist %SystemRoot%\Temp\wou_wupre_tried.txt goto ListMissingIds
echo Checking Windows Update scan prerequisites...
%CSCRIPT_PATH% //Nologo //B //E:vbs ListInstalledUpdateIds.vbs
set SHA2_PREREQ_INSTALLING=0
if exist "%TEMP%\MissingUpdateIds.txt" del "%TEMP%\MissingUpdateIds.txt"
if exist ..\static\StaticUpdateIds-wupre-%OS_NAME%.txt (
  for /F "tokens=1* delims=kbKB,;" %%i in (..\static\StaticUpdateIds-wupre-%OS_NAME%.txt) do (
    if exist "%TEMP%\InstalledUpdateIds.txt" (
      %SystemRoot%\System32\find.exe /I "%%i" "%TEMP%\InstalledUpdateIds.txt" >nul 2>&1
      if errorlevel 1 echo %%i>>"%TEMP%\MissingUpdateIds.txt"
      if not "%SHA2_PREREQ_ID%"=="" (if "%%i"=="%SHA2_PREREQ_ID%" (set SHA2_PREREQ_INSTALLING=1))
    ) else (
      echo %%i>>"%TEMP%\MissingUpdateIds.txt"
    )
  )
)
if "%OS_SHA2_SUPPORT%"=="1" (
  if exist ..\static\StaticUpdateIds-wupre-%OS_NAME%-sha2.txt (
    for /F "tokens=1* delims=kbKB,;" %%i in (..\static\StaticUpdateIds-wupre-%OS_NAME%-sha2.txt) do (
      if exist "%TEMP%\InstalledUpdateIds.txt" (
        %SystemRoot%\System32\find.exe /I "%%i" "%TEMP%\InstalledUpdateIds.txt" >nul 2>&1
        if errorlevel 1 echo %%i>>"%TEMP%\MissingUpdateIds.txt"
      ) else (
        echo %%i>>"%TEMP%\MissingUpdateIds.txt"
      )
    )
  )
)
if exist ..\static\StaticUpdateIds-wupre-%OS_NAME%-%OS_VER_BUILD%.txt (
  for /F "tokens=1* delims=kbKB,;" %%i in (..\static\StaticUpdateIds-wupre-%OS_NAME%-%OS_VER_BUILD%.txt) do (
    if exist "%TEMP%\InstalledUpdateIds.txt" (
      %SystemRoot%\System32\find.exe /I "%%i" "%TEMP%\InstalledUpdateIds.txt" >nul 2>&1
      if errorlevel 1 echo %%i>>"%TEMP%\MissingUpdateIds.txt"
      if not "%SHA2_PREREQ_ID%"=="" (if "%%i"=="%SHA2_PREREQ_ID%" (set SHA2_PREREQ_INSTALLING=1))
    ) else (
      echo %%i>>"%TEMP%\MissingUpdateIds.txt"
    )
  )
)
if "%OS_SHA2_SUPPORT%"=="1" (
  if exist ..\static\StaticUpdateIds-wupre-%OS_NAME%-%OS_VER_BUILD%-sha2.txt (
    for /F "tokens=1* delims=kbKB,;" %%i in (..\static\StaticUpdateIds-wupre-%OS_NAME%-%OS_VER_BUILD%-sha2.txt) do (
      if exist "%TEMP%\InstalledUpdateIds.txt" (
        %SystemRoot%\System32\find.exe /I "%%i" "%TEMP%\InstalledUpdateIds.txt" >nul 2>&1
        if errorlevel 1 echo %%i>>"%TEMP%\MissingUpdateIds.txt"
      ) else (
        echo %%i>>"%TEMP%\MissingUpdateIds.txt"
      )
    )
  )
)
call :Log "Info: Checked Windows Update scan prerequisites"
call ListUpdatesToInstall.cmd /excludestatics /ignoreblacklist
if errorlevel 1 goto ListError
if exist "%TEMP%\UpdatesToInstall.txt" (
  echo Adjusting service 'Windows Update'...
  call :EnableWUSvc
  call :AdjustWUSvc
  echo Installing Windows Update scan prerequisites...
  call InstallListedUpdates.cmd /selectoptions %VERIFY_MODE% %DISM_MODE% /ignoreerrors
  set ERR_LEVEL=!errorlevel!
  rem echo DoUpdate: ERR_LEVEL=!ERR_LEVEL!
  if "!ERR_LEVEL!"=="3010" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_wupre_tried.txt
    set REBOOT_REQUIRED=1
  ) else if "!ERR_LEVEL!"=="3011" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_wupre_tried.txt
    set RECALL_REQUIRED=1
  ) else if "!ERR_LEVEL!" GEQ "0" (
    if not exist %SystemRoot%\Temp\nul md %SystemRoot%\Temp
    echo. >%SystemRoot%\Temp\wou_wupre_tried.txt
    rem FIXME 11.9.8 (b69)
    set RECALL_REQUIRED=1
  )
  call :Log "Info: Installed Windows Update scan prerequisites"
)
if "%RECALL_REQUIRED%"=="1" goto Installed
if "%REBOOT_REQUIRED%"=="1" goto Installed

:ListMissingIds
rem *** Adjust service 'Windows Update' ***
echo Adjusting service 'Windows Update'...
call :EnableWUSvc
call :AdjustWUSvc
set WUSVC_STARTED=1
rem *** List ids of missing updates ***
if not exist ..\wsus\wsusscn2.cab goto NoCatalog
if "%VERIFY_MODE%" NEQ "/verify" goto SkipVerifyCatalog
if not exist %HASHDEEP_PATH% (
  echo Warning: Hash computing/auditing utility %HASHDEEP_PATH% not found.
  call :Log "Warning: Hash computing/auditing utility %HASHDEEP_PATH% not found"
  goto SkipVerifyCatalog
)
if not exist ..\md\hashes-wsus.txt (
  echo Warning: Hash file hashes-wsus.txt not found.
  call :Log "Warning: Hash file hashes-wsus.txt not found"
  goto SkipVerifyCatalog
)
echo Verifying integrity of Windows Update catalog file...
%SystemRoot%\System32\findstr.exe /L /I /C:%% /C:wsusscn2.cab ..\md\hashes-wsus.txt >"%TEMP%\hash-wsusscn2.txt"
%HASHDEEP_PATH% -a -b -k "%TEMP%\hash-wsusscn2.txt" ..\wsus\wsusscn2.cab
if errorlevel 1 (
  if exist "%TEMP%\hash-wsusscn2.txt" del "%TEMP%\hash-wsusscn2.txt"
  goto CatalogIntegrityError
)
if exist "%TEMP%\hash-wsusscn2.txt" del "%TEMP%\hash-wsusscn2.txt"
:SkipVerifyCatalog
if "%OS_SHA2_SUPPORT%" NEQ "1" (
  echo Warning: Support for SHA2 signed updates is missing. Updates might fail to install.
  call :Log "Warning: Support for SHA2 signed updates is missing"
)
if "%WUA_SHA2_SUPPORT%" NEQ "1" (
  echo Warning: Support for a SHA2 signed catalog file is missing. Missing updates might not be found.
  call :Log "Warning: Support for a SHA2 signed catalog file is missing"
)
echo %TIME% - Listing ids of missing updates (please be patient, this will take a while)...
copy /Y ..\wsus\wsusscn2.cab "%TEMP%" >nul
%CSCRIPT_PATH% //Nologo //E:vbs ListMissingUpdateIds.vbs %LIST_MODE_IDS%
if exist "%TEMP%\wsusscn2.cab" del "%TEMP%\wsusscn2.cab"
echo %TIME% - Done.
call :Log "Info: Listed ids of missing updates"
if not exist "%TEMP%\MissingUpdateIds.txt" set NO_MISSING_IDS=1

:ListInstalledIds
rem *** List ids of installed updates ***
if "%LIST_MODE_IDS%"=="/all" goto ListInstFiles
if "%LIST_MODE_UPDATES%"=="/excludestatics" goto ListInstFiles
echo Listing ids of installed updates...
%CSCRIPT_PATH% //Nologo //B //E:vbs ListInstalledUpdateIds.vbs
call :Log "Info: Listed ids of installed updates"

:ListInstFiles
rem *** List update files ***
echo Listing update files...
call ListUpdatesToInstall.cmd %LIST_MODE_IDS% %LIST_MODE_UPDATES%
if errorlevel 1 goto ListError
call :Log "Info: Listed update files"

:InstallUpdates
rem *** Install updates ***
if not exist "%TEMP%\UpdatesToInstall.txt" goto SkipUpdates
call :StopWUSvc
set WUSVC_STOPPED=1
echo Installing updates...
call InstallListedUpdates.cmd /selectoptions %VERIFY_MODE% %DISM_MODE% /errorsaswarnings
set ERR_LEVEL=%errorlevel%
rem echo DoUpdate: ERR_LEVEL=%ERR_LEVEL%
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
) else if "%ERR_LEVEL%" NEQ "0" (
  goto InstError
)
if "%USERNAME%"=="WOUTempAdmin" (
  if "%FINISH_MODE%"=="/shutdown" (
    if not exist %SystemRoot%\Temp\WOUpdatesToInstall.txt echo.>nul 2>%SystemRoot%\Temp\WOUpdatesToInstall.txt
  )
)
if exist %SystemRoot%\Temp\WOUpdatesToInstall.txt (set RECALL_REQUIRED=1) else (set REBOOT_REQUIRED=1)
if "%RECALL_REQUIRED%"=="1" goto Installed
:SkipUpdates

rem *** Install Microsoft Security Essentials ***
if "%OS_NAME%"=="w62" goto SkipMSSEInst
if "%OS_NAME%"=="w63" goto SkipMSSEInst
if "%OS_NAME%"=="w100" goto SkipMSSEInst
echo Checking Microsoft Security Essentials installation state...
if "%INSTALL_MSSE%" NEQ "/instmsse" (
  if "%MSSE_INSTALLED%"=="1" (goto CheckMSSEDefs) else (goto SkipMSSEInst)
)
if %OS_DOMAIN_ROLE% GEQ 2 (
  if "%MSSE_INSTALLED%"=="1" (goto CheckMSSEDefs) else (goto SkipMSSEInst)
)
set MSSE_FILENAME=..\msse\%OS_ARCH%-glb\MSEInstall-%OS_ARCH%-%OS_LANG%.exe
if not exist %MSSE_FILENAME% (
  echo Warning: Microsoft Security Essentials installation file ^(%MSSE_FILENAME%^) not found.
  call :Log "Warning: Microsoft Security Essentials installation file (%MSSE_FILENAME%) not found"
  if "%MSSE_INSTALLED%"=="1" (goto CheckMSSEDefs) else (goto SkipMSSEInst)
)
rem *** Determine Microsoft Security Essentials installation file version ***
echo Determining Microsoft Security Essentials installation file version...
%CSCRIPT_PATH% //Nologo //B //E:vbs DetermineFileVersion.vbs %MSSE_FILENAME% MSSE_VER_TARGET
if not exist "%TEMP%\SetFileVersion.cmd" goto CheckMSSEDefs
call "%TEMP%\SetFileVersion.cmd"
del "%TEMP%\SetFileVersion.cmd"
if %MSSE_VER_MAJOR% LSS %MSSE_VER_TARGET_MAJOR% goto InstallMSSE
if %MSSE_VER_MAJOR% GTR %MSSE_VER_TARGET_MAJOR% goto CheckMSSEDefs
if %MSSE_VER_MINOR% LSS %MSSE_VER_TARGET_MINOR% goto InstallMSSE
if %MSSE_VER_MINOR% GTR %MSSE_VER_TARGET_MINOR% goto CheckMSSEDefs
if %MSSE_VER_BUILD% LSS %MSSE_VER_TARGET_BUILD% goto InstallMSSE
if %MSSE_VER_BUILD% GTR %MSSE_VER_TARGET_BUILD% goto CheckMSSEDefs
if %MSSE_VER_REVIS% GEQ %MSSE_VER_TARGET_REVIS% goto CheckMSSEDefs
:InstallMSSE
echo Installing Microsoft Security Essentials...
call InstallOSUpdate.cmd "%MSSE_FILENAME%" %VERIFY_MODE% /ignoreerrors /s /runwgacheck /o
set ERR_LEVEL=%errorlevel%
rem echo DoUpdate: ERR_LEVEL=%ERR_LEVEL%
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
)
set MSSE_FILENAME=
rem FIXME 11.9.8 (b69)
set REBOOT_REQUIRED=1
:CheckMSSEDefs
if "%SKIP_DEFS%"=="/skipdefs" goto SkipMSSEInst
set MSSE_VER_TARGET_MAJOR=
set MSSE_VER_TARGET_MINOR=
set MSSE_VER_TARGET_BUILD=
set MSSE_VER_TARGET_REVIS=
set MSSEDEFS_FILENAME=..\msse\%OS_ARCH%-glb\mpam-fe.exe
if not exist %MSSEDEFS_FILENAME% (
  echo Warning: Microsoft Security Essentials definition file ^(%MSSEDEFS_FILENAME%^) not found.
  call :Log "Warning: Microsoft Security Essentials definition file (%MSSEDEFS_FILENAME%) not found"
  goto CheckNISDefs
)
rem *** Determine Microsoft Security Essentials definition file version ***
echo Determining Microsoft Security Essentials definition file version...
%CSCRIPT_PATH% //Nologo //B //E:vbs DetermineFileVersion.vbs %MSSEDEFS_FILENAME% MSSEDEFS_VER_TARGET
if not exist "%TEMP%\SetFileVersion.cmd" goto CheckNISDefs
call "%TEMP%\SetFileVersion.cmd"
del "%TEMP%\SetFileVersion.cmd"
if %MSSEDEFS_VER_MAJOR% LSS %MSSEDEFS_VER_TARGET_MAJOR% goto InstallMSSEDefs
if %MSSEDEFS_VER_MAJOR% GTR %MSSEDEFS_VER_TARGET_MAJOR% goto CheckNISDefs
if %MSSEDEFS_VER_MINOR% LSS %MSSEDEFS_VER_TARGET_MINOR% goto InstallMSSEDefs
if %MSSEDEFS_VER_MINOR% GTR %MSSEDEFS_VER_TARGET_MINOR% goto CheckNISDefs
if %MSSEDEFS_VER_BUILD% LSS %MSSEDEFS_VER_TARGET_BUILD% goto InstallMSSEDefs
if %MSSEDEFS_VER_BUILD% GTR %MSSEDEFS_VER_TARGET_BUILD% goto CheckNISDefs
if %MSSEDEFS_VER_REVIS% GEQ %MSSEDEFS_VER_TARGET_REVIS% goto CheckNISDefs
:InstallMSSEDefs
echo Installing Microsoft Security Essentials definition file...
call InstallOSUpdate.cmd "%MSSEDEFS_FILENAME%" %VERIFY_MODE% /ignoreerrors -q
set ERR_LEVEL=%errorlevel%
rem echo DoUpdate: ERR_LEVEL=%ERR_LEVEL%
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
)
set MSSEDEFS_FILENAME=
:CheckNISDefs
set MSSEDEFS_VER_TARGET_MAJOR=
set MSSEDEFS_VER_TARGET_MINOR=
set MSSEDEFS_VER_TARGET_BUILD=
set MSSEDEFS_VER_TARGET_REVIS=
set NISDEFS_FILENAME=..\msse\%OS_ARCH%-glb\nis_full_%OS_ARCH%.exe
if not exist %NISDEFS_FILENAME% (
  echo Warning: Network Inspection System definition file ^(%NISDEFS_FILENAME%^) not found.
  call :Log "Warning: Network Inspection System definition file (%NISDEFS_FILENAME%) not found"
  goto SkipMSSEInst
)
rem *** Determine Network Inspection System definition file version ***
echo Determining Network Inspection System definition file version...
%CSCRIPT_PATH% //Nologo //B //E:vbs DetermineFileVersion.vbs %NISDEFS_FILENAME% NISDEFS_VER_TARGET
if not exist "%TEMP%\SetFileVersion.cmd" goto SkipMSSEInst
call "%TEMP%\SetFileVersion.cmd"
del "%TEMP%\SetFileVersion.cmd"
if %NISDEFS_VER_MAJOR% LSS %NISDEFS_VER_TARGET_MAJOR% goto InstallNISDefs
if %NISDEFS_VER_MAJOR% GTR %NISDEFS_VER_TARGET_MAJOR% goto SkipMSSEInst
if %NISDEFS_VER_MINOR% LSS %NISDEFS_VER_TARGET_MINOR% goto InstallNISDefs
if %NISDEFS_VER_MINOR% GTR %NISDEFS_VER_TARGET_MINOR% goto SkipMSSEInst
if %NISDEFS_VER_BUILD% LSS %NISDEFS_VER_TARGET_BUILD% goto InstallNISDefs
if %NISDEFS_VER_BUILD% GTR %NISDEFS_VER_TARGET_BUILD% goto SkipMSSEInst
if %NISDEFS_VER_REVIS% GEQ %NISDEFS_VER_TARGET_REVIS% goto SkipMSSEInst
:InstallNISDefs
echo Installing Network Inspection System definition file...
call InstallOSUpdate.cmd "%NISDEFS_FILENAME%" %VERIFY_MODE% /ignoreerrors
set ERR_LEVEL=%errorlevel%
rem echo DoUpdate: ERR_LEVEL=%ERR_LEVEL%
if "%ERR_LEVEL%"=="3010" (
  set REBOOT_REQUIRED=1
) else if "%ERR_LEVEL%"=="3011" (
  set RECALL_REQUIRED=1
)
set NISDEFS_FILENAME=
:SkipMSSEInst
set NISDEFS_VER_TARGET_MAJOR=
set NISDEFS_VER_TARGET_MINOR=
set NISDEFS_VER_TARGET_BUILD=
set NISDEFS_VER_TARGET_REVIS=

if "%RECALL_REQUIRED%"=="1" goto Installed
if "%REBOOT_REQUIRED%"=="1" goto Installed
goto NoUpdates

:FinalHooks
rem *** Execute custom finalization hook ***
if exist .\custom\FinalizationHook.cmd (
  echo Executing custom finalization hook...
  pushd .\custom
  call FinalizationHook.cmd
  popd
  call :Log "Info: Executed custom finalization hook (Errorlevel: %errorlevel%)"
)
if "%RECALL_REQUIRED%" NEQ "1" (
  if exist .\custom\FinalizationHookFinal.cmd (
    echo Executing final custom finalization hook...
    pushd .\custom
    call FinalizationHookFinal.cmd
    popd
    call :Log "Info: Executed final custom finalization hook (Errorlevel: %errorlevel%)"
  )
)
goto :eof

:RebootOrShutdown
if "%SHOW_LOG%"=="/showlog" call PrepareShowLogFile.cmd
if "%FINISH_MODE%"=="/shutdown" (
  echo Shutting down...
  %SystemRoot%\System32\shutdown.exe /s /f /t 3
  goto :eof
)
if "%BOOT_MODE%"=="/autoreboot" (
  if exist %SystemRoot%\System32\bcdedit.exe (
    echo Adjusting boot sequence for next reboot...
    %SystemRoot%\System32\bcdedit.exe /bootsequence {current}
    call :Log "Info: Adjusted boot sequence for next reboot"
  )
  echo Rebooting...
  %SystemRoot%\System32\shutdown.exe /r /f /t 3
)
goto :eof

:RestoreWUSvc
if "%WUSVC_STOPPED%"=="1" (
  if "%WUSVC_STARTED%" NEQ "1" call :StartWUSvc
)
goto :eof

:CleanupPwrCfg
if "%CUPOL_SSA%" NEQ "" (
  echo Restoring screensaver setting...
  %REG_PATH% ADD "HKCU\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d %CUPOL_SSA% /f >nul 2>&1
  call :Log "Info: Restored screensaver setting"
)
if exist %SystemRoot%\woubak-pwrscheme-act.txt (
  echo Activating previous power scheme...
  for /F %%i in (%SystemRoot%\woubak-pwrscheme-act.txt) do %SystemRoot%\System32\powercfg.exe -setactive %%i
  if errorlevel 1 (
    echo Warning: Activation of previous power scheme failed.
    call :Log "Warning: Activation of previous power scheme failed"
  ) else (
    del %SystemRoot%\woubak-pwrscheme-act.txt
    call :Log "Info: Activated previous power scheme"
  )
)
if exist %SystemRoot%\woubak-pwrscheme-temp.txt (
  echo Deleting temporary power scheme...
  for /F %%i in (%SystemRoot%\woubak-pwrscheme-temp.txt) do %SystemRoot%\System32\powercfg.exe -delete %%i
  if errorlevel 1 (
    echo Warning: Deletion of temporary power scheme failed.
    call :Log "Warning: Deletion of temporary power scheme failed"
  ) else (
    del %SystemRoot%\woubak-pwrscheme-temp.txt
    call :Log "Info: Deleted temporary power scheme"
  )
)
goto :eof

:Cleanup
if exist %SystemRoot%\Temp\wou_w63upd1_tried.txt del %SystemRoot%\Temp\wou_w63upd1_tried.txt
if exist %SystemRoot%\Temp\wou_w63upd2_tried.txt del %SystemRoot%\Temp\wou_w63upd2_tried.txt
if exist %SystemRoot%\Temp\wou_wua_tried.txt del %SystemRoot%\Temp\wou_wua_tried.txt
if exist %SystemRoot%\Temp\wou_iepre_tried.txt del %SystemRoot%\Temp\wou_iepre_tried.txt
if exist %SystemRoot%\Temp\wou_ie_tried.txt del %SystemRoot%\Temp\wou_ie_tried.txt
if exist %SystemRoot%\Temp\wou_net35_tried.txt del %SystemRoot%\Temp\wou_net35_tried.txt
if exist %SystemRoot%\Temp\wou_net4_tried.txt del %SystemRoot%\Temp\wou_net4_tried.txt
if exist %SystemRoot%\Temp\wou_wmf_tried.txt del %SystemRoot%\Temp\wou_wmf_tried.txt
if exist %SystemRoot%\Temp\wou_cpp_tried.txt del %SystemRoot%\Temp\wou_cpp_tried.txt
if exist %SystemRoot%\Temp\wou_wupre_tried.txt del %SystemRoot%\Temp\wou_wupre_tried.txt
if exist "%TEMP%\UpdateInstaller.ini" del "%TEMP%\UpdateInstaller.ini"
call :CleanupPwrCfg
if "%USERNAME%"=="WOUTempAdmin" (
  echo Cleaning up automatic recall...
  call CleanupRecall.cmd
  call :FinalHooks
  call :RebootOrShutdown
)
if "%BOOT_MODE%"=="/autoreboot" goto :eof
if "%FINISH_MODE%"=="/shutdown" goto :eof
if "%SHOW_LOG%"=="/showlog" start %SystemRoot%\System32\notepad.exe %UPDATE_LOGFILE%
goto :eof

:Installed
if "%RECALL_REQUIRED%"=="1" (
  if "%BOOT_MODE%"=="/autoreboot" (
    if "%OS_NAME%"=="w100" (
      echo.
      echo Automatic recall is not supported on Windows 10 systems.
      call :Log "Info: Automatic recall is not supported on Windows 10 systems"
      goto ManualRecall
    )
    if %OS_DOMAIN_ROLE% GEQ 4 (
      echo.
      echo Automatic recall is not supported on domain controllers.
      call :Log "Info: Automatic recall is not supported on domain controllers"
      goto ManualRecall
    )
    if not exist ..\bin\Autologon.exe (
      echo.
      echo Warning: Utility ..\bin\Autologon.exe not found. Automatic recall is unavailable.
      call :Log "Warning: Utility ..\bin\Autologon.exe not found. Automatic recall is unavailable"
      goto ManualRecall
    )
    if "%USERNAME%" NEQ "WOUTempAdmin" (
      echo Preparing automatic recall...
      call PrepareRecall.cmd "%~f0" %UPDATE_RCERTS% %INSTALL_DOTNET35% %INSTALL_DOTNET4% %INSTALL_WMF% %UPDATE_CPP% %INSTALL_MSSE% %UPDATE_TSC% %SKIP_IEINST% %SKIP_DEFS% %SKIP_DYNAMIC% %LIST_MODE_IDS% %LIST_MODE_UPDATES% %VERIFY_MODE% %BOOT_MODE% %FINISH_MODE% %SHOW_LOG% %DISM_MODE% %MONITOR_ON% %INSTALL_MSI%
    )
    if exist %SystemRoot%\System32\bcdedit.exe (
      echo Adjusting boot sequence for next reboot...
      %SystemRoot%\System32\bcdedit.exe /bootsequence {current}
      call :Log "Info: Adjusted boot sequence for next reboot"
    )
    echo Rebooting...
    call :FinalHooks
    %SystemRoot%\System32\shutdown.exe /r /f /t 3
    goto EoF
  ) else goto ManualRecall
) else (
  call :Cleanup
  if "%USERNAME%" NEQ "WOUTempAdmin" (
    call :FinalHooks
    if "%BOOT_MODE%"=="/autoreboot" (
      call :RebootOrShutdown
      goto EoF
    )
    if "%FINISH_MODE%"=="/shutdown" (
      call :RebootOrShutdown
      goto EoF
    )
    call :RestoreWUSvc
    echo.
    echo Installation successful. Please reboot your system now.
    call :Log "Info: Installation successful"
    echo.
    echo 
  )
)
goto EoF

:ManualRecall
call :CleanupPwrCfg
call :RestoreWUSvc
echo.
echo Installation successful. Please reboot your system now and recall Update afterwards.
call :Log "Info: Installation successful (Updates pending)"
echo.
echo 
call :FinalHooks
goto EoF

:NoExtensions
echo.
echo ERROR: No command extensions available.
echo.
exit /b 1

:NoTemp
echo.
echo ERROR: Environment variable TEMP not set.
call :Log "Error: Environment variable TEMP not set"
echo.
goto Error

:NoTempDir
echo.
echo ERROR: Directory "%TEMP%" not found.
call :Log "Error: Directory "%TEMP%" not found"
echo.
goto Error

:NoCScript
echo.
echo ERROR: VBScript interpreter %CSCRIPT_PATH% not found.
call :Log "Error: VBScript interpreter %CSCRIPT_PATH% not found"
echo.
goto Error

:NoReg
echo.
echo ERROR: Registry tool %REG_PATH% not found.
call :Log "Error: Registry tool %REG_PATH% not found"
echo.
goto Error

:NoSc
echo.
echo ERROR: Service control utility %SC_PATH% not found.
call :Log "Error: Service control utility %SC_PATH% not found"
echo.
goto Error

:EndlessLoop
echo.
echo ERROR: Potentially endless reboot/recall loop detected.
call :Log "Error: Potentially endless reboot/recall loop detected"
echo.
goto Error

:NoIfAdmin
echo.
echo ERROR: File ..\bin\IfAdmin.exe not found.
call :Log "Error: File ..\bin\IfAdmin.exe not found"
echo.
goto Error

:NoAdmin
echo.
echo ERROR: User %USERNAME% does not have administrative privileges.
call :Log "Error: User %USERNAME% does not have administrative privileges"
echo.
goto Error

:NoSysEnvVars
echo.
echo ERROR: Determination of OS properties failed.
call :Log "Error: Determination of OS properties failed"
echo.
goto Error

:UnsupOS
echo.
echo ERROR: Unsupported Operating System (%OS_NAME% %OS_ARCH%).
call :Log "Error: Unsupported Operating System (%OS_NAME% %OS_ARCH%)"
echo.
goto Error

:UnsupArch
echo.
echo ERROR: Unsupported Operating System architecture (%OS_ARCH%).
call :Log "Error: Unsupported Operating System architecture (%OS_ARCH%)"
echo.
goto Error

:UnsupLang
echo.
echo ERROR: Unsupported Operating System language.
call :Log "Error: Unsupported Operating System language"
echo.
goto Error

:InvalidMedium
echo.
echo ERROR: Medium neither supports your Windows nor your Office version.
call :Log "Error: Medium neither supports your Windows nor your Office version"
echo.
goto Error

:NoSPTargetId
echo.
echo ERROR: Environment variable OS_SP_TARGET_ID not set.
call :Log "Error: Environment variable OS_SP_TARGET_ID not set"
echo.
goto Error

:NoCatalog
echo.
echo ERROR: File ..\wsus\wsusscn2.cab not found.
call :Log "Error: File ..\wsus\wsusscn2.cab not found"
echo.
goto Error

:CatalogIntegrityError
echo.
echo ERROR: File hash does not match stored value (file: ..\wsus\wsusscn2.cab).
call :Log "Error: File hash does not match stored value (file: ..\wsus\wsusscn2.cab)"
echo.
goto Error

:NoUpdates
echo.
if "%NO_MISSING_IDS%"=="1" (
  echo No missing update found. Nothing to do!
  call :Log "Info: No missing update found"
) else (
  echo Any missing update was either black listed or not found. Nothing to do!
  call :Log "Info: Any missing update was either black listed or not found"
)
echo.
call :Cleanup
call :FinalHooks
if "%FINISH_MODE%"=="/shutdown" call :RebootOrShutdown
goto EoF

:ListError
echo.
echo ERROR: Listing of update files failed.
call :Log "Error: Listing of update files failed"
echo.
goto Error

:InstError
echo.
echo ERROR: Installation failed.
call :Log "Error: Installation failed"
echo.
goto Error

:Error
set ERROR_OCCURRED=1
call :Cleanup
call :FinalHooks
goto EoF

:EoF
cd ..
echo Ending WSUS Offline Update - Community Edition - at %TIME%...
call :Log "Info: Ending WSUS Offline Update - Community Edition"
title %ComSpec%
if "%RECALL_REQUIRED%"=="1" (
  verify other 2>nul
  exit /b 3011
)
if "%REBOOT_REQUIRED%"=="1" exit /b 3010
endlocal
