@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

if "%OS_RAM_GB%"=="" (
  if /i "%OS_ARCH%"=="x86" (set UPDATES_PER_STAGE=60) else (set UPDATES_PER_STAGE=40)
) else (
  if /i "%OS_ARCH%"=="x86" (set /A UPDATES_PER_STAGE=OS_RAM_GB*60) else (set /A UPDATES_PER_STAGE=OS_RAM_GB*40)
)
if exist .\custom\SetUpdatesPerStage.cmd call .\custom\SetUpdatesPerStage.cmd
if %UPDATES_PER_STAGE% LSS 40 set UPDATES_PER_STAGE=40

set IE_VER_TARGET_BUILD=0
set IE_VER_TARGET_REVIS=0

set DOTNET35_VER_TARGET_MAJOR=3
set DOTNET35_VER_TARGET_MINOR=5
set DOTNET35_VER_TARGET_BUILD=30729
set DOTNET35_VER_TARGET_REVIS=1

set DOTNET4_VER_TARGET_MAJOR=4
set DOTNET4_VER_TARGET_MINOR=8
if "%OS_VER_MAJOR%.%OS_VER_MINOR%.%OS_VER_BUILD_INTERNAL%"=="10.0.10240" (
  set DOTNET4_VER_TARGET_MINOR=6
  set DOTNET4_VER_TARGET_BUILD=01590
) else if "%OS_VER_MAJOR%.%OS_VER_MINOR%.%OS_VER_BUILD_INTERNAL%"=="10.0.18362" (
  set DOTNET4_VER_TARGET_BUILD=03752
) else if "%OS_VER_MAJOR%.%OS_VER_MINOR%.%OS_VER_BUILD_INTERNAL%"=="10.0.19041" (
  set DOTNET4_VER_TARGET_BUILD=04084
) else if "%OS_VER_MAJOR%.%OS_VER_MINOR%.%OS_VER_BUILD_INTERNAL%"=="10.0.20348" (
  set DOTNET4_VER_TARGET_BUILD=04161
) else (
  set DOTNET4_VER_TARGET_BUILD=03761
)
set DOTNET4_VER_TARGET_REVIS=0

set WMF_VER_TARGET_MAJOR=5
set WMF_VER_TARGET_MINOR=1

set TSC_VER_TARGET_BUILD=0
set TSC_VER_TARGET_REVIS=0

if %OS_VER_MAJOR% LSS 5 goto SetOfficeName
if %OS_VER_MAJOR% GTR 10 goto SetOfficeName
if %OS_VER_MINOR% GTR 3 goto SetOfficeName
goto Windows%OS_VER_MAJOR%.%OS_VER_MINOR%

:Windows5.0
rem *** Windows 2000 ***
set OS_NAME=w2k
goto SetOfficeName

:Windows5.1
rem *** Windows XP ***
set OS_NAME=wxp
goto SetOfficeName

:Windows5.2
rem *** Windows Server 2003 ***
set OS_NAME=w2k3
goto SetOfficeName

:Windows6.0
rem *** Windows Server 2008 ***
set OS_NAME=w60
goto SetOfficeName

:Windows6.1
rem *** Windows 7 / Server 2008 R2 ***
set OS_NAME=w61
goto SetOfficeName

:Windows6.2
rem *** Windows Server 2012 ***
set OS_NAME=w62
set IE_VER_TARGET_MAJOR=9
set IE_VER_TARGET_MINOR=11
set WMF_TARGET_ID=3191565
set TSC_VER_TARGET_MAJOR=6
set TSC_VER_TARGET_MINOR=2
set WOU_ENDLESS=6
goto SetOfficeName

:Windows6.3
rem *** Windows 8.1 / Server 2012 R2 ***
set OS_NAME=w63
set OS_SP_PREREQ_ID=2975061
set OS_SP_TARGET_ID=2919355
set OS_UPD1_TARGET_REVIS=17041
set OS_UPD2_TARGET_REVIS=17415
set IE_VER_TARGET_MAJOR=9
set IE_VER_TARGET_MINOR=11
set WMF_TARGET_ID=3191564
set TSC_VER_TARGET_MAJOR=6
set TSC_VER_TARGET_MINOR=3
set WOU_ENDLESS=6
goto SetOfficeName

:Windows10.0
if %OS_VER_BUILD% GEQ 21382 goto Windows11.0
rem *** Windows 10.0 / Server 2016/2019 ***
rem *** Windows Server 2022 is "fe", but behaves like Windows 10 regarding updates, so treat it as "w100" ***
set OS_NAME=w100
set IE_VER_TARGET_MAJOR=9
set IE_VER_TARGET_MINOR=11
set TSC_VER_TARGET_MAJOR=10
set TSC_VER_TARGET_MINOR=0
set WOU_ENDLESS=3
goto SetOfficeName

:Windows11.0
rem *** Windows 11 / Server xxx ***
set OS_NAME=w110
goto SetOfficeName

:SetOfficeName
set OFC_INSTALLED=0
if "%O2K13_VER_MAJOR%"=="" goto NoO2k13
rem *** Office 2013 ***
set OFC_INSTALLED=1
set O2K13_SP_VER_TARGET=1
set O2K13_SP_TARGET_ID=2817430-fullfile-%O2K13_ARCH%
:NoO2k13
if "%O2K16_VER_MAJOR%"=="" goto NoO2k16
rem *** Office 2016 ***
set OFC_INSTALLED=1
set O2K16_SP_VER_TARGET=0
:NoO2k16
goto EoF

:EoF
