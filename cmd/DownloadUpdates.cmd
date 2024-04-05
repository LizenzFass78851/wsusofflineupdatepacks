@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***
rem
rem Patched by Hartmut Buhrmester 2020-01-18
rem - new method for the determination of dynamic Office updates
rem - some files for the determination of superseded updates and dynamic
rem   Windows updates were renamed for consistency

verify other 2>nul
setlocal enableextensions enabledelayedexpansion
if errorlevel 1 goto NoExtensions

rem clear vars storing parameters
set EXC_SP=
set EXC_STATICS=
set EXC_WINGLB=
set INC_DOTNET=
set INC_MSSE=
set INC_WDDEFS=
set CLEANUP_DL=
set VERIFY_DL=
set EXIT_ERR=
set SKIP_SDD=
set SKIP_TZ=
set SKIP_DL=
set SKIP_PARAM=
set http_proxy=
set https_proxy=
set WSUS_URL=
set WSUS_ONLY=
set WSUS_BY_PROXY=

if "%DIRCMD%" NEQ "" set DIRCMD=

cd /D "%~dp0"

set WSUSOFFLINE_VERSION=11.9.11hf5
title %~n0 %1 %2 %3 %4 %5 %6 %7 %8 %9
echo Starting WSUS Offline Update - Community Edition - download v. %WSUSOFFLINE_VERSION% for %1 %2...
set DOWNLOAD_LOGFILE=..\log\download.log
goto Start

:Log
echo %DATE% %TIME% - %~1>>%DOWNLOAD_LOGFILE%
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
if exist %DOWNLOAD_LOGFILE% (
  echo.>>%DOWNLOAD_LOGFILE%
  echo -------------------------------------------------------------------------------->>%DOWNLOAD_LOGFILE%
  echo.>>%DOWNLOAD_LOGFILE%
)
if exist .\custom\InitializationHook.cmd (
  call :Log "Info: Executed custom initialization hook (Errorlevel: %ERR_LEVEL%)"
  set ERR_LEVEL=
)
call :Log "Info: Starting WSUS Offline Update - Community Edition - download v. %WSUSOFFLINE_VERSION% for %1 %2"

for %%i in (w60 w60-x64 w61 w61-x64 w62-x64 w63 w63-x64 w100 w100-x64 o2k16) do (
  if /i "%1"=="%%i" (
    if /i "%2"=="glb" goto EvalParams
  )
)
for %%i in (o2k13) do (
  if /i "%1"=="%%i" (
    for %%j in (enu fra esn jpn kor rus ptg ptb deu nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do (if /i "%2"=="%%j" goto Lang_%%j)
  )
)
goto InvalidParams

rem The variable LANG_SHORT was replaced with LOCALE_LONG, consisting of
rem the language and region code, e.g. de-de or en-us.
:Lang_enu
set LOCALE_LONG=en-us
goto EvalParams

:Lang_fra
set LOCALE_LONG=fr-fr
goto EvalParams

:Lang_esn
set LOCALE_LONG=es-es
goto EvalParams

:Lang_jpn
set LOCALE_LONG=ja-jp
goto EvalParams

:Lang_kor
set LOCALE_LONG=ko-kr
goto EvalParams

:Lang_rus
set LOCALE_LONG=ru-ru
goto EvalParams

:Lang_ptg
set LOCALE_LONG=pt-pt
goto EvalParams

:Lang_ptb
set LOCALE_LONG=pt-br
goto EvalParams

:Lang_deu
set LOCALE_LONG=de-de
goto EvalParams

:Lang_nld
set LOCALE_LONG=nl-nl
goto EvalParams

:Lang_ita
set LOCALE_LONG=it-it
goto EvalParams

:Lang_chs
set LOCALE_LONG=zh-cn
goto EvalParams

:Lang_cht
set LOCALE_LONG=zh-tw
goto EvalParams

:Lang_plk
set LOCALE_LONG=pl-pl
goto EvalParams

:Lang_hun
set LOCALE_LONG=hu-hu
goto EvalParams

:Lang_csy
set LOCALE_LONG=cs-cz
goto EvalParams

:Lang_sve
set LOCALE_LONG=sv-se
goto EvalParams

:Lang_trk
set LOCALE_LONG=tr-tr
goto EvalParams

:Lang_ell
set LOCALE_LONG=el-gr
goto EvalParams

:Lang_ara
set LOCALE_LONG=ar-sa
goto EvalParams

:Lang_heb
set LOCALE_LONG=he-il
goto EvalParams

:Lang_dan
set LOCALE_LONG=da-dk
goto EvalParams

:Lang_nor
set LOCALE_LONG=nb-no
goto EvalParams

:Lang_fin
set LOCALE_LONG=fi-fi
goto EvalParams

:EvalParams
if "%3"=="" goto NoMoreParams
for %%i in (/excludesp /excludestatics /excludewinglb /includedotnet /seconly /includemsse /includewddefs /nocleanup /verify /exitonerror /skipsdd /skiptz /skipdownload /skipdynamic /proxy /wsus /wsusonly /wsusbyproxy) do (
  if /i "%3"=="%%i" call :Log "Info: Option %%i detected"
)
if /i "%3"=="/excludesp" set EXC_SP=1
if /i "%3"=="/excludestatics" set EXC_STATICS=1
if /i "%3"=="/excludewinglb" set EXC_WINGLB=1
if /i "%3"=="/includedotnet" set INC_DOTNET=1
if /i "%3"=="/seconly" set SECONLY=1
if /i "%3"=="/includemsse" set INC_MSSE=1
if /i "%3"=="/includewddefs" (
  echo %1 | %SystemRoot%\System32\find.exe /I "w62" >nul 2>&1
  if errorlevel 1 (
    echo %1 | %SystemRoot%\System32\find.exe /I "w63" >nul 2>&1
    if errorlevel 1 (
      echo %1 | %SystemRoot%\System32\find.exe /I "w100" >nul 2>&1
      if errorlevel 1 (set INC_WDDEFS=1) else (set INC_MSSE=1)
    ) else (set INC_MSSE=1)
  ) else (set INC_MSSE=1)
)
if /i "%3"=="/nocleanup" set CLEANUP_DL=0
if /i "%3"=="/verify" set VERIFY_DL=1
if /i "%3"=="/exitonerror" set EXIT_ERR=1
if /i "%3"=="/skipsdd" set SKIP_SDD=1
if /i "%3"=="/skiptz" set SKIP_TZ=1
if /i "%3"=="/skipdownload" (
  set SKIP_DL=1
  set SKIP_PARAM=/skipdownload
)
if /i "%3"=="/skipdynamic" (if "%SKIP_PARAM%"=="" set SKIP_PARAM=/skipdynamic)
if /i "%3"=="/proxy" (
  set http_proxy=%4
  set https_proxy=%4
  shift /3
)
if /i "%3"=="/wsus" (
  set WSUS_URL=%4
  shift /3
)
if /i "%3"=="/wsusonly" set WSUS_ONLY=1
if /i "%3"=="/wsusbyproxy" set WSUS_BY_PROXY=1
shift /3
goto EvalParams

:NoMoreParams
echo %1 | %SystemRoot%\System32\find.exe /I "x64" >nul 2>&1
if errorlevel 1 (set TARGET_ARCH=x86) else (set TARGET_ARCH=x64)
if "%TEMP%"=="" goto NoTemp
pushd "%TEMP%"
if errorlevel 1 goto NoTempDir
popd
if exist ..\doc\history.txt (
  echo Checking for sufficient file system rights...
  ren ..\doc\history.txt _history.txt
  if errorlevel 1 (
    echo.
    echo ERROR: Unable to rename file ..\doc\history.txt
    goto InsufficientRights
  )
  ren ..\doc\_history.txt history.txt
)
set CSCRIPT_PATH=%SystemRoot%\System32\cscript.exe
if not exist %CSCRIPT_PATH% goto NoCScript
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set WGET_PATH=..\bin\wget64.exe) else (
  if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" (set WGET_PATH=..\bin\wget64.exe) else (set WGET_PATH=..\bin\wget.exe)
)
if not exist %WGET_PATH% goto NoWGet
set TZ=
if "%SKIP_TZ%"=="1" goto SkipTZ
%CSCRIPT_PATH% //Nologo //B //E:vbs DetermineCurrentTimeZone.vbs /nodebug
if not exist "%TEMP%\SetTZVariable.cmd" goto SkipTZ
call "%TEMP%\SetTZVariable.cmd"
del "%TEMP%\SetTZVariable.cmd"
call :Log "Info: Set time zone to !TZ!"
:SkipTZ
if exist custom\SetAria2EnvVars.cmd (
  if "%http_proxy%" NEQ "" (call ActivateAria2Downloads.cmd /reload /proxy %http_proxy%) else (call ActivateAria2Downloads.cmd /reload)
  call custom\SetAria2EnvVars.cmd
) else (
  set DLDR_PATH=%WGET_PATH%
  set DLDR_COPT=-N --progress=bar:noscroll --trust-server-names
  set DLDR_LOPT=-a %DOWNLOAD_LOGFILE%
  set DLDR_IOPT=-i
  set DLDR_POPT=-P
  set DLDR_NVOPT=-nv
  rem set DLDR_NCOPT=--no-check-certificate
  set DLDR_UOPT=-U "Mozilla/5.0 (Windows NT 10.0)"
)
if not exist %DLDR_PATH% goto NoDLdr
if not exist ..\bin\unzip.exe goto NoUnZip
if not exist ..\client\bin\unzip.exe copy ..\bin\unzip.exe ..\client\bin >nul
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set HASHDEEP_EXE=hashdeep64.exe) else (
  if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" (set HASHDEEP_EXE=hashdeep64.exe) else (set HASHDEEP_EXE=hashdeep.exe)
)

rem ** disable SDD, if local version != most recent version ***
if "%http_proxy%" NEQ "" (call CheckOUVersion.cmd /mode:different /quiet /proxy %http_proxy%) else (call CheckOUVersion.cmd /mode:different /quiet)
if not "%errorlevel%"=="0" (
  set SKIP_SDD=1
  call :Log "Info: Disabled static and exclude definitions update due to version mismatch"
)

rem *** Clean up existing directories ***
echo Cleaning up existing directories...
if exist ..\iso\dummy.txt del ..\iso\dummy.txt
if exist ..\log\dummy.txt del ..\log\dummy.txt
if exist ..\exclude\custom\dummy.txt del ..\exclude\custom\dummy.txt
if exist ..\static\custom\dummy.txt del ..\static\custom\dummy.txt
if exist ..\static\sdd\dummy.txt del ..\static\sdd\dummy.txt
if exist ..\client\exclude\custom\dummy.txt del ..\client\exclude\custom\dummy.txt
if exist ..\client\static\custom\dummy.txt del ..\client\static\custom\dummy.txt
if exist ..\client\software\msi\dummy.txt del ..\client\software\msi\dummy.txt
if exist ..\client\UpdateTable\dummy.txt del ..\client\UpdateTable\dummy.txt
if exist .\custom\InitializationHook.cmd (
  if exist .\custom\InitializationHook.cmdt del .\custom\InitializationHook.cmdt
)
if exist .\custom\FinalizationHook.cmd (
  if exist .\custom\FinalizationHook.cmdt del .\custom\FinalizationHook.cmdt
)
if exist ..\client\cmd\custom\InitializationHook.cmd (
  if exist ..\client\cmd\custom\InitializationHook.cmdt del ..\client\cmd\custom\InitializationHook.cmdt
)
if exist ..\client\cmd\custom\FinalizationHook.cmd (
  if exist ..\client\cmd\custom\FinalizationHook.cmdt del ..\client\cmd\custom\FinalizationHook.cmdt
)
if exist ..\client\cmd\custom\FinalizationHookFinal.cmd (
  if exist ..\client\cmd\custom\FinalizationHookFinal.cmdt del ..\client\cmd\custom\FinalizationHookFinal.cmdt
)
if exist ..\client\cmd\custom\SetUpdatesPerStage.cmd (
  if exist ..\client\cmd\custom\SetUpdatesPerStage.cmdt del ..\client\cmd\custom\SetUpdatesPerStage.cmdt
)
if exist ..\client\software\custom\InstallCustomSoftware.cmd (
  if exist ..\client\software\custom\InstallCustomSoftware.cmdt del ..\client\software\custom\InstallCustomSoftware.cmdt
)
if exist .\--no-proxy\nul rd /S /Q .\--no-proxy

rem *** Obsolete internal stuff ***
if exist ActivateVistaAllLanguageServicePacks.cmd del ActivateVistaAllLanguageServicePacks.cmd
if exist ActivateVistaFiveLanguageServicePacks.cmd del ActivateVistaFiveLanguageServicePacks.cmd
if exist DetermineAutoDaylightTimeSet.vbs del DetermineAutoDaylightTimeSet.vbs
if exist CheckTRCerts.cmd del CheckTRCerts.cmd
if exist ..\doc\faq.txt del ..\doc\faq.txt
if exist ..\client\cmd\Reboot.vbs del ..\client\cmd\Reboot.vbs
if exist ..\client\cmd\Shutdown.vbs del ..\client\cmd\Shutdown.vbs
if exist ..\client\msi\nul rd /S /Q ..\client\msi
if exist ..\client\opt\OptionList-Q.txt del ..\client\opt\OptionList-Q.txt
if exist ..\client\opt\OptionList-qn.txt del ..\client\opt\OptionList-qn.txt
if exist ..\client\static\StaticUpdateIds-ie9-w61.txt del ..\client\static\StaticUpdateIds-ie9-w61.txt
if exist ..\client\static\StaticUpdateIds-w100-x86.txt del ..\client\static\StaticUpdateIds-w100-x86.txt
if exist ..\client\static\StaticUpdateIds-w100-x64.txt del ..\client\static\StaticUpdateIds-w100-x64.txt
if exist ..\opt\nul rd /S /Q ..\opt
del /Q ..\static\StaticDownloadLinks-ie8-w60-*.txt >nul 2>&1
del /Q ..\static\StaticDownloadLinks-ie9-w61-*.txt >nul 2>&1
if exist ..\xslt\ExtractDownloadLinks-wua-x86.xsl del ..\xslt\ExtractDownloadLinks-wua-x86.xsl
if exist ..\xslt\ExtractDownloadLinks-wua-x64.xsl del ..\xslt\ExtractDownloadLinks-wua-x64.xsl
if exist ..\xslt\ExtractBundledUpdateRelationsAndFileIds.xsl del ..\xslt\ExtractBundledUpdateRelationsAndFileIds.xsl
if exist ..\xslt\ExtractUpdateCategoriesAndFileIds.xsl del ..\xslt\ExtractUpdateCategoriesAndFileIds.xsl
if exist ..\xslt\ExtractUpdateCabExeIdsAndLocations.xsl del ..\xslt\ExtractUpdateCabExeIdsAndLocations.xsl
if exist ..\xslt\ExtractSupersededUpdateRelations.xsl del ..\xslt\ExtractSupersededUpdateRelations.xsl
if exist ..\xslt\ExtractSupersedingRevisionIds.xsl del ..\xslt\ExtractSupersedingRevisionIds.xsl
if exist ..\xslt\ExtractUpdateFileIdsAndLocations.xsl del ..\xslt\ExtractUpdateFileIdsAndLocations.xsl
if exist ..\xslt\ExtractUpdateRevisionAndFileIds.xsl del ..\xslt\ExtractUpdateRevisionAndFileIds.xsl
if exist ..\xslt\ExtractUpdateRevisionIds.xsl del ..\xslt\ExtractUpdateRevisionIds.xsl
if exist ..\xslt\extract-office-revision-and-update-ids.xsl del ..\xslt\extract-office-revision-and-update-ids.xsl
if exist ..\xslt\ExtractDownloadLinks-dotnet-x64-glb.xsl del ..\xslt\ExtractDownloadLinks-dotnet-x64-glb.xsl
if exist ..\xslt\ExtractDownloadLinks-dotnet-x86-glb.xsl del ..\xslt\ExtractDownloadLinks-dotnet-x86-glb.xsl
if exist ..\xslt\ExtractDownloadLinks-w60-x64-glb.xsl del ..\xslt\ExtractDownloadLinks-w60-x64-glb.xsl
if exist ..\xslt\ExtractDownloadLinks-w60-x86-glb.xsl del ..\xslt\ExtractDownloadLinks-w60-x86-glb.xsl
if exist ..\xslt\ExtractDownloadLinks-w61-x64-glb.xsl del ..\xslt\ExtractDownloadLinks-w61-x64-glb.xsl
if exist ..\xslt\ExtractDownloadLinks-w61-x86-glb.xsl del ..\xslt\ExtractDownloadLinks-w61-x86-glb.xsl
if exist ..\xslt\ExtractDownloadLinks-w62-x64-glb.xsl del ..\xslt\ExtractDownloadLinks-w62-x64-glb.xsl
if exist ..\xslt\ExtractDownloadLinks-w63-x64-glb.xsl del ..\xslt\ExtractDownloadLinks-w63-x64-glb.xsl
if exist ..\xslt\ExtractDownloadLinks-w63-x86-glb.xsl del ..\xslt\ExtractDownloadLinks-w63-x86-glb.xsl
if exist ..\xslt\ExtractDownloadLinks-w100-x64-glb.xsl del ..\xslt\ExtractDownloadLinks-w100-x64-glb.xsl
if exist ..\xslt\ExtractDownloadLinks-w100-x86-glb.xsl del ..\xslt\ExtractDownloadLinks-w100-x86-glb.xsl
del /Q ..\xslt\*-win-x86-*.* >nul 2>&1
if exist ..\static\StaticDownloadFiles-modified.txt del ..\static\StaticDownloadFiles-modified.txt
if exist ..\exclude\ExcludeDownloadFiles-modified.txt del ..\exclude\ExcludeDownloadFiles-modified.txt
if exist ..\client\static\StaticUpdateFiles-modified.txt del ..\client\static\StaticUpdateFiles-modified.txt

rem *** Obsolete external stuff ***
if exist ..\bin\extract.exe del ..\bin\extract.exe
if exist ..\bin\fciv.exe del ..\bin\fciv.exe
if exist ..\bin\msxsl.exe del ..\bin\msxsl.exe
if exist ..\bin\upx.exe del ..\bin\upx.exe
if exist ..\sh\hashdeep del ..\sh\hashdeep
if exist ..\fciv\nul rd /S /Q ..\fciv
if exist ..\static\StaticDownloadLink-extract.txt del ..\static\StaticDownloadLink-extract.txt
if exist ..\static\StaticDownloadLink-fciv.txt del ..\static\StaticDownloadLink-fciv.txt
if exist ..\static\StaticDownloadLink-msxsl.txt del ..\static\StaticDownloadLink-msxsl.txt
if exist ..\static\StaticDownloadLink-sigcheck.txt del ..\static\StaticDownloadLink-sigcheck.txt
if exist ..\static\StaticDownloadLink-streams.txt del ..\static\StaticDownloadLink-streams.txt
if exist ..\static\StaticDownloadLinks-mkisofs.txt del ..\static\StaticDownloadLinks-mkisofs.txt
if exist ..\static\StaticDownloadLink-unzip.txt del ..\static\StaticDownloadLink-unzip.txt

rem *** Windows 2000 stuff ***
if exist ..\client\bin\reg.exe del ..\client\bin\reg.exe
if exist ..\client\static\StaticUpdateIds-w2k-x86.txt del ..\client\static\StaticUpdateIds-w2k-x86.txt
if exist FixIE6SetupDir.cmd del FixIE6SetupDir.cmd
for %%i in (enu fra esn jpn kor rus ptg ptb deu nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do (
  if exist ..\client\win\%%i\ie6setup\nul rd /S /Q ..\client\win\%%i\ie6setup
)
if exist ..\exclude\ExcludeList-w2k-x86.txt del ..\exclude\ExcludeList-w2k-x86.txt
if exist ..\exclude\ExcludeListISO-w2k-x86.txt del ..\exclude\ExcludeListISO-w2k-x86.txt
if exist ..\exclude\ExcludeListUSB-w2k-x86.txt del ..\exclude\ExcludeListUSB-w2k-x86.txt
if exist ..\sh\FIXIE6SetupDir.sh del ..\sh\FIXIE6SetupDir.sh
del /Q ..\static\*ie6-*.* >nul 2>&1
del /Q ..\static\*w2k-*.* >nul 2>&1
del /Q ..\xslt\*w2k-*.* >nul 2>&1

rem *** Windows XP stuff ***
if exist ..\client\static\StaticUpdateIds-wxp-x86.txt del ..\client\static\StaticUpdateIds-wxp-x86.txt
if exist ..\exclude\ExcludeList-wxp-x86.txt del ..\exclude\ExcludeList-wxp-x86.txt
if exist ..\exclude\ExcludeListISO-wxp-x86.txt del ..\exclude\ExcludeListISO-wxp-x86.txt
if exist ..\exclude\ExcludeListUSB-wxp-x86.txt del ..\exclude\ExcludeListUSB-wxp-x86.txt
del /Q ..\static\*-wxp-x86-*.* >nul 2>&1
del /Q ..\xslt\*-wxp-x86-*.* >nul 2>&1

rem *** Windows Server 2003 stuff ***
if exist ..\client\static\StaticUpdateIds-w2k3-x86.txt del ..\client\static\StaticUpdateIds-w2k3-x86.txt
if exist ..\client\static\StaticUpdateIds-w2k3-x64.txt del ..\client\static\StaticUpdateIds-w2k3-x64.txt
if exist ..\exclude\ExcludeList-w2k3-x86.txt del ..\exclude\ExcludeList-w2k3-x86.txt
if exist ..\exclude\ExcludeList-w2k3-x64.txt del ..\exclude\ExcludeList-w2k3-x64.txt
if exist ..\exclude\ExcludeListISO-w2k3-x86.txt del ..\exclude\ExcludeListISO-w2k3-x86.txt
if exist ..\exclude\ExcludeListISO-w2k3-x64.txt del ..\exclude\ExcludeListISO-w2k3-x64.txt
if exist ..\exclude\ExcludeListUSB-w2k3-x86.txt del ..\exclude\ExcludeListUSB-w2k3-x86.txt
if exist ..\exclude\ExcludeListUSB-w2k3-x64.txt del ..\exclude\ExcludeListUSB-w2k3-x64.txt
del /Q ..\static\*-w2k3-*.* >nul 2>&1
del /Q ..\xslt\*-w2k3-*.* >nul 2>&1

rem *** Windows language specific stuff ***
del /Q ..\static\*-win-x86-*.* >nul 2>&1

rem *** Windows 8 stuff ***
if exist ..\client\static\StaticUpdateIds-w62-x86.txt del ..\client\static\StaticUpdateIds-w62-x86.txt
if exist ..\exclude\ExcludeList-w62-x86.txt del ..\exclude\ExcludeList-w62-x86.txt
if exist ..\exclude\ExcludeListISO-w62-x86.txt del ..\exclude\ExcludeListISO-w62-x86.txt
if exist ..\exclude\ExcludeListUSB-w62-x86.txt del ..\exclude\ExcludeListUSB-w62-x86.txt
if exist ..\static\StaticDownloadLinks-w62-x86-glb.txt del ..\static\StaticDownloadLinks-w62-x86-glb.txt
if exist ..\xslt\ExtractDownloadLinks-w62-x86-glb.xsl del ..\xslt\ExtractDownloadLinks-w62-x86-glb.xsl

rem *** Windows 10 Version 1511 stuff ***
if exist ..\client\static\StaticUpdateIds-w100-10586-x64.txt del ..\client\static\StaticUpdateIds-w100-10586-x64.txt
if exist ..\client\static\StaticUpdateIds-w100-10586-x86.txt del ..\client\static\StaticUpdateIds-w100-10586-x86.txt

rem *** Windows 10 Version 1703 stuff ***
if exist ..\client\static\StaticUpdateIds-w100-15063-dotnet.txt del ..\client\static\StaticUpdateIds-w100-15063-dotnet.txt
if exist ..\client\static\StaticUpdateIds-w100-15063-dotnet4-528049.txt del ..\client\static\StaticUpdateIds-w100-15063-dotnet4-528049.txt
if exist ..\client\static\StaticUpdateIds-w100-15063-x64.txt del ..\client\static\StaticUpdateIds-w100-15063-x64.txt
if exist ..\client\static\StaticUpdateIds-w100-15063-x86.txt del ..\client\static\StaticUpdateIds-w100-15063-x86.txt
if exist ..\client\static\StaticUpdateIds-wupre-w100-15063.txt del ..\client\static\StaticUpdateIds-wupre-w100-15063.txt

rem *** Windows 10 Version 1709 stuff ***
if exist ..\client\static\StaticUpdateIds-w100-16299.txt del ..\client\static\StaticUpdateIds-w100-16299.txt
if exist ..\client\static\StaticUpdateIds-w100-16299-x64.txt del ..\client\static\StaticUpdateIds-w100-16299-x64.txt
if exist ..\client\static\StaticUpdateIds-w100-16299-x86.txt del ..\client\static\StaticUpdateIds-w100-16299-x86.txt
if exist ..\client\static\StaticUpdateIds-wupre-w100-16299.txt del ..\client\static\StaticUpdateIds-wupre-w100-16299.txt
if exist ..\client\static\StaticUpdateIds-servicing-w100-16299.txt del ..\client\static\StaticUpdateIds-servicing-w100-16299.txt
if exist ..\client\static\StaticUpdateIds-w100-16299-dotnet.txt del ..\client\static\StaticUpdateIds-w100-16299-dotnet.txt
if exist ..\client\static\StaticUpdateIds-w100-16299-dotnet4-528049.txt del ..\client\static\StaticUpdateIds-w100-16299-dotnet4-528049.txt

rem *** Windows 10 Version 1803 stuff ***
if exist ..\client\static\StaticUpdateIds-w100-17134.txt del ..\client\static\StaticUpdateIds-w100-17134.txt
if exist ..\client\static\StaticUpdateIds-w100-17134-x64.txt del ..\client\static\StaticUpdateIds-w100-17134-x64.txt
if exist ..\client\static\StaticUpdateIds-w100-17134-x86.txt del ..\client\static\StaticUpdateIds-w100-17134-x86.txt
if exist ..\client\static\StaticUpdateIds-wupre-w100-17134.txt del ..\client\static\StaticUpdateIds-wupre-w100-17134.txt
if exist ..\client\static\StaticUpdateIds-servicing-w100-17134.txt del ..\client\static\StaticUpdateIds-servicing-w100-17134.txt
if exist ..\client\static\StaticUpdateIds-w100-17134-dotnet.txt del ..\client\static\StaticUpdateIds-w100-17134-dotnet.txt
if exist ..\client\static\StaticUpdateIds-w100-17134-dotnet4-528049.txt del ..\client\static\StaticUpdateIds-w100-17134-dotnet4-528049.txt

rem *** Windows 10 Version 190x stuff ***
if exist ..\client\static\StaticUpdateIds-w100-18362.txt del ..\client\static\StaticUpdateIds-w100-18362.txt
if exist ..\client\static\StaticUpdateIds-w100-18362-x64.txt del ..\client\static\StaticUpdateIds-w100-18362-x64.txt
if exist ..\client\static\StaticUpdateIds-w100-18362-x86.txt del ..\client\static\StaticUpdateIds-w100-18362-x86.txt
if exist ..\client\static\StaticUpdateIds-wupre-w100-18362.txt del ..\client\static\StaticUpdateIds-wupre-w100-18362.txt
if exist ..\client\static\StaticUpdateIds-servicing-w100-18362.txt del ..\client\static\StaticUpdateIds-servicing-w100-18362.txt
if exist ..\client\static\StaticUpdateIds-w100-18362-dotnet.txt del ..\client\static\StaticUpdateIds-w100-18362-dotnet.txt
if exist ..\client\static\StaticUpdateIds-w100-18363.txt del ..\client\static\StaticUpdateIds-w100-18363.txt
if exist ..\client\static\StaticUpdateIds-w100-18363-x64.txt del ..\client\static\StaticUpdateIds-w100-18363-x64.txt
if exist ..\client\static\StaticUpdateIds-w100-18363-x86.txt del ..\client\static\StaticUpdateIds-w100-18363-x86.txt
if exist ..\client\static\StaticUpdateIds-wupre-w100-18363.txt del ..\client\static\StaticUpdateIds-wupre-w100-18363.txt
if exist ..\client\static\StaticUpdateIds-servicing-w100-18363.txt del ..\client\static\StaticUpdateIds-servicing-w100-18363.txt
if exist ..\client\static\StaticUpdateIds-w100-18363-dotnet.txt del ..\client\static\StaticUpdateIds-w100-18363-dotnet.txt

rem *** Office and invcif.exe stuff ***
if exist ..\static\StaticDownloadLinks-inventory.txt del ..\static\StaticDownloadLinks-inventory.txt
if exist ..\client\wsus\invcif.exe (
  if exist ..\client\md\hashes-wsus.txt del ..\client\md\hashes-wsus.txt
  del ..\client\wsus\invcif.exe
)
if exist ..\client\wsus\invcm.exe (
  if exist ..\client\md\hashes-wsus.txt del ..\client\md\hashes-wsus.txt
  del ..\client\wsus\invcm.exe
)
if exist ..\client\static\StaticUpdateIds-o2k7-x*.txt del ..\client\static\StaticUpdateIds-o2k7-x*.txt
if exist ..\ExtractDownloadLinks-oall.cmd del ..\ExtractDownloadLinks-oall.cmd
if exist ..\ExtractDownloadLinks-wall.cmd del ..\ExtractDownloadLinks-wall.cmd
if exist ..\static\StaticDownloadLinks-o2k7-x*.txt del ..\static\StaticDownloadLinks-o2k7-x*.txt
if exist ..\xslt\ExtractDownloadLinks-oall-deu.xsl del ..\xslt\ExtractDownloadLinks-oall-deu.xsl
if exist ..\xslt\ExtractDownloadLinks-oall-enu.xsl del ..\xslt\ExtractDownloadLinks-oall-enu.xsl
if exist ..\xslt\ExtractDownloadLinks-oall-fra.xsl del ..\xslt\ExtractDownloadLinks-oall-fra.xsl
if exist ..\xslt\ExtractDownloadLinks-wall.xsl del ..\xslt\ExtractDownloadLinks-wall.xsl
del /Q ..\exclude\ExcludeList*-oxp.txt >nul 2>&1
del /Q ..\exclude\ExcludeList*-o2k3.txt >nul 2>&1
del /Q ..\exclude\ExcludeList*-o2k7*.txt >nul 2>&1
del /Q ..\exclude\ExcludeList*-o2k10.txt >nul 2>&1
del /Q ..\static\StaticDownloadLinks-ofc-*.txt >nul 2>&1
del /Q ..\xslt\ExtractDownloadLinks-o*.* >nul 2>&1
del /Q ..\xslt\ExtractExpiredIds-o*.* >nul 2>&1
del /Q ..\xslt\ExtractValidIds-o*.* >nul 2>&1

rem *** Office 2000 stuff ***
if exist ..\client\bin\msxsl.exe del ..\client\bin\msxsl.exe
if exist ..\client\xslt\nul rd /S /Q ..\client\xslt
if exist ..\client\static\StaticUpdateIds-o2k.txt del ..\client\static\StaticUpdateIds-o2k.txt
del /Q ..\exclude\ExcludeList*-o2k.txt >nul 2>&1
del /Q ..\static\*o2k-*.* >nul 2>&1
del /Q ..\xslt\*o2k-*.* >nul 2>&1
if exist ..\xslt\ExtractExpiredIds-o2k.xsl del ..\xslt\ExtractExpiredIds-o2k.xsl
if exist ..\xslt\ExtractValidIds-o2k.xsl del ..\xslt\ExtractValidIds-o2k.xsl

rem *** Office XP stuff ***
if exist ..\client\static\StaticUpdateIds-oxp.txt del ..\client\static\StaticUpdateIds-oxp.txt
del /Q ..\static\*oxp-*.* >nul 2>&1

rem *** Office 2003 stuff ***
if exist ..\client\static\StaticUpdateIds-o2k3.txt del ..\client\static\StaticUpdateIds-o2k3.txt
del /Q ..\static\*o2k3-*.* >nul 2>&1

rem *** Office 2007 stuff ***
if exist ..\client\static\StaticUpdateIds-o2k7.txt del ..\client\static\StaticUpdateIds-o2k7.txt
del /Q ..\static\*o2k7-*.* >nul 2>&1

rem *** Office 2010 stuff ***
if exist ..\client\static\StaticUpdateIds-o2k10.txt del ..\client\static\StaticUpdateIds-o2k10.txt
del /Q ..\static\*o2k10-*.* >nul 2>&1

rem *** CPP restructuring stuff ***
if exist ..\client\md\hashes-cpp-x64-glb.txt del ..\client\md\hashes-cpp-x64-glb.txt
if exist ..\client\cpp\x64-glb\nul (
  move /Y ..\client\cpp\x64-glb\*.* ..\client\cpp >nul
  rd /S /Q ..\client\cpp\x64-glb
)
if exist ..\client\md\hashes-cpp-x86-glb.txt del ..\client\md\hashes-cpp-x86-glb.txt
if exist ..\client\cpp\x86-glb\nul (
  move /Y ..\client\cpp\x86-glb\*.* ..\client\cpp >nul
  rd /S /Q ..\client\cpp\x86-glb
)
if exist ..\client\static\StaticUpdateIds-cpp2005_x64_documented.txt del ..\client\static\StaticUpdateIds-cpp2005_x64_documented.txt
if exist ..\client\static\StaticUpdateIds-cpp2005_x64_new.txt del ..\client\static\StaticUpdateIds-cpp2005_x64_new.txt
if exist ..\client\static\StaticUpdateIds-cpp2005_x64_old.txt del ..\client\static\StaticUpdateIds-cpp2005_x64_old.txt
if exist ..\client\static\StaticUpdateIds-cpp2005_x86_documented.txt del ..\client\static\StaticUpdateIds-cpp2005_x86_documented.txt
if exist ..\client\static\StaticUpdateIds-cpp2005_x86_new.txt del ..\client\static\StaticUpdateIds-cpp2005_x86_new.txt
if exist ..\client\static\StaticUpdateIds-cpp2005_x86_old.txt del ..\client\static\StaticUpdateIds-cpp2005_x86_old.txt
if exist ..\client\static\StaticUpdateIds-cpp2008_x64_documented.txt del ..\client\static\StaticUpdateIds-cpp2008_x64_documented.txt
if exist ..\client\static\StaticUpdateIds-cpp2008_x64_new.txt del ..\client\static\StaticUpdateIds-cpp2008_x64_new.txt
if exist ..\client\static\StaticUpdateIds-cpp2008_x64_old.txt del ..\client\static\StaticUpdateIds-cpp2008_x64_old.txt
if exist ..\client\static\StaticUpdateIds-cpp2008_x86_documented.txt del ..\client\static\StaticUpdateIds-cpp2008_x86_documented.txt
if exist ..\client\static\StaticUpdateIds-cpp2008_x86_new.txt del ..\client\static\StaticUpdateIds-cpp2008_x86_new.txt
if exist ..\client\static\StaticUpdateIds-cpp2008_x86_old.txt del ..\client\static\StaticUpdateIds-cpp2008_x86_old.txt
if exist ..\client\static\StaticUpdateIds-cpp2010_x64_documented.txt del ..\client\static\StaticUpdateIds-cpp2010_x64_documented.txt
if exist ..\client\static\StaticUpdateIds-cpp2010_x64_new.txt del ..\client\static\StaticUpdateIds-cpp2010_x64_new.txt
if exist ..\client\static\StaticUpdateIds-cpp2010_x64_old.txt del ..\client\static\StaticUpdateIds-cpp2010_x64_old.txt
if exist ..\client\static\StaticUpdateIds-cpp2010_x86_documented.txt del ..\client\static\StaticUpdateIds-cpp2010_x86_documented.txt
if exist ..\client\static\StaticUpdateIds-cpp2010_x86_new.txt del ..\client\static\StaticUpdateIds-cpp2010_x86_new.txt
if exist ..\client\static\StaticUpdateIds-cpp2010_x86_old.txt del ..\client\static\StaticUpdateIds-cpp2010_x86_old.txt
if exist ..\client\static\StaticUpdateIds-cpp2012_x64_documented.txt del ..\client\static\StaticUpdateIds-cpp2012_x64_documented.txt
if exist ..\client\static\StaticUpdateIds-cpp2012_x64_new.txt del ..\client\static\StaticUpdateIds-cpp2012_x64_new.txt
if exist ..\client\static\StaticUpdateIds-cpp2012_x64_old.txt del ..\client\static\StaticUpdateIds-cpp2012_x64_old.txt
if exist ..\client\static\StaticUpdateIds-cpp2012_x86_documented.txt del ..\client\static\StaticUpdateIds-cpp2012_x86_documented.txt
if exist ..\client\static\StaticUpdateIds-cpp2012_x86_new.txt del ..\client\static\StaticUpdateIds-cpp2012_x86_new.txt
if exist ..\client\static\StaticUpdateIds-cpp2012_x86_old.txt del ..\client\static\StaticUpdateIds-cpp2012_x86_old.txt
if exist ..\client\static\StaticUpdateIds-cpp2013_x64_documented.txt del ..\client\static\StaticUpdateIds-cpp2013_x64_documented.txt
if exist ..\client\static\StaticUpdateIds-cpp2013_x64_new.txt del ..\client\static\StaticUpdateIds-cpp2013_x64_new.txt
if exist ..\client\static\StaticUpdateIds-cpp2013_x64_old.txt del ..\client\static\StaticUpdateIds-cpp2013_x64_old.txt
if exist ..\client\static\StaticUpdateIds-cpp2013_x86_documented.txt del ..\client\static\StaticUpdateIds-cpp2013_x86_documented.txt
if exist ..\client\static\StaticUpdateIds-cpp2013_x86_new.txt del ..\client\static\StaticUpdateIds-cpp2013_x86_new.txt
if exist ..\client\static\StaticUpdateIds-cpp2013_x86_old.txt del ..\client\static\StaticUpdateIds-cpp2013_x86_old.txt
if exist ..\client\static\StaticUpdateIds-cpp2015_x64_documented.txt del ..\client\static\StaticUpdateIds-cpp2015_x64_documented.txt
if exist ..\client\static\StaticUpdateIds-cpp2015_x64_new.txt del ..\client\static\StaticUpdateIds-cpp2015_x64_new.txt
if exist ..\client\static\StaticUpdateIds-cpp2015_x64_old.txt del ..\client\static\StaticUpdateIds-cpp2015_x64_old.txt
if exist ..\client\static\StaticUpdateIds-cpp2015_x86_documented.txt del ..\client\static\StaticUpdateIds-cpp2015_x86_documented.txt
if exist ..\client\static\StaticUpdateIds-cpp2015_x86_new.txt del ..\client\static\StaticUpdateIds-cpp2015_x86_new.txt
if exist ..\client\static\StaticUpdateIds-cpp2015_x86_old.txt del ..\client\static\StaticUpdateIds-cpp2015_x86_old.txt

rem *** .NET restructuring stuff ***
if exist ..\exclude\ExcludeList-dotnet.txt del ..\exclude\ExcludeList-dotnet.txt
if exist ..\exclude\ExcludeList-dotnet-x86.txt del ..\exclude\ExcludeList-dotnet-x86.txt
if exist ..\exclude\ExcludeList-dotnet-x64.txt del ..\exclude\ExcludeList-dotnet-x64.txt
if exist ..\client\win\glb\ndp*.* (
  if not exist ..\client\dotnet\x86-glb\nul md ..\client\dotnet\x86-glb
  move /Y ..\client\win\glb\ndp*.* ..\client\dotnet\x86-glb >nul
)
del /Q ..\static\StaticDownloadLinks-dotnet-x*-*.txt >nul 2>&1
if exist ..\xslt\ExtractDownloadLinks-dotnet-glb.xsl del ..\xslt\ExtractDownloadLinks-dotnet-glb.xsl
if exist ..\xslt\extract-revision-and-update-ids-dotnet.xsl del ..\xslt\extract-revision-and-update-ids-dotnet.xsl
if exist ..\client\static\StaticUpdateIds-dotnet.txt del ..\client\static\StaticUpdateIds-dotnet.txt
if exist ..\client\dotnet\glb\nul (
  if not exist ..\client\dotnet\x64-glb\nul md ..\client\dotnet\x64-glb
  move /Y ..\client\dotnet\glb\*-x64_*.* ..\client\dotnet\x64-glb >nul
  if not exist ..\client\dotnet\x86-glb\nul md ..\client\dotnet\x86-glb
  move /Y ..\client\dotnet\glb\*-x86_*.* ..\client\dotnet\x86-glb >nul
  rd /S /Q ..\client\dotnet\glb
)

rem *** IE restructuring stuff ***
if exist ..\client\static\StaticUpdateIds-ie10-w61.txt del ..\client\static\StaticUpdateIds-ie10-w61.txt

rem *** Microsoft Security Essentials stuff ***
if exist ..\static\StaticDownloadLink-mssedefs-x64.txt del ..\static\StaticDownloadLink-mssedefs-x64.txt
if exist ..\static\StaticDownloadLink-mssedefs-x86.txt del ..\static\StaticDownloadLink-mssedefs-x86.txt
if exist ..\static\StaticDownloadLink-mssedefs-x64-glb.txt del ..\static\StaticDownloadLink-mssedefs-x64-glb.txt
if exist ..\static\StaticDownloadLink-mssedefs-x86-glb.txt del ..\static\StaticDownloadLink-mssedefs-x86-glb.txt
if exist ..\client\mssedefs\x64\nul (
  if not exist ..\client\mssedefs\x64-glb\nul md ..\client\mssedefs\x64-glb
  move /Y ..\client\mssedefs\x64\*.* ..\client\mssedefs\x64-glb >nul
  rd /S /Q ..\client\mssedefs\x64
)
if exist ..\client\mssedefs\x86\nul (
  if not exist ..\client\mssedefs\x86-glb\nul md ..\client\mssedefs\x86-glb
  move /Y ..\client\mssedefs\x86\*.* ..\client\mssedefs\x86-glb >nul
  rd /S /Q ..\client\mssedefs\x86
)
if exist ..\client\mssedefs\nul move /Y ..\client\mssedefs msse >nul
if exist ..\client\md\hashes-mssedefs.txt del ..\client\md\hashes-mssedefs.txt
if exist ..\client\md\hashes-msse.txt del ..\client\md\hashes-msse.txt

rem *** Old Windows Defender stuff ***
if exist ..\client\md\hashes-wddefs.txt del ..\client\md\hashes-wddefs.txt

rem *** Windows Update Agent stuff ***
if exist ..\client\wsus\WindowsUpdateAgent30-x64.exe (
  del ..\client\wsus\WindowsUpdateAgent30-x64.exe
  if exist ..\client\md\hashes-wsus.txt del ..\client\md\hashes-wsus.txt
)
if exist ..\client\wsus\WindowsUpdateAgent30-x86.exe (
  del ..\client\wsus\WindowsUpdateAgent30-x86.exe
  if exist ..\client\md\hashes-wsus.txt del ..\client\md\hashes-wsus.txt
)

rem *** Windows Essentials 2012 stuff ***
del /Q ..\static\StaticDownloadLinks-wle-*.txt >nul 2>&1
del /Q ..\static\custom\StaticDownloadLinks-wle-*.txt >nul 2>&1
if exist ..\exclude\ExcludeList-wle.txt del ..\exclude\ExcludeList-wle.txt
if exist ..\client\wle\nul rd /S /Q ..\client\wle
if exist ..\client\md\hashes-wle.txt del ..\client\md\hashes-wle.txt

rem *** old self update stuff ***
if exist ..\static\StaticDownloadLink-this.txt del ..\static\StaticDownloadLink-this.txt

rem *** delete old-style hashes ***
if exist ..\client\md\nul (
  for /f "delims=" %%f in ('dir /b ..\client\md\hashes-*.txt 2^>nul') do (
    %SystemRoot%\System32\findstr.exe /L /C:"-c md5,sha1,sha256 -b" /C:"-c sha1 -b" "..\client\md\%%f" >nul 2>&1
    if errorlevel 1 (
      del /Q "..\client\md\%%f" >nul 2>&1
    )
  )
)

rem *** Update static download definitions ***
if "%SKIP_SDD%"=="1" goto SkipSDD
echo Preserving custom language and architecture additions and removals...
set REMOVE_CMD=
%SystemRoot%\System32\find.exe /I "us." ..\static\StaticDownloadLinks-w61-x86-glb.txt >nul 2>&1
if errorlevel 1 (
  set REMOVE_CMD=RemoveEnglishLanguageSupport.cmd !REMOVE_CMD!
)
%SystemRoot%\System32\find.exe /I "de." ..\static\StaticDownloadLinks-w61-x86-glb.txt >nul 2>&1
if errorlevel 1 (
  set REMOVE_CMD=RemoveGermanLanguageSupport.cmd !REMOVE_CMD!
)
set CUST_LANG=
if exist ..\static\custom\StaticDownloadLinks-dotnet.txt (
  for %%i in (fra esn jpn kor rus ptg ptb nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do (
    %SystemRoot%\System32\find.exe /I "%%i" ..\static\custom\StaticDownloadLinks-dotnet.txt >nul 2>&1
    if not errorlevel 1 (
      set CUST_LANG=%%i !CUST_LANG!
      call RemoveCustomLanguageSupport.cmd %%i /quiet
    )
  )
)
set OX64_LANG=
for %%i in (enu fra esn jpn kor rus ptg ptb deu nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do (
  if exist ..\static\custom\StaticDownloadLinks-o2k13-%%i.txt (
    set OX64_LANG=%%i !OX64_LANG!
    call RemoveOffice2010x64Support.cmd %%i /quiet
  )
)
call :Log "Info: Preserved custom language and architecture additions and removals"

echo Updating static and exclude definitions for download and update...
if not exist ..\static\sdd md ..\static\sdd
call :SDDCore https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/StaticDownloadFiles-modified.txt ..\static\sdd
if not "%SDDCoreReturnValue%"=="0" (
  call :Log "Warning: Failed to update StaticDownloadFiles-modified.txt"
  goto SkipSDDDownload
)
if exist ..\static\sdd\StaticDownloadFiles-modified.txt (
  for /f "delims=" %%f in (..\static\sdd\StaticDownloadFiles-modified.txt) do (
    if not "%%f"=="" (
      call :SDDCore %%f ..\static
      if not "!SDDCoreReturnValue!"=="0" (
        call :Log "Warning: Failed to download %%f"
        goto SkipSDDDownload
      )
    )
  )
)
call :SDDCore https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/ExcludeDownloadFiles-modified.txt ..\static\sdd
if not "%SDDCoreReturnValue%"=="0" (
  call :Log "Warning: Failed to update ExcludeDownloadFiles-modified.txt"
  goto SkipSDDDownload
)
if exist ..\static\sdd\ExcludeDownloadFiles-modified.txt (
  for /f "delims=" %%f in (..\static\sdd\ExcludeDownloadFiles-modified.txt) do (
    if not "%%f"=="" (
      call :SDDCore %%f ..\exclude
      if not "!SDDCoreReturnValue!"=="0" (
        call :Log "Warning: Failed to download %%f"
        goto SkipSDDDownload
      )
    )
  )
)
call :SDDCore https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/StaticUpdateFiles-modified.txt ..\static\sdd
if not "%SDDCoreReturnValue%"=="0" (
  call :Log "Warning: Failed to update StaticUpdateFiles-modified.txt"
  goto SkipSDDDownload
)
if exist ..\static\sdd\StaticUpdateFiles-modified.txt (
  for /f "delims=" %%f in (..\static\sdd\StaticUpdateFiles-modified.txt) do (
    if not "%%f"=="" (
      call :SDDCore %%f ..\client\static
      if not "!SDDCoreReturnValue!"=="0" (
        call :Log "Warning: Failed to download %%f"
        goto SkipSDDDownload
      )
    )
  )
)

copy /Y ..\exclude\ExcludeList-superseded-exclude.txt ..\exclude\ExcludeList-superseded-exclude.ori >nul
call :SDDCore https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/ExcludeList-superseded-exclude.txt ..\exclude
if "%SDDCoreReturnValue%"=="0" (
  echo n | %SystemRoot%\System32\comp.exe ..\exclude\ExcludeList-superseded-exclude.txt ..\exclude\ExcludeList-superseded-exclude.ori /A /L /C >nul 2>&1
  if errorlevel 1 (
    if exist ..\exclude\ExcludeList-superseded.txt del ..\exclude\ExcludeList-superseded.txt
  )
  del ..\exclude\ExcludeList-superseded-exclude.ori
) else (
  call :Log "Warning: Failed to update .\exclude\ExcludeList-superseded-exclude.txt"
  move /Y ..\exclude\ExcludeList-superseded-exclude.ori ..\exclude\ExcludeList-superseded-exclude.txt >nul
)
copy /Y ..\exclude\ExcludeList-superseded-exclude-seconly.txt ..\exclude\ExcludeList-superseded-exclude-seconly.ori >nul
call :SDDCore https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/ExcludeList-superseded-exclude-seconly.txt ..\exclude
if "%SDDCoreReturnValue%"=="0" (
  echo n | %SystemRoot%\System32\comp.exe ..\exclude\ExcludeList-superseded-exclude-seconly.txt ..\exclude\ExcludeList-superseded-exclude-seconly.ori /A /L /C >nul 2>&1
  if errorlevel 1 (
    if exist ..\exclude\ExcludeList-superseded.txt del ..\exclude\ExcludeList-superseded.txt
  )
  del ..\exclude\ExcludeList-superseded-exclude-seconly.ori
) else (
  call :Log "Warning: Failed to update .\exclude\ExcludeList-superseded-exclude-seconly.txt"
  move /Y ..\exclude\ExcludeList-superseded-exclude-seconly.ori ..\exclude\ExcludeList-superseded-exclude-seconly.txt >nul
)
copy /Y ..\client\exclude\ExcludeList.txt ..\client\exclude\ExcludeList.ori >nul
call :SDDCore https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/ExcludeList.txt ..\client\exclude
if "%SDDCoreReturnValue%"=="0" (
  del ..\client\exclude\ExcludeList.ori
) else (
  call :Log "Warning: Failed to update .\client\exclude\ExcludeList.txt"
  move /Y ..\client\exclude\ExcludeList.ori ..\client\exclude\ExcludeList.txt >nul
)
copy /Y ..\client\exclude\HideList-seconly.txt ..\client\exclude\HideList-seconly.ori >nul
call :SDDCore https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/HideList-seconly.txt ..\client\exclude
if "%SDDCoreReturnValue%"=="0" (
  echo n | %SystemRoot%\System32\comp.exe ..\client\exclude\HideList-seconly.txt ..\client\exclude\HideList-seconly.ori /A /L /C >nul 2>&1
  if errorlevel 1 (
    if exist ..\exclude\ExcludeList-superseded.txt del ..\exclude\ExcludeList-superseded.txt
  )
  del ..\client\exclude\HideList-seconly.ori
) else (
  call :Log "Warning: Failed to update .\client\exclude\HideList-seconly.txt"
  move /Y ..\client\exclude\HideList-seconly.ori ..\client\exclude\HideList-seconly.txt >nul
)
copy /Y ..\client\opt\OptionList.txt ..\client\opt\OptionList.ori >nul
call :SDDCore https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/OptionList.txt ..\client\opt
if "%SDDCoreReturnValue%"=="0" (
  del ..\client\opt\OptionList.ori
) else (
  call :Log "Warning: Failed to update .\client\opt\OptionList.txt"
  move /Y ..\client\opt\OptionList.ori ..\client\opt\OptionList.txt >nul
)
copy /Y ..\client\opt\OptionList-wildcard.txt ..\client\opt\OptionList-wildcard.ori >nul
call :SDDCore https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/OptionList-wildcard.txt ..\client\opt
if "%SDDCoreReturnValue%"=="0" (
  del ..\client\opt\OptionList-wildcard.ori
) else (
  call :Log "Warning: Failed to update .\client\opt\OptionList-wildcard.txt"
  move /Y ..\client\opt\OptionList-wildcard.ori ..\client\opt\OptionList-wildcard.txt >nul
)
call :Log "Info: Updated static and exclude definitions for download and update"
:SkipSDDDownload

echo Restoring custom language and architecture additions and removals...
if "%REMOVE_CMD%" NEQ "" (
  for %%i in (%REMOVE_CMD%) do call %%i /quiet
)
if "%CUST_LANG%" NEQ "" (
  for %%i in (%CUST_LANG%) do call AddCustomLanguageSupport.cmd %%i /quiet
)
if "%OX64_LANG%" NEQ "" (
  for %%i in (%OX64_LANG%) do call AddOffice2010x64Support.cmd %%i /quiet
)
set REMOVE_CMD=
set CUST_LANG=
set OX64_LANG=
call :Log "Info: Restored custom language and architecture additions and removals"
:SkipSDD

rem *** Download mkisofs tool ***
if "%SKIP_DL%"=="1" goto SkipMkIsoFs
echo Downloading/validating mkisofs tool...
call :SDDCore https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/mkisofs.exe ..\bin
if "%SDDCoreReturnValue%"=="0" (
  call :Log "Info: Downloaded/validated mkisofs tool"
) else (
  echo Warning: Download of mkisofs tool failed.
  call :Log "Warning: Download of mkisofs tool failed"
)
:SkipMkIsoFs

rem *** Download Sysinternals' tools Autologon, Sigcheck and Streams ***
if "%SKIP_DL%"=="1" goto SkipSysinternals
:DownloadSysinternals
echo Downloading Sysinternals' tools Autologon, Sigcheck and Streams...
%DLDR_PATH% %DLDR_COPT% %DLDR_IOPT% ..\static\StaticDownloadLinks-sysinternals.txt %DLDR_POPT% ..\bin
if errorlevel 1 goto DownloadError
call :Log "Info: Downloaded Sysinternals' tools Autologon, Sigcheck and Streams"
pushd ..\bin
unzip.exe -u -o AutoLogon.zip -x Eula.txt -d ..\client\bin
unzip.exe -u -o Sigcheck.zip -x Eula.txt
unzip.exe -u -o Streams.zip -x Eula.txt
popd
:SkipSysinternals
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set SIGCHK_PATH=..\bin\sigcheck64.exe) else (
  if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" (set SIGCHK_PATH=..\bin\sigcheck64.exe) else (set SIGCHK_PATH=..\bin\sigcheck.exe)
)
if not exist %SIGCHK_PATH% goto SkipSigChkOpts
%CSCRIPT_PATH% //Nologo //B //E:vbs ..\client\cmd\DetermineFileVersion.vbs %SIGCHK_PATH% SIGCHK_VER
if exist "%TEMP%\SetFileVersion.cmd" (
  call "%TEMP%\SetFileVersion.cmd"
  del "%TEMP%\SetFileVersion.cmd"
) else (set SIGCHK_VER_MAJOR=2)
if %SIGCHK_VER_MAJOR% GEQ 2 (set SIGCHK_COPT=/accepteula -q -c -nobanner) else (set SIGCHK_COPT=/accepteula -q -v)
set SIGCHK_VER_MAJOR=
set SIGCHK_VER_MINOR=
set SIGCHK_VER_BUILD=
set SIGCHK_VER_REVIS=
:SkipSigChkOpts
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set STRMS_PATH=..\bin\streams64.exe) else (
  if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" (set STRMS_PATH=..\bin\streams64.exe) else (set STRMS_PATH=..\bin\streams.exe)
)

rem *** Cleanup UpdateOU.new ***
if exist UpdateOU.new (
  if exist UpdateOU.cmd del UpdateOU.cmd
  ren UpdateOU.new UpdateOU.cmd
  rem *** Remove NTFS alternate data streams from new or updated script files ***
  if exist %STRMS_PATH% (
    %STRMS_PATH% /accepteula ..\*.* >nul 2>&1
    if errorlevel 1 (
      call :Log "Info: File system does not support streams"
    ) else (
      echo Removing NTFS alternate data streams from new or updated script files...
      %STRMS_PATH% /accepteula -s -d ..\*.cmd >nul 2>&1
      %STRMS_PATH% /accepteula -s -d ..\*.exe >nul 2>&1
      %STRMS_PATH% /accepteula -s -d ..\*.vbs >nul 2>&1
      if errorlevel 1 (
        echo Warning: Unable to remove NTFS alternate data streams from new or updated script files.
        call :Log "Warning: Unable to remove NTFS alternate data streams from new or updated script files"
      ) else (
        call :Log "Info: Removed NTFS alternate data streams from new or updated script files"
      )
    )
  ) else (
    echo Warning: Sysinternals' NTFS alternate data stream handling tool %STRMS_PATH% not found.
    call :Log "Warning: Sysinternals' NTFS alternate data stream handling tool %STRMS_PATH% not found"
  )
)

rem *** Download most recent Windows Update catalog file ***
if "%VERIFY_DL%" NEQ "1" goto DownloadWSUS
if not exist ..\client\wsus\nul goto DownloadWSUS
if not exist ..\client\bin\%HASHDEEP_EXE% goto NoHashDeep
if exist ..\client\md\hashes-wsus.txt (
  echo Verifying integrity of Windows Update catalog file...
  ..\client\bin\%HASHDEEP_EXE% -a -b -vv -k ..\client\md\hashes-wsus.txt -r ..\client\wsus
  if errorlevel 1 (
    goto IntegrityError
  )
  call :Log "Info: Verified integrity of Windows Update catalog file"
) else (
  echo Warning: Integrity database ..\client\md\hashes-wsus.txt not found.
  call :Log "Warning: Integrity database ..\client\md\hashes-wsus.txt not found"
)
:DownloadWSUS
if not exist ..\client\wsus\nul md ..\client\wsus
if exist ..\client\md\hashes-wsus.txt del ..\client\md\hashes-wsus.txt
echo Downloading/validating most recent Windows Update catalog file...
if exist ..\client\wsus\wsusscn2.cab (
  copy /Y ..\client\wsus\wsusscn2.cab ..\client\wsus\wsusscn2.bak >nul
)
%DLDR_PATH% %DLDR_COPT% %DLDR_IOPT% ..\static\StaticDownloadLinks-wsus.txt %DLDR_POPT% ..\client\wsus
if errorlevel 1 goto DownloadError
call :Log "Info: Downloaded/validated most recent Windows Update catalog file"
if "%VERIFY_DL%" NEQ "1" goto SkipWSUS
if not exist %SIGCHK_PATH% goto NoSigCheck
echo Verifying digital file signature of Windows Update catalog file...
for /F "skip=1 tokens=1 delims=," %%i in ('%SIGCHK_PATH% %SIGCHK_COPT% -s ..\client\wsus ^| %SystemRoot%\System32\findstr.exe /I /V "\"Signed\""') do (
  del "%%i"
  echo Warning: Deleted unsigned file %%i.
  call :Log "Warning: Deleted unsigned file '%%~i'"
)
if exist ..\client\wsus\wsusscn2.cab (
  if exist ..\client\wsus\wsusscn2.bak del ..\client\wsus\wsusscn2.bak
) else (
  if not exist ..\client\wsus\wsusscn2.bak goto SignatureError
  ren ..\client\wsus\wsusscn2.bak wsusscn2.cab
  %SystemRoot%\System32\attrib.exe -A ..\client\wsus\wsusscn2.cab
  call :Log "Info: Restored preexisting catalog file ..\client\wsus\wsusscn2.cab"
)
call :Log "Info: Verified digital file signature of Windows Update catalog file"
if not exist ..\client\bin\%HASHDEEP_EXE% goto NoHashDeep
echo Creating integrity database for Windows Update catalog file...
if not exist ..\client\md\nul md ..\client\md
..\client\bin\%HASHDEEP_EXE% -c md5,sha1,sha256 -b -r ..\client\wsus >..\client\md\hashes-wsus.txt
if errorlevel 1 (
  echo Warning: Error creating integrity database ..\client\md\hashes-wsus.txt.
  call :Log "Warning: Error creating integrity database ..\client\md\hashes-wsus.txt"
) else (
  call :Log "Info: Created integrity database for Windows Update catalog file"
)
for %%i in (..\client\md\hashes-wsus.txt) do if %%~zi==0 del %%i
:SkipWSUS

rem *** Download installation files for .NET Frameworks 3.5 SP1 and 4.x ***
if "%INC_DOTNET%" NEQ "1" goto SkipDotNet
if "%SKIP_DL%"=="1" goto SkipDotNet
if "%VERIFY_DL%" NEQ "1" goto DownloadDotNet
if not exist ..\client\dotnet\nul goto DownloadDotNet
if not exist ..\client\bin\%HASHDEEP_EXE% goto NoHashDeep
if exist ..\client\md\hashes-dotnet.txt (
  echo Verifying integrity of .NET Frameworks' installation files...
  ..\client\bin\%HASHDEEP_EXE% -a -b -vv -k ..\client\md\hashes-dotnet.txt -r ..\client\dotnet
  if errorlevel 1 (
    goto IntegrityError
  )
  call :Log "Info: Verified integrity of .NET Frameworks' installation files"
  if exist ..\client\md\hashes-dotnet.txt (
    for %%i in (..\client\md\hashes-dotnet.txt) do echo _%%~ti | %SystemRoot%\System32\find.exe "_%DATE:~-10%" >nul 2>&1
    if not errorlevel 1 (
      echo Skipping download/validation of .NET Frameworks' files due to 'same day' rule.
      call :Log "Info: Skipped download/validation of .NET Frameworks' files due to 'same day' rule"
      goto SkipDotNet
    )
  )
) else (
  echo Warning: Integrity database ..\client\md\hashes-dotnet.txt not found.
  call :Log "Warning: Integrity database ..\client\md\hashes-dotnet.txt not found"
)
:DownloadDotNet
if not exist ..\client\dotnet\nul md ..\client\dotnet
if exist ..\client\md\hashes-dotnet.txt del ..\client\md\hashes-dotnet.txt
echo Downloading/validating installation files for .NET Frameworks 3.5 SP1 and 4.x...
copy /Y ..\static\StaticDownloadLinks-dotnet.txt "%TEMP%\StaticDownloadLinks-dotnet.txt" >nul
if exist ..\static\custom\StaticDownloadLinks-dotnet.txt (
  type ..\static\custom\StaticDownloadLinks-dotnet.txt >>"%TEMP%\StaticDownloadLinks-dotnet.txt"
)
if exist ..\exclude\custom\ExcludeListForce-all.txt (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:..\exclude\custom\ExcludeListForce-all.txt "%TEMP%\StaticDownloadLinks-dotnet.txt" >"%TEMP%\ValidStaticLinks-dotnet.txt"
  del "%TEMP%\StaticDownloadLinks-dotnet.txt"
) else (
  if exist "%TEMP%\ValidStaticLinks-dotnet.txt" del "%TEMP%\ValidStaticLinks-dotnet.txt"
  ren "%TEMP%\StaticDownloadLinks-dotnet.txt" ValidStaticLinks-dotnet.txt
)

for /F "usebackq tokens=* delims=" %%i in ("%TEMP%\ValidStaticLinks-dotnet.txt") do (
  %DLDR_PATH% %DLDR_COPT% %DLDR_POPT% ..\client\dotnet "%%i"
  if errorlevel 1 (
    if exist "..\client\dotnet\%%~nxi" del "..\client\dotnet\%%~nxi"
    echo Warning: Download of %%i failed.
    call :Log "Warning: Download of %%i failed"
  ) else (
    call :Log "Info: Downloaded/validated %%i to ..\client\dotnet"
  )
)
call :Log "Info: Downloaded/validated installation files for .NET Frameworks 3.5 SP1 and 4.x"
if "%CLEANUP_DL%"=="0" (
  del "%TEMP%\ValidStaticLinks-dotnet.txt"
  goto VerifyDotNet
)
echo Cleaning up client directory for .NET Frameworks 3.5 SP1 and 4.x...
for /F "delims=" %%i in ('dir ..\client\dotnet /A:-D /B 2^>nul') do (
  %SystemRoot%\System32\find.exe /I "%%i" "%TEMP%\ValidStaticLinks-dotnet.txt" >nul 2>&1
  if errorlevel 1 (
    del "..\client\dotnet\%%i"
    call :Log "Info: Deleted ..\client\dotnet\%%i"
  )
)
del "%TEMP%\ValidStaticLinks-dotnet.txt"
call :Log "Info: Cleaned up client directory for .NET Frameworks 3.5 SP1 and 4.x"
:VerifyDotNet
if "%VERIFY_DL%" NEQ "1" goto SkipDotNet
rem *** Verifying digital file signatures for .NET Frameworks' installation files ***
if not exist %SIGCHK_PATH% goto NoSigCheck
echo Verifying digital file signatures for .NET Frameworks' installation files...
for /F "skip=1 tokens=1 delims=," %%i in ('%SIGCHK_PATH% %SIGCHK_COPT% -s ..\client\dotnet ^| %SystemRoot%\System32\findstr.exe /I /V "\"Signed\""') do (
  del "%%i"
  echo Warning: Deleted unsigned file %%i.
  call :Log "Warning: Deleted unsigned file '%%~i'"
)
call :Log "Info: Verified digital file signatures for .NET Frameworks' installation files"
if not exist ..\client\bin\%HASHDEEP_EXE% goto NoHashDeep
echo Creating integrity database for .NET Frameworks' installation files...
if not exist ..\client\md\nul md ..\client\md
..\client\bin\%HASHDEEP_EXE% -c md5,sha1,sha256 -b -r ..\client\dotnet >..\client\md\hashes-dotnet.txt
if errorlevel 1 (
  echo Warning: Error creating integrity database ..\client\md\hashes-dotnet.txt.
  call :Log "Warning: Error creating integrity database ..\client\md\hashes-dotnet.txt"
) else (
  call :Log "Info: Created integrity database for .NET Frameworks' installation files"
)
for %%i in (..\client\md\hashes-dotnet.txt) do if %%~zi==0 del %%i
:SkipDotNet

rem *** Download C++ Runtime Libraries' installation files ***
if "%INC_DOTNET%" NEQ "1" goto SkipCPP
if "%SKIP_DL%"=="1" goto SkipCPP
if "%VERIFY_DL%" NEQ "1" goto DownloadCPP
if not exist ..\client\cpp\nul goto DownloadCPP
if not exist ..\client\bin\%HASHDEEP_EXE% goto NoHashDeep
if exist ..\client\md\hashes-cpp.txt (
  echo Verifying integrity of C++ Runtime Libraries' installation files...
  ..\client\bin\%HASHDEEP_EXE% -a -b -vv -k ..\client\md\hashes-cpp.txt -r ..\client\cpp
  if errorlevel 1 (
    goto IntegrityError
  )
  call :Log "Info: Verified integrity of C++ Runtime Libraries' installation files"
  for %%i in (..\client\md\hashes-cpp.txt) do echo _%%~ti | %SystemRoot%\System32\find.exe "_%DATE:~-10%" >nul 2>&1
  if not errorlevel 1 (
    echo Skipping download/validation of C++ Runtime Libraries' installation files due to 'same day' rule.
    call :Log "Info: Skipped download/validation of C++ Runtime Libraries' installation files due to 'same day' rule"
    goto SkipCPP
  )
) else (
  echo Warning: Integrity database ..\client\md\hashes-cpp.txt not found.
  call :Log "Warning: Integrity database ..\client\md\hashes-cpp.txt not found"
)
:DownloadCPP
if not exist ..\client\cpp\nul md ..\client\cpp
if exist ..\client\md\hashes-cpp.txt del ..\client\md\hashes-cpp.txt
echo Downloading/validating C++ Runtime Libraries' installation files...
for %%i in (x64 x86) do (
  for /F "tokens=1,2 delims=," %%j in (..\static\StaticDownloadLinks-cpp-%%i-glb.txt) do (
    if "%%k" NEQ "" (
      if exist "..\client\cpp\%%k" (
        echo Renaming file ..\client\cpp\%%k to %%~nxj...
        if exist "..\client\cpp\%%~nxj" del "..\client\cpp\%%~nxj"
        ren "..\client\cpp\%%k" "%%~nxj"
        call :Log "Info: Renamed file ..\client\cpp\%%k to %%~nxj"
      )
    )
    %DLDR_PATH% %DLDR_COPT% %DLDR_POPT% ..\client\cpp "%%j"
    if errorlevel 1 (
      if exist "..\client\cpp\%%~nxj" del "..\client\cpp\%%~nxj"
      echo Warning: Download of %%j failed.
      call :Log "Warning: Download of %%j failed"
    )
    if "%%k" NEQ "" (
      if exist "..\client\cpp\%%~nxj" (
        echo Renaming file ..\client\cpp\%%~nxj to %%k...
        ren "..\client\cpp\%%~nxj" "%%k"
        call :Log "Info: Renamed file ..\client\cpp\%%~nxj to %%k"
      )
    )
  )
)
call :Log "Info: Downloaded/validated C++ Runtime Libraries' installation files"
if "%CLEANUP_DL%"=="0" goto VerifyCPP
echo Cleaning up client directory for C++ Runtime Libraries...
for /F "delims=" %%i in ('dir ..\client\cpp /A:-D /B 2^>nul') do (
  %SystemRoot%\System32\find.exe /I "%%i" ..\static\StaticDownloadLinks-cpp-x64-glb.txt >nul 2>&1
  if errorlevel 1 (
    %SystemRoot%\System32\find.exe /I "%%i" ..\static\StaticDownloadLinks-cpp-x86-glb.txt >nul 2>&1
    if errorlevel 1 (
      del "..\client\cpp\%%i"
      call :Log "Info: Deleted ..\client\cpp\%%i"
    )
  )
)
call :Log "Info: Cleaned up client directory for C++ Runtime Libraries"
:VerifyCPP
if "%VERIFY_DL%" NEQ "1" goto SkipCPP
rem *** Verifying digital file signatures for C++ Runtime Libraries' installation files ***
if not exist %SIGCHK_PATH% goto NoSigCheck
echo Verifying digital file signatures for C++ Runtime Libraries' installation files...
for /F "skip=1 tokens=1 delims=," %%i in ('%SIGCHK_PATH% %SIGCHK_COPT% -s ..\client\cpp ^| %SystemRoot%\System32\findstr.exe /I /V "\"Signed\""') do (
  del "%%i"
  echo Warning: Deleted unsigned file %%i.
  call :Log "Warning: Deleted unsigned file '%%~i'"
)
call :Log "Info: Verified digital file signatures for C++ Runtime Libraries' installation files"
if not exist ..\client\bin\%HASHDEEP_EXE% goto NoHashDeep
echo Creating integrity database for C++ Runtime Libraries' installation files...
if not exist ..\client\md\nul md ..\client\md
..\client\bin\%HASHDEEP_EXE% -c md5,sha1,sha256 -b -r ..\client\cpp >..\client\md\hashes-cpp.txt
if errorlevel 1 (
  echo Warning: Error creating integrity database ..\client\md\hashes-cpp.txt.
  call :Log "Warning: Error creating integrity database ..\client\md\hashes-cpp.txt"
) else (
  call :Log "Info: Created integrity database for C++ Runtime Libraries' installation files"
)
for %%i in (..\client\md\hashes-cpp.txt) do if %%~zi==0 del %%i
:SkipCPP

rem *** Download Microsoft Security Essentials ***
if "%INC_MSSE%" NEQ "1" goto SkipMSSE
if "%SKIP_DL%"=="1" goto SkipMSSE
if "%VERIFY_DL%" NEQ "1" goto DownloadMSSE
if not exist ..\client\msse\nul goto DownloadMSSE
if not exist ..\client\bin\%HASHDEEP_EXE% goto NoHashDeep
if exist ..\client\md\hashes-msse-%TARGET_ARCH%-glb.txt (
  echo Verifying integrity of Microsoft Security Essentials files...
  ..\client\bin\%HASHDEEP_EXE% -a -b -vv -k ..\client\md\hashes-msse-%TARGET_ARCH%-glb.txt -r ..\client\msse\%TARGET_ARCH%-glb
  if errorlevel 1 (
    goto IntegrityError
  )
  call :Log "Info: Verified integrity of Microsoft Security Essentials files"
  if exist ..\client\msse\%TARGET_ARCH%-glb\mpam*.exe (
    for %%i in (..\client\msse\%TARGET_ARCH%-glb\mpam*.exe) do echo _%%~ti | %SystemRoot%\System32\find.exe "_%DATE:~-10%" >nul 2>&1
    if not errorlevel 1 (
      echo Skipping download/validation of Microsoft Security Essentials files ^(%TARGET_ARCH%^) due to 'same day' rule.
      call :Log "Info: Skipped download/validation of Microsoft Security Essentials files (%TARGET_ARCH%) due to 'same day' rule"
      goto SkipMSSE
    )
  )
) else (
  echo Warning: Integrity database ..\client\md\hashes-msse-%TARGET_ARCH%-glb.txt not found.
  call :Log "Warning: Integrity database ..\client\md\hashes-msse-%TARGET_ARCH%-glb.txt not found"
)
:DownloadMSSE
if not exist ..\client\msse\nul md ..\client\msse
if exist ..\client\md\hashes-msse-%TARGET_ARCH%-glb.txt del ..\client\md\hashes-msse-%TARGET_ARCH%-glb.txt
echo Downloading/validating Microsoft Security Essentials files...
copy /Y ..\static\StaticDownloadLinks-msse-%TARGET_ARCH%-glb.txt "%TEMP%\StaticDownloadLinks-msse-%TARGET_ARCH%-glb.txt" >nul
if exist ..\static\custom\StaticDownloadLinks-msse-%TARGET_ARCH%-glb.txt (
  type ..\static\custom\StaticDownloadLinks-msse-%TARGET_ARCH%-glb.txt >>"%TEMP%\StaticDownloadLinks-msse-%TARGET_ARCH%-glb.txt"
)
for /F "usebackq tokens=1,2 delims=," %%i in ("%TEMP%\StaticDownloadLinks-msse-%TARGET_ARCH%-glb.txt") do (
  if "%%j" NEQ "" (
    if exist "..\client\msse\%TARGET_ARCH%-glb\%%j" (
      echo Renaming file ..\client\msse\%TARGET_ARCH%-glb\%%j to %%~nxi...
      if exist "..\client\msse\%TARGET_ARCH%-glb\%%~nxi" del "..\client\msse\%TARGET_ARCH%-glb\%%~nxi"
      ren "..\client\msse\%TARGET_ARCH%-glb\%%j" "%%~nxi"
      call :Log "Info: Renamed file ..\client\msse\%TARGET_ARCH%-glb\%%j to %%~nxi"
    )
  )
  %DLDR_PATH% %DLDR_COPT% %DLDR_UOPT% %DLDR_POPT% ..\client\msse\%TARGET_ARCH%-glb "%%i"
  if errorlevel 1 (
    if exist "..\client\msse\%TARGET_ARCH%-glb\%%~nxi" del "..\client\msse\%TARGET_ARCH%-glb\%%~nxi"
    echo Warning: Download of %%i failed.
    call :Log "Warning: Download of %%i failed"
  )
  if "%%j" NEQ "" (
    if exist "..\client\msse\%TARGET_ARCH%-glb\%%~nxi" (
      echo Renaming file ..\client\msse\%TARGET_ARCH%-glb\%%~nxi to %%j...
      ren "..\client\msse\%TARGET_ARCH%-glb\%%~nxi" "%%j"
      call :Log "Info: Renamed file ..\client\msse\%TARGET_ARCH%-glb\%%~nxi to %%j"
    )
  )
)
call :Log "Info: Downloaded/validated Microsoft Security Essentials files"
if "%CLEANUP_DL%"=="0" (
  del "%TEMP%\StaticDownloadLinks-msse-%TARGET_ARCH%-glb.txt"
  goto VerifyMSSE
)
echo Cleaning up client directory for Microsoft Security Essentials...
for /F "delims=" %%i in ('dir ..\client\msse\%TARGET_ARCH%-glb /A:-D /B 2^>nul') do (
  if "%%i" NEQ "mpam-fe.exe" (
    %SystemRoot%\System32\find.exe /I "%%i" "%TEMP%\StaticDownloadLinks-msse-%TARGET_ARCH%-glb.txt" >nul 2>&1
    if errorlevel 1 (
      del "..\client\msse\%TARGET_ARCH%-glb\%%i"
      call :Log "Info: Deleted ..\client\msse\%TARGET_ARCH%-glb\%%i"
    )
  )
)
del "%TEMP%\StaticDownloadLinks-msse-%TARGET_ARCH%-glb.txt"
call :Log "Info: Cleaned up client directory for Microsoft Security Essentials"
:VerifyMSSE
if "%VERIFY_DL%" NEQ "1" goto SkipMSSE
rem *** Verifying digital file signatures for Microsoft Security Essentials files ***
if not exist %SIGCHK_PATH% goto NoSigCheck
echo Verifying digital file signatures for Microsoft Security Essentials files...
for /F "skip=1 tokens=1 delims=," %%i in ('%SIGCHK_PATH% %SIGCHK_COPT% -s ..\client\msse\%TARGET_ARCH%-glb ^| %SystemRoot%\System32\findstr.exe /I /V "\"Signed\""') do (
  del "%%i"
  echo Warning: Deleted unsigned file %%i.
  call :Log "Warning: Deleted unsigned file '%%~i'"
)
call :Log "Info: Verified digital file signatures for Microsoft Security Essentials files"
if not exist ..\client\bin\%HASHDEEP_EXE% goto NoHashDeep
echo Creating integrity database for Microsoft Security Essentials files...
if not exist ..\client\md\nul md ..\client\md
..\client\bin\%HASHDEEP_EXE% -c md5,sha1,sha256 -b -r ..\client\msse\%TARGET_ARCH%-glb >..\client\md\hashes-msse-%TARGET_ARCH%-glb.txt
if errorlevel 1 (
  echo Warning: Error creating integrity database ..\client\md\hashes-msse-%TARGET_ARCH%-glb.txt.
  call :Log "Warning: Error creating integrity database ..\client\md\hashes-msse-%TARGET_ARCH%-glb.txt"
) else (
  call :Log "Info: Created integrity database for Microsoft Security Essentials files"
)
for %%i in (..\client\md\hashes-msse-%TARGET_ARCH%-glb.txt) do if %%~zi==0 del %%i
:SkipMSSE

rem *** Download Windows Defender definition files ***
if "%INC_WDDEFS%" NEQ "1" goto SkipWDDefs
if "%SKIP_DL%"=="1" goto SkipWDDefs
if "%VERIFY_DL%" NEQ "1" goto DownloadWDDefs
if not exist ..\client\wddefs\nul goto DownloadWDDefs
if not exist ..\client\bin\%HASHDEEP_EXE% goto NoHashDeep
if exist ..\client\md\hashes-wddefs-%TARGET_ARCH%-glb.txt (
  echo Verifying integrity of Windows Defender definition files...
  ..\client\bin\%HASHDEEP_EXE% -a -b -vv -k ..\client\md\hashes-wddefs-%TARGET_ARCH%-glb.txt -r ..\client\wddefs\%TARGET_ARCH%-glb
  if errorlevel 1 (
    goto IntegrityError
  )
  call :Log "Info: Verified integrity of Windows Defender definition files"
  if exist ..\client\wddefs\%TARGET_ARCH%-glb\mpas*.exe (
    for %%i in (..\client\wddefs\%TARGET_ARCH%-glb\mpas*.exe) do echo _%%~ti | %SystemRoot%\System32\find.exe "_%DATE:~-10%" >nul 2>&1
    if not errorlevel 1 (
      echo Skipping download/validation of Windows Defender definition files ^(%TARGET_ARCH%^) due to 'same day' rule.
      call :Log "Info: Skipped download/validation of Windows Defender definition files (%TARGET_ARCH%) due to 'same day' rule"
      goto SkipWDDefs
    )
  )
) else (
  echo Warning: Integrity database ..\client\md\hashes-wddefs-%TARGET_ARCH%-glb.txt not found.
  call :Log "Warning: Integrity database ..\client\md\hashes-wddefs-%TARGET_ARCH%-glb.txt not found"
)
:DownloadWDDefs
if not exist ..\client\wddefs\nul md ..\client\wddefs
if exist ..\client\md\hashes-wddefs-%TARGET_ARCH%-glb.txt del ..\client\md\hashes-wddefs-%TARGET_ARCH%-glb.txt
echo Downloading/validating Windows Defender definition files...
%DLDR_PATH% %DLDR_COPT% %DLDR_UOPT% %DLDR_IOPT% ..\static\StaticDownloadLink-wddefs-%TARGET_ARCH%-glb.txt %DLDR_POPT% ..\client\wddefs\%TARGET_ARCH%-glb
if errorlevel 1 (
  echo Warning: Download/validation of Windows Defender definition files failed.
  call :Log "Warning: Download/validation of Windows Defender definition files failed"
)
call :Log "Info: Downloaded/validated Windows Defender definition files"

rem *** Verifying digital file signatures for Windows Defender definition files ***
if "%VERIFY_DL%" NEQ "1" goto SkipWDDefs
if not exist %SIGCHK_PATH% goto NoSigCheck
echo Verifying digital file signatures for Windows Defender definition files...
for /F "skip=1 tokens=1 delims=," %%i in ('%SIGCHK_PATH% %SIGCHK_COPT% -s ..\client\wddefs\%TARGET_ARCH%-glb ^| %SystemRoot%\System32\findstr.exe /I /V "\"Signed\""') do (
  del "%%i"
  echo Warning: Deleted unsigned file %%i.
  call :Log "Warning: Deleted unsigned file '%%~i'"
)
call :Log "Info: Verified digital file signatures for Windows Defender definition files"
if not exist ..\client\bin\%HASHDEEP_EXE% goto NoHashDeep
echo Creating integrity database for Windows Defender definition files...
if not exist ..\client\md\nul md ..\client\md
..\client\bin\%HASHDEEP_EXE% -c md5,sha1,sha256 -b -r ..\client\wddefs\%TARGET_ARCH%-glb >..\client\md\hashes-wddefs-%TARGET_ARCH%-glb.txt
if errorlevel 1 (
  echo Warning: Error creating integrity database ..\client\md\hashes-wddefs-%TARGET_ARCH%-glb.txt.
  call :Log "Warning: Error creating integrity database ..\client\md\hashes-wddefs-%TARGET_ARCH%-glb.txt"
) else (
  call :Log "Info: Created integrity database for Windows Defender definition files"
)
for %%i in (..\client\md\hashes-wddefs-%TARGET_ARCH%-glb.txt) do if %%~zi==0 del %%i
:SkipWDDefs

rem *** Download the platform specific patches ***
if "%EXC_WINGLB%"=="1" goto SkipWinGlb
for %%i in (w60 w60-x64 w61 w61-x64 w62-x64 w63 w63-x64 w100 w100-x64) do (
  if /i "%1"=="%%i" (
    call :DownloadCore win glb x86 /skipdynamic
    if errorlevel 1 goto Error
  )
)
:SkipWinGlb
for %%i in (o2k13) do (
  if /i "%1"=="%%i" (
    call :DownloadCore %1 glb %TARGET_ARCH% %SKIP_PARAM%
    if errorlevel 1 goto Error
    call :DownloadCore %1 %2 %TARGET_ARCH% %SKIP_PARAM%
    if errorlevel 1 goto Error
  )
)
for %%i in (w60 w60-x64 w61 w61-x64 w62-x64 w63 w63-x64 w100 w100-x64 o2k16) do (
  if /i "%1"=="%%i" (
    call :DownloadCore %1 glb %TARGET_ARCH% %SKIP_PARAM%
    if errorlevel 1 goto Error
  )
)
goto RemindDate

:DownloadCore
rem %1 = platform (w60, w60-x64, w61, w61-x64, w62, w62-x64, w63, w63-x64, w100, w100-x64, win, o2k13, o2k16)
rem %2 = language
rem %3 = architecture (x86, x64)
rem %4 = "/skipdownload" / "/skipdynamic"
rem *** Determine update urls for %1 %2 ***
title %~n0 %1 %2 %3 %4 %5 %6 %7 %8 %9
echo.

if "%SECONLY%"=="1" (
  set SUSED_LIST=..\exclude\ExcludeList-superseded-seconly.txt
) else (
  set SUSED_LIST=..\exclude\ExcludeList-superseded.txt
)
if "%4"=="/skipdynamic" (
  echo Skipping unneeded determination of superseded updates.
  call :Log "Info: Skipped unneeded determination of superseded updates"
  goto SkipSuperseded
)
rem *** Extract Microsoft's update catalog file package.xml ***
echo Extracting Microsoft's update catalog file package.xml...
if exist "%TEMP%\package.cab" del "%TEMP%\package.cab"
if exist "%TEMP%\package.xml" del "%TEMP%\package.xml"
%SystemRoot%\System32\expand.exe ..\client\wsus\wsusscn2.cab -F:package.cab "%TEMP%" >nul
%SystemRoot%\System32\expand.exe "%TEMP%\package.cab" "%TEMP%\package.xml" >nul
del "%TEMP%\package.cab"
rem *** Determine superseded updates ***
if not exist ..\exclude\ExcludeList-superseded-seconly.txt (
  if exist ..\exclude\ExcludeList-superseded.txt del ..\exclude\ExcludeList-superseded.txt
)
if exist ..\exclude\ExcludeList-superseded.txt (
  %SystemRoot%\System32\find.exe /I "http://" ..\exclude\ExcludeList-superseded.txt >nul 2>&1
  if errorlevel 1 del ..\exclude\ExcludeList-superseded.txt
)
for %%i in (..\client\wsus\wsusscn2.cab) do echo %%~ai | %SystemRoot%\System32\find.exe /I "a" >nul 2>&1
if not errorlevel 1 (
  if exist ..\exclude\ExcludeList-superseded.txt del ..\exclude\ExcludeList-superseded.txt
)
if exist ..\exclude\ExcludeList-superseded.txt (
  echo Found valid list of superseded updates.
  call :Log "Info: Found valid list of superseded updates"
  goto SkipSuperseded
)
echo %TIME% - Determining superseded updates...

rem *** Step 0: Files used multiple times ***

rem echo Extracting revision-and-update-ids.txt...
%CSCRIPT_PATH% //Nologo //B //E:vbs XSLT.vbs "%TEMP%\package.xml" ..\xslt\extract-revision-and-update-ids.xsl "%TEMP%\revision-and-update-ids-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\revision-and-update-ids-unsorted.txt" > "%TEMP%\revision-and-update-ids.txt"
..\bin\gsort.exe -T "%TEMP%" -t "," -k 2 "%TEMP%\revision-and-update-ids-unsorted.txt" > "%TEMP%\revision-and-update-ids-inverted-unclean.txt"
%CSCRIPT_PATH% //Nologo //B //E:vbs ExtractUniqueFromSorted.vbs "%TEMP%\revision-and-update-ids-inverted-unclean.txt" "%TEMP%\revision-and-update-ids-inverted.txt"
del "%TEMP%\revision-and-update-ids-unsorted.txt"
del "%TEMP%\revision-and-update-ids-inverted-unclean.txt"

rem echo Extracting BundledUpdateRevisionAndFileIds.txt...
%CSCRIPT_PATH% //Nologo //B //E:vbs XSLT.vbs "%TEMP%\package.xml" ..\xslt\extract-update-revision-and-file-ids.xsl "%TEMP%\BundledUpdateRevisionAndFileIds-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\BundledUpdateRevisionAndFileIds-unsorted.txt" > "%TEMP%\BundledUpdateRevisionAndFileIds.txt"
del "%TEMP%\BundledUpdateRevisionAndFileIds-unsorted.txt"

rem echo Extracting UpdateCabExeIdsAndLocations.txt...
%CSCRIPT_PATH% //Nologo //B //E:vbs XSLT.vbs "%TEMP%\package.xml" ..\xslt\extract-update-cab-exe-ids-and-locations.xsl "%TEMP%\UpdateCabExeIdsAndLocations-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\UpdateCabExeIdsAndLocations-unsorted.txt" > "%TEMP%\UpdateCabExeIdsAndLocations.txt"
del "%TEMP%\UpdateCabExeIdsAndLocations-unsorted.txt"

rem echo Extracting existing-bundle-revision-ids.txt...
%CSCRIPT_PATH% //Nologo //B //E:vbs XSLT.vbs "%TEMP%\package.xml" ..\xslt\extract-existing-bundle-revision-ids.xsl "%TEMP%\existing-bundle-revision-ids-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\existing-bundle-revision-ids-unsorted.txt" >"%TEMP%\existing-bundle-revision-ids.txt"
del "%TEMP%\existing-bundle-revision-ids-unsorted.txt"

rem *** Step 1: extract RevisionIds from HideList-seconly.txt [target: revision-ids-HideList-seconly.txt] ***

if not exist ..\client\exclude\HideList-seconly.txt (
  rem echo Creating blank revision-ids-HideList-seconly.txt...
  echo. > "%TEMP%\revision-ids-HideList-seconly.txt"
  goto SkipHideList
)

rem echo Creating file-and-update-ids.txt...
..\bin\join.exe -t "," -o "2.3,1.2" "%TEMP%\revision-and-update-ids.txt" "%TEMP%\BundledUpdateRevisionAndFileIds.txt" > "%TEMP%\file-and-update-ids-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\file-and-update-ids-unsorted.txt" > "%TEMP%\file-and-update-ids.txt"
del "%TEMP%\file-and-update-ids-unsorted.txt"

rem echo Creating update-ids-and-locations.txt...
..\bin\join.exe -t "," -o "1.2,2.2" "%TEMP%\file-and-update-ids.txt" "%TEMP%\UpdateCabExeIdsAndLocations.txt" > "%TEMP%\update-ids-and-locations-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\update-ids-and-locations-unsorted.txt" > "%TEMP%\update-ids-and-locations.txt"
del "%TEMP%\update-ids-and-locations-unsorted.txt"

rem echo Creating UpdateTable-all.csv...
%CSCRIPT_PATH% //Nologo //B //E:vbs ExtractIdsAndFileNames.vbs "%TEMP%\update-ids-and-locations.txt" "%TEMP%\UpdateTable-all.csv"

rem echo Extracting HideList-seconly-KBNumbers.txt...
..\bin\cut.exe -d "," -f "1" ..\client\exclude\HideList-seconly.txt > "%TEMP%\HideList-seconly-KBNumbers.txt"

rem echo Creating UpdateTable-HideList-seconly.csv...
%SystemRoot%\System32\findstr.exe /L /I /G:"%TEMP%\HideList-seconly-KBNumbers.txt" "%TEMP%\UpdateTable-all.csv" > "%TEMP%\UpdateTable-HideList-seconly.csv"

rem echo Creating update-ids-HideList-seconly.txt...
..\bin\cut.exe -d "," -f "1" "%TEMP%\UpdateTable-HideList-seconly.csv" > "%TEMP%\update-ids-HideList-seconly-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\update-ids-HideList-seconly-unsorted.txt" > "%TEMP%\update-ids-HideList-seconly.txt"
del "%TEMP%\update-ids-HideList-seconly-unsorted.txt"

rem echo Creating revision-ids-HideList-seconly.txt...
..\bin\join.exe -t "," -1 2 -o "1.1" "%TEMP%\revision-and-update-ids-inverted.txt" "%TEMP%\update-ids-HideList-seconly.txt" > "%TEMP%\revision-ids-HideList-seconly-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\revision-ids-HideList-seconly-unsorted.txt" > "%TEMP%\revision-ids-HideList-seconly.txt"
del "%TEMP%\revision-ids-HideList-seconly-unsorted.txt"

del "%TEMP%\file-and-update-ids.txt"
del "%TEMP%\update-ids-and-locations.txt"
del "%TEMP%\HideList-seconly-KBNumbers.txt"
del "%TEMP%\UpdateTable-all.csv"
del "%TEMP%\UpdateTable-HideList-seconly.csv"
del "%TEMP%\update-ids-HideList-seconly.txt"

:SkipHideList

rem *** Step 2: Calculate the relations of the updates [target: ValidSupersededRevisionIds(-seconly).txt & ValidNonSupersededRevisionIds(-seconly).txt] ***

rem echo Extracting superseding-and-superseded-revision-ids.txt...
%CSCRIPT_PATH% //Nologo //B //E:vbs XSLT.vbs "%TEMP%\package.xml" ..\xslt\extract-superseding-and-superseded-revision-ids.xsl "%TEMP%\superseding-and-superseded-revision-ids-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\superseding-and-superseded-revision-ids-unsorted.txt" >"%TEMP%\superseding-and-superseded-revision-ids.txt"
del "%TEMP%\superseding-and-superseded-revision-ids-unsorted.txt"

rem echo Joining superseding-and-superseded-revision-ids.txt and revision-ids-HideList-seconly.txt to superseding-and-superseded-revision-ids-Rollups.txt...
..\bin\join.exe -1 1 -2 1 -t "," -o "1.1,1.2" "%TEMP%\superseding-and-superseded-revision-ids.txt" "%TEMP%\revision-ids-HideList-seconly.txt" > "%TEMP%\superseding-and-superseded-revision-ids-Rollups.txt"

rem echo Creating superseding-and-superseded-revision-ids-seconly.txt...
%SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\superseding-and-superseded-revision-ids-Rollups.txt" "%TEMP%\superseding-and-superseded-revision-ids.txt" > "%TEMP%\superseding-and-superseded-revision-ids-seconly.txt"

rem echo Joining existing-bundle-revision-ids.txt and superseding-and-superseded-revision-ids(-seconly).txt to ValidSupersededRevisionIds(-seconly).txt...
..\bin\join.exe -t "," -o "2.2" "%TEMP%\existing-bundle-revision-ids.txt" "%TEMP%\superseding-and-superseded-revision-ids.txt" >"%TEMP%\ValidSupersededRevisionIds-unsorted.txt"
..\bin\join.exe -t "," -o "2.2" "%TEMP%\existing-bundle-revision-ids.txt" "%TEMP%\superseding-and-superseded-revision-ids-seconly.txt" >"%TEMP%\ValidSupersededRevisionIds-seconly-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\ValidSupersededRevisionIds-unsorted.txt" >"%TEMP%\ValidSupersededRevisionIds.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\ValidSupersededRevisionIds-seconly-unsorted.txt" >"%TEMP%\ValidSupersededRevisionIds-seconly.txt"
del "%TEMP%\ValidSupersededRevisionIds-unsorted.txt"
del "%TEMP%\ValidSupersededRevisionIds-seconly-unsorted.txt"

rem echo Creating ValidNonSupersededRevisionIds(-seconly).txt...
%SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\ValidSupersededRevisionIds.txt" "%TEMP%\existing-bundle-revision-ids.txt" > "%TEMP%\ValidNonSupersededRevisionIds-unsorted.txt"
%SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\ValidSupersededRevisionIds-seconly.txt" "%TEMP%\existing-bundle-revision-ids.txt" > "%TEMP%\ValidNonSupersededRevisionIds-seconly-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\ValidNonSupersededRevisionIds-unsorted.txt" >"%TEMP%\ValidNonSupersededRevisionIds.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\ValidNonSupersededRevisionIds-seconly-unsorted.txt" >"%TEMP%\ValidNonSupersededRevisionIds-seconly.txt"
del "%TEMP%\ValidNonSupersededRevisionIds-unsorted.txt"
del "%TEMP%\ValidNonSupersededRevisionIds-seconly-unsorted.txt"

del "%TEMP%\revision-ids-HideList-seconly.txt"
del "%TEMP%\superseding-and-superseded-revision-ids-Rollups.txt"
del "%TEMP%\superseding-and-superseded-revision-ids.txt"
del "%TEMP%\superseding-and-superseded-revision-ids-seconly.txt"

rem *** Step 3: Get the FileIds for the RevisionIds [target: OnlySupersededFileIds(-seconly).txt] ***

rem echo Joining ValidSupersededRevisionIds(-seconly).txt and BundledUpdateRevisionAndFileIds.txt to SupersededFileIds(-seconly).txt...
..\bin\join.exe -t "," -o "2.3" "%TEMP%\ValidSupersededRevisionIds.txt" "%TEMP%\BundledUpdateRevisionAndFileIds.txt" >"%TEMP%\SupersededFileIds-unsorted.txt"
..\bin\join.exe -t "," -o "2.3" "%TEMP%\ValidSupersededRevisionIds-seconly.txt" "%TEMP%\BundledUpdateRevisionAndFileIds.txt" >"%TEMP%\SupersededFileIds-seconly-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\SupersededFileIds-unsorted.txt" >"%TEMP%\SupersededFileIds.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\SupersededFileIds-seconly-unsorted.txt" >"%TEMP%\SupersededFileIds-seconly.txt"
del "%TEMP%\SupersededFileIds-unsorted.txt"
del "%TEMP%\SupersededFileIds-seconly-unsorted.txt"

rem echo Joining ValidNonSupersededRevisionIds(-seconly).txt and BundledUpdateRevisionAndFileIds.txt to NonSupersededFileIds(-seconly).txt...
..\bin\join.exe -t "," -o "2.3" "%TEMP%\ValidNonSupersededRevisionIds.txt" "%TEMP%\BundledUpdateRevisionAndFileIds.txt" >"%TEMP%\NonSupersededFileIds-unsorted.txt"
..\bin\join.exe -t "," -o "2.3" "%TEMP%\ValidNonSupersededRevisionIds-seconly.txt" "%TEMP%\BundledUpdateRevisionAndFileIds.txt" >"%TEMP%\NonSupersededFileIds-seconly-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\NonSupersededFileIds-unsorted.txt" >"%TEMP%\NonSupersededFileIds.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\NonSupersededFileIds-seconly-unsorted.txt" >"%TEMP%\NonSupersededFileIds-seconly.txt"
del "%TEMP%\NonSupersededFileIds-unsorted.txt"
del "%TEMP%\NonSupersededFileIds-seconly-unsorted.txt"

rem echo Creating OnlySupersededFileIds(-seconly).txt...
%SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\NonSupersededFileIds.txt" "%TEMP%\SupersededFileIds.txt" >"%TEMP%\OnlySupersededFileIds-unsorted.txt"
%SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\NonSupersededFileIds-seconly.txt" "%TEMP%\SupersededFileIds-seconly.txt" >"%TEMP%\OnlySupersededFileIds-seconly-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\OnlySupersededFileIds-unsorted.txt" >"%TEMP%\OnlySupersededFileIds.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\OnlySupersededFileIds-seconly-unsorted.txt" >"%TEMP%\OnlySupersededFileIds-seconly.txt"
del "%TEMP%\OnlySupersededFileIds-unsorted.txt"
del "%TEMP%\OnlySupersededFileIds-seconly-unsorted.txt"

del "%TEMP%\ValidSupersededRevisionIds.txt"
del "%TEMP%\ValidSupersededRevisionIds-seconly.txt"
del "%TEMP%\ValidNonSupersededRevisionIds.txt"
del "%TEMP%\ValidNonSupersededRevisionIds-seconly.txt"
del "%TEMP%\NonSupersededFileIds.txt"
del "%TEMP%\NonSupersededFileIds-seconly.txt"
del "%TEMP%\SupersededFileIds.txt"
del "%TEMP%\SupersededFileIds-seconly.txt"

rem *** Step 4: Get the URLs for the FileIds [target: ExcludeList-superseded-all(-seconly).txt] ***

rem echo Joining OnlySupersededFileIds(-seconly).txt and UpdateCabExeIdsAndLocations.txt to ExcludeList-superseded-all(-seconly).txt...
..\bin\join.exe -t "," -o "2.2" "%TEMP%\OnlySupersededFileIds.txt" "%TEMP%\UpdateCabExeIdsAndLocations.txt" >"%TEMP%\ExcludeList-superseded-all-unsorted.txt"
..\bin\join.exe -t "," -o "2.2" "%TEMP%\OnlySupersededFileIds-seconly.txt" "%TEMP%\UpdateCabExeIdsAndLocations.txt" >"%TEMP%\ExcludeList-superseded-all-seconly-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\ExcludeList-superseded-all-unsorted.txt" >"%TEMP%\ExcludeList-superseded-all.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\ExcludeList-superseded-all-seconly-unsorted.txt" >"%TEMP%\ExcludeList-superseded-all-seconly.txt"
del "%TEMP%\ExcludeList-superseded-all-unsorted.txt"
del "%TEMP%\ExcludeList-superseded-all-seconly-unsorted.txt"

del "%TEMP%\OnlySupersededFileIds.txt"
del "%TEMP%\OnlySupersededFileIds-seconly.txt"

rem *** Cleanup ***

del "%TEMP%\revision-and-update-ids.txt"
del "%TEMP%\revision-and-update-ids-inverted.txt"
del "%TEMP%\BundledUpdateRevisionAndFileIds.txt"
del "%TEMP%\UpdateCabExeIdsAndLocations.txt"
del "%TEMP%\existing-bundle-revision-ids.txt"

rem *** Step 5: Apply ExcludeList-superseded-exclude(-seconly).txt [target: ExcludeList-superseded(-seconly).txt] ***

if exist ..\exclude\ExcludeList-superseded-exclude.txt copy /Y ..\exclude\ExcludeList-superseded-exclude.txt "%TEMP%\ExcludeList-superseded-exclude.txt" >nul
if exist ..\exclude\ExcludeList-superseded-exclude.txt copy /Y ..\exclude\ExcludeList-superseded-exclude.txt "%TEMP%\ExcludeList-superseded-exclude-seconly.txt" >nul
if exist ..\exclude\custom\ExcludeList-superseded-exclude.txt (
  type ..\exclude\custom\ExcludeList-superseded-exclude.txt >>"%TEMP%\ExcludeList-superseded-exclude.txt"
  type ..\exclude\custom\ExcludeList-superseded-exclude.txt >>"%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
)
for %%i in (upd1 upd2) do (
  for /F %%j in ('type ..\client\static\StaticUpdateIds-w63-%%i.txt ^| find /i "kb"') do (
    echo windows8.1-%%j>>"%TEMP%\ExcludeList-superseded-exclude.txt"
    echo windows8.1-%%j>>"%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
  )
)
if exist ..\exclude\ExcludeList-superseded-exclude-seconly.txt (
  type ..\exclude\ExcludeList-superseded-exclude-seconly.txt >>"%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
)
if exist ..\exclude\custom\ExcludeList-superseded-exclude-seconly.txt (
  type ..\exclude\custom\ExcludeList-superseded-exclude-seconly.txt >>"%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
)
for %%i in (w62 w63) do (
  for /F %%j in ('dir /B ..\client\static\StaticUpdateIds-%%i*-seconly.txt 2^>nul') do (
    for /F "tokens=1* delims=,;" %%k in (..\client\static\%%j) do (
      echo %%k>>"%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
    )
  )
  for /F %%j in ('dir /B ..\client\static\custom\StaticUpdateIds-%%i*-seconly.txt 2^>nul') do (
    for /F "tokens=1* delims=,;" %%k in (..\client\static\custom\%%j) do (
      echo %%k>>"%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
    )
  )
)
for %%i in ("%TEMP%\ExcludeList-superseded-exclude.txt") do if %%~zi==0 del %%i
for %%i in ("%TEMP%\ExcludeList-superseded-exclude-seconly.txt") do if %%~zi==0 del %%i
if exist "%TEMP%\ExcludeList-superseded-exclude.txt" (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\ExcludeList-superseded-exclude.txt" "%TEMP%\ExcludeList-superseded-all.txt" >..\exclude\ExcludeList-superseded.txt
  del "%TEMP%\ExcludeList-superseded-exclude.txt"
) else (
  copy /Y "%TEMP%\ExcludeList-superseded-all.txt" ..\exclude\ExcludeList-superseded.txt >nul
)
if exist "%TEMP%\ExcludeList-superseded-exclude-seconly.txt" (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\ExcludeList-superseded-exclude-seconly.txt" "%TEMP%\ExcludeList-superseded-all-seconly.txt" >..\exclude\ExcludeList-superseded-seconly.txt
  del "%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
) else (
  copy /Y "%TEMP%\ExcludeList-superseded-all-seconly.txt" ..\exclude\ExcludeList-superseded-seconly.txt >nul
)

del "%TEMP%\ExcludeList-superseded-all.txt"
del "%TEMP%\ExcludeList-superseded-all-seconly.txt"

%SystemRoot%\System32\attrib.exe -A ..\client\wsus\wsusscn2.cab

echo %TIME% - Done.
call :Log "Info: Determined superseded updates"
:SkipSuperseded

rem *** Verify integrity of existing updates for %1 %2 ***
if "%4"=="/skipdownload" goto SkipStatics
if "%VERIFY_DL%" NEQ "1" goto SkipAudit
if not exist ..\client\%1\%2\nul goto SkipAudit
if not exist ..\client\bin\%HASHDEEP_EXE% goto NoHashDeep
if exist ..\client\md\hashes-%1-%2.txt (
  echo Verifying integrity of existing updates for %1 %2...
  ..\client\bin\%HASHDEEP_EXE% -a -b -vv -k ..\client\md\hashes-%1-%2.txt -r ..\client\%1\%2
  if errorlevel 1 (
    goto IntegrityError
  )
  call :Log "Info: Verified integrity of existing updates for %1 %2"
  for %%i in (..\client\md\hashes-%1-%2.txt) do echo _%%~ti | %SystemRoot%\System32\find.exe "_%DATE:~-10%" >nul 2>&1
  if not errorlevel 1 (
    if exist %SUSED_LIST% (
      for %%i in (%SUSED_LIST%) do echo _%%~ti | %SystemRoot%\System32\find.exe "_%DATE:~-10%" >nul 2>&1
      if errorlevel 1 (
        echo Skipping download/validation of %1 %2 due to 'same day' rule.
        call :Log "Info: Skipped download/validation of %1 %2 due to 'same day' rule"
        verify >nul
        goto :eof
      )
    )
  )
) else (
  echo Warning: Integrity database ..\client\md\hashes-%1-%2.txt not found.
  call :Log "Warning: Integrity database ..\client\md\hashes-%1-%2.txt not found"
)
:SkipAudit
if exist ..\client\md\hashes-%1-%2.txt del ..\client\md\hashes-%1-%2.txt

rem *** Determine static update urls for %1 %2 ***
if "%EXC_STATICS%"=="1" goto SkipStatics
echo Determining static update urls for %1 %2...
if exist ..\static\StaticDownloadLinks-%1-%2.txt copy /Y ..\static\StaticDownloadLinks-%1-%2.txt "%TEMP%\StaticDownloadLinks-%1-%2.txt" >nul
if exist ..\static\StaticDownloadLinks-%1-%3-%2.txt copy /Y ..\static\StaticDownloadLinks-%1-%3-%2.txt "%TEMP%\StaticDownloadLinks-%1-%2.txt" >nul
if exist ..\static\custom\StaticDownloadLinks-%1-%2.txt (
  type ..\static\custom\StaticDownloadLinks-%1-%2.txt >>"%TEMP%\StaticDownloadLinks-%1-%2.txt"
)
if exist ..\static\custom\StaticDownloadLinks-%1-%3-%2.txt (
  type ..\static\custom\StaticDownloadLinks-%1-%3-%2.txt >>"%TEMP%\StaticDownloadLinks-%1-%2.txt"
)
if not exist "%TEMP%\StaticDownloadLinks-%1-%2.txt" goto SkipStatics

:EvalStatics
if exist "%TEMP%\ExcludeListStatic.txt" del "%TEMP%\ExcludeListStatic.txt"
if exist ..\exclude\custom\ExcludeListForce-all.txt copy /Y ..\exclude\custom\ExcludeListForce-all.txt "%TEMP%\ExcludeListStatic.txt" >nul
if "%EXC_SP%"=="1" (
  type ..\exclude\ExcludeList-SPs.txt >>"%TEMP%\ExcludeListStatic.txt"
  type "..\client\static\StaticUpdateIds-w63-upd1.txt" >>"%TEMP%\ExcludeListStatic.txt"
  type "..\client\static\StaticUpdateIds-w63-upd2.txt" >>"%TEMP%\ExcludeListStatic.txt"
)
if exist "%TEMP%\ExcludeListStatic.txt" (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\ExcludeListStatic.txt" "%TEMP%\StaticDownloadLinks-%1-%2.txt" >"%TEMP%\ValidStaticLinks-%1-%2.txt"
  del "%TEMP%\ExcludeListStatic.txt"
  del "%TEMP%\StaticDownloadLinks-%1-%2.txt"
) else (
  if exist "%TEMP%\ValidStaticLinks-%1-%2.txt" del "%TEMP%\ValidStaticLinks-%1-%2.txt"
  ren "%TEMP%\StaticDownloadLinks-%1-%2.txt" ValidStaticLinks-%1-%2.txt
)
call :Log "Info: Determined static update urls for %1 %2"

:SkipStatics
if "%4"=="/skipdynamic" (
  echo Skipping determination of dynamic update urls for %1 %2 on demand.
  call :Log "Info: Skipped determination of dynamic update urls for %1 %2 on demand"
  goto DoDownload
)
if not exist ..\client\UpdateTable\nul md ..\client\UpdateTable

set PLATFORM_WINDOWS=w60 w61 w62 w63 w100
set PLATFORM_OFFICE=o2k13 o2k16

rem *** Determine dynamic update urls for %1 %2 ***
echo %TIME% - Determining dynamic update urls for %1 %2...
call :Log "Info: Determining dynamic update URLs for %1 %2 ..."

set TMP_PLATFORM=%1
if "%TMP_PLATFORM:~-4%"=="-x64" (
  set TMP_PLATFORM=%TMP_PLATFORM:~0,-4%
)

if not exist ..\xslt\extract-revision-and-update-ids-%TMP_PLATFORM%.xsl (
  if exist "%TEMP%\package.xml" del "%TEMP%\package.xml"
  goto DoDownload
)

rem The file update-ids-and-locations.txt lists all
rem UpdateIds (in the form of UUIDs) and their locations, before
rem splitting the file into global and localized updates or applying any
rem exclude lists. This file only depends on the WSUS offline scan file
rem wsusscn2.cab. If it already exists, it can be reused again. It will
rem be deleted at the end of the script.
rem
rem TODO: Such tricks work great for the Linux download scripts, but
rem not for the Windows script.
rem echo Extracting revision-and-update-ids.txt ...
call :Log "Info: Extracting revision-and-update-ids.txt ..."
%CSCRIPT_PATH% //Nologo //B //E:vbs XSLT.vbs "%TEMP%\package.xml" ..\xslt\extract-revision-and-update-ids-%TMP_PLATFORM%.xsl "%TEMP%\revision-and-update-ids-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\revision-and-update-ids-unsorted.txt" > "%TEMP%\revision-and-update-ids.txt"
del "%TEMP%\revision-and-update-ids-unsorted.txt"

rem echo Extracting BundledUpdateRevisionAndFileIds.txt ...
call :Log "Info: Extracting BundledUpdateRevisionAndFileIds.txt ..."
%CSCRIPT_PATH% //Nologo //B //E:vbs XSLT.vbs "%TEMP%\package.xml" ..\xslt\extract-update-revision-and-file-ids.xsl "%TEMP%\BundledUpdateRevisionAndFileIds-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\BundledUpdateRevisionAndFileIds-unsorted.txt" > "%TEMP%\BundledUpdateRevisionAndFileIds.txt"
del "%TEMP%\BundledUpdateRevisionAndFileIds-unsorted.txt"

rem echo Extracting UpdateCabExeIdsAndLocations.txt ...
call :Log "Info: Extracting UpdateCabExeIdsAndLocations.txt ..."
%CSCRIPT_PATH% //Nologo //B //E:vbs XSLT.vbs "%TEMP%\package.xml" ..\xslt\extract-update-cab-exe-ids-and-locations.xsl "%TEMP%\UpdateCabExeIdsAndLocations-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\UpdateCabExeIdsAndLocations-unsorted.txt" > "%TEMP%\UpdateCabExeIdsAndLocations.txt"
del "%TEMP%\UpdateCabExeIdsAndLocations-unsorted.txt"

if exist "%TEMP%\package.xml" del "%TEMP%\package.xml"

rem Join the first two files to get the FileIds. The UpdateId of the
rem bundle record is copied, because it is needed later for the files
rem UpdateTable-*-*.csv.
rem
rem Input file 1: revision-and-update-ids.txt
rem - Field 1: RevisionId of the bundle record
rem - Field 2: UpdateId of the bundle record
rem Input file 2: BundledUpdateRevisionAndFileIds.txt
rem - Field 1: RevisionId of the parent bundle record
rem - Field 2: RevisionId of the update record for the PayloadFile
rem - Field 3: FileId of the PayloadFile
rem Output file: file-and-update-ids.txt
rem - Field 1: FileId of the PayloadFile
rem - Field 2: UpdateId of the bundle record
rem echo Creating file-and-update-ids.txt ...
call :Log "Info: Creating file-and-update-ids.txt ..."
..\bin\join.exe -t "," -o "2.3,1.2" "%TEMP%\revision-and-update-ids.txt" "%TEMP%\BundledUpdateRevisionAndFileIds.txt" > "%TEMP%\file-and-update-ids-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\file-and-update-ids-unsorted.txt" > "%TEMP%\file-and-update-ids.txt"
del "%TEMP%\BundledUpdateRevisionAndFileIds.txt"
del "%TEMP%\revision-and-update-ids.txt"
del "%TEMP%\file-and-update-ids-unsorted.txt"

rem Join with third file to get the FileLocations (URLs)
rem
rem Input file 1: file-and-update-ids.txt
rem - Field 1: FileId of the PayloadFile
rem - Field 2: UpdateId of the bundle record
rem Input file 2: UpdateCabExeIdsAndLocations.txt
rem - Field 1: FileId of the PayloadFile
rem - Field 2: Location (URL)
rem Output file: update-ids-and-locations.txt
rem - Field 1: UpdateId of the bundle record
rem - Field 2: Location (URL)
rem echo Creating update-ids-and-locations.txt ...
call :Log "Info: Creating update-ids-and-locations.txt ..."
..\bin\join.exe -t "," -o "1.2,2.2" "%TEMP%\file-and-update-ids.txt" "%TEMP%\UpdateCabExeIdsAndLocations.txt" > "%TEMP%\update-ids-and-locations-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\update-ids-and-locations-unsorted.txt" > "%TEMP%\update-ids-and-locations.txt"
del "%TEMP%\file-and-update-ids.txt"
del "%TEMP%\update-ids-and-locations-unsorted.txt"
del "%TEMP%\UpdateCabExeIdsAndLocations.txt"

rem Filtering differs between Windows and Office
rem echo Creating update-ids-and-locations-%2.txt ...
call :Log "Info: Creating update-ids-and-locations-%2.txt ..."
for %%i in (%PLATFORM_WINDOWS%) do (if /i "%TMP_PLATFORM%"=="%%i" goto DetermineWindows)
for %%i in (%PLATFORM_OFFICE%) do (if /i "%TMP_PLATFORM%"=="%%i" goto DetermineOffice)
goto DoDownload

:DetermineWindows
type "%TEMP%\update-ids-and-locations.txt" > "%TEMP%\update-ids-and-locations-%2.txt"
del "%TEMP%\update-ids-and-locations.txt"
goto DetermineShared

:DetermineOffice
rem Separate the updates into global and localized versions
if "%2"=="glb" (
  rem Remove all localized files to get the global/multilingual updates
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"..\exclude\ExcludeList-locales.txt" "%TEMP%\update-ids-and-locations.txt" > "%TEMP%\update-ids-and-locations-%2.txt"
) else (
  rem Extract localized files using search strings like "-en-us_"
  %SystemRoot%\System32\findstr.exe /L /I /C:"-%LOCALE_LONG%_" "%TEMP%\update-ids-and-locations.txt" > "%TEMP%\update-ids-and-locations-%2.txt"
)
del "%TEMP%\update-ids-and-locations.txt"
goto DetermineShared

:DetermineShared
rem Create the files ../client/UpdateTable/UpdateTable-*-*.csv, which are
rem needed during the installation of the updates. They link the UpdateIds
rem (in form of UUIDs) to the file names.
rem echo Creating UpdateTable-%TMP_PLATFORM%-%2.csv ...
call :Log "Info: Creating UpdateTable-%TMP_PLATFORM%-%2.csv ..."
%CSCRIPT_PATH% //Nologo //B //E:vbs ExtractIdsAndFileNames.vbs "%TEMP%\update-ids-and-locations-%2.txt" ..\client\UpdateTable\UpdateTable-%TMP_PLATFORM%-%2.csv

rem At this point, the UpdateIds are no longer needed. Only the locations
rem (URLs) are needed to create the initial list of dynamic download
rem links.
rem echo Creating DynamicDownloadLinks-%1-%2.txt ...
call :Log "Info: Creating DynamicDownloadLinks-%1-%2.txt ..."
..\bin\cut.exe -d "," -f "2" "%TEMP%\update-ids-and-locations-%2.txt" > "%TEMP%\DynamicDownloadLinks-%1-%2-unsorted.txt"
..\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\DynamicDownloadLinks-%1-%2-unsorted.txt" > "%TEMP%\DynamicDownloadLinks-%1-%2.txt"
del "%TEMP%\update-ids-and-locations-%2.txt"
del "%TEMP%\DynamicDownloadLinks-%1-%2-unsorted.txt"

rem Remove the superseded updates to get a list of current dynamic
rem download links
rem echo Creating CurrentDynamicLinks-%1-%2.txt ...
call :Log "Info: Creating CurrentDynamicLinks-%1-%2.txt ..."
if exist %SUSED_LIST% (
  rem join -v1 does a "left join" and returns only lines or records,
  rem which are unique on the left side
  ..\bin\join.exe -v1 "%TEMP%\DynamicDownloadLinks-%1-%2.txt" %SUSED_LIST% > "%TEMP%\CurrentDynamicLinks-%1-%2.txt"
  del "%TEMP%\DynamicDownloadLinks-%1-%2.txt"
) else (
  move /Y "%TEMP%\DynamicDownloadLinks-%1-%2.txt" "%TEMP%\CurrentDynamicLinks-%1-%2.txt" >nul
)

rem Apply the remaining exclude lists, which typically contain kb numbers
rem only, to get the final list of valid dynamic download links
rem echo Creating ValidDynamicLinks-%1-%2.txt ...
call :Log "Info: Creating ValidDynamicLinks-%1-%2.txt ..."
if exist "%TEMP%\ExcludeList-%1.txt" del "%TEMP%\ExcludeList-%1.txt"
if exist ..\exclude\ExcludeList-%TMP_PLATFORM%.txt (
  type ..\exclude\ExcludeList-%TMP_PLATFORM%.txt >>"%TEMP%\ExcludeList-%1.txt"
  if exist ..\exclude\custom\ExcludeList-%TMP_PLATFORM%.txt type ..\exclude\custom\ExcludeList-%TMP_PLATFORM%.txt >>"%TEMP%\ExcludeList-%1.txt"
)
if exist ..\exclude\ExcludeList-%TMP_PLATFORM%-%3.txt (
  type ..\exclude\ExcludeList-%TMP_PLATFORM%-%3.txt >> "%TEMP%\ExcludeList-%1.txt"
  if exist ..\exclude\custom\ExcludeList-%TMP_PLATFORM%-%3.txt type ..\exclude\custom\ExcludeList-%TMP_PLATFORM%-%3.txt >>"%TEMP%\ExcludeList-%1.txt"
)
if exist ..\exclude\ExcludeList-%TMP_PLATFORM%-%2.txt (
  type ..\exclude\ExcludeList-%TMP_PLATFORM%-%2.txt >>"%TEMP%\ExcludeList-%1.txt"
  if exist ..\exclude\custom\ExcludeList-%TMP_PLATFORM%-%2.txt type ..\exclude\custom\ExcludeList-%TMP_PLATFORM%-%2.txt >>"%TEMP%\ExcludeList-%1.txt"
)
if exist ..\exclude\ExcludeList-%TMP_PLATFORM%-%3-%2.txt (
  type ..\exclude\ExcludeList-%TMP_PLATFORM%-%3-%2.txt >> "%TEMP%\ExcludeList-%1.txt"
  if exist ..\exclude\custom\ExcludeList-%TMP_PLATFORM%-%3-%2.txt type ..\exclude\custom\ExcludeList-%TMP_PLATFORM%-%3-%2.txt >>"%TEMP%\ExcludeList-%1.txt"
)
if not "%2"=="glb" (
  if exist ..\exclude\ExcludeList-%TMP_PLATFORM%-lng.txt (
    type ..\exclude\ExcludeList-%TMP_PLATFORM%-lng.txt >>"%TEMP%\ExcludeList-%1.txt"
    if exist ..\exclude\custom\ExcludeList-%TMP_PLATFORM%-lng.txt type ..\exclude\custom\ExcludeList-%TMP_PLATFORM%-lng.txt >>"%TEMP%\ExcludeList-%1.txt"
  )
  if exist ..\exclude\ExcludeList-%TMP_PLATFORM%-%3-lng.txt (
    type ..\exclude\ExcludeList-%TMP_PLATFORM%-%3-lng.txt >> "%TEMP%\ExcludeList-%1.txt"
    if exist ..\exclude\custom\ExcludeList-%TMP_PLATFORM%-%3-lng.txt type ..\exclude\custom\ExcludeList-%TMP_PLATFORM%-%3-lng.txt >>"%TEMP%\ExcludeList-%1.txt"
  )
)

if "%EXC_SP%"=="1" (
  type ..\exclude\ExcludeList-SPs.txt >>"%TEMP%\ExcludeList-%1.txt"
  type ..\client\static\StaticUpdateIds-w63-upd1.txt >>"%TEMP%\ExcludeList-%1.txt"
  type ..\client\static\StaticUpdateIds-w63-upd2.txt >>"%TEMP%\ExcludeList-%1.txt"
)

for %%i in (%PLATFORM_WINDOWS%) do (if /i "%TMP_PLATFORM%"=="%%i" goto DetermineWindowsSpecificExclude)
goto SkipDetermineWindowsSpecificExclude

:DetermineWindowsSpecificExclude
if "%SECONLY%"=="1" (
  if exist ..\client\exclude\HideList-seconly.txt (
    for /F "tokens=1* delims=,;" %%i in (..\client\exclude\HideList-seconly.txt) do (
      echo %%i>>"%TEMP%\ExcludeList-%1.txt"
    )
  )
  if exist ..\client\exclude\custom\HideList-seconly.txt (
    for /F "tokens=1* delims=,;" %%i in (..\client\exclude\custom\HideList-seconly.txt) do (
      echo %%i>>"%TEMP%\ExcludeList-%1.txt"
    )
  )
)
rem exclude other architectures
if exist ..\exclude\ExcludeList-%3.txt type ..\exclude\ExcludeList-%3.txt >> "%TEMP%\ExcludeList-%1.txt"
:SkipDetermineWindowsSpecificExclude

for %%i in (%PLATFORM_OFFICE%) do (if /i "%TMP_PLATFORM%"=="%%i" goto DetermineOfficeSpecificExclude)
goto SkipDetermineOfficeSpecificExclude

:DetermineOfficeSpecificExclude
if exist ..\exclude\ExcludeList-ofc.txt (
  type ..\exclude\ExcludeList-ofc.txt >>"%TEMP%\ExcludeList-%1.txt"
  if exist ..\exclude\custom\ExcludeList-ofc.txt type ..\exclude\custom\ExcludeList-ofc.txt >>"%TEMP%\ExcludeList-%1.txt"
)
if not "%2"=="glb" (
  if exist ..\exclude\ExcludeList-ofc-lng.txt type ..\exclude\ExcludeList-ofc-lng.txt >>"%TEMP%\ExcludeList-%1.txt"
  if exist ..\exclude\custom\ExcludeList-ofc-lng.txt type ..\exclude\custom\ExcludeList-ofc-lng.txt >>"%TEMP%\ExcludeList-%1.txt"
)
if exist ..\exclude\ExcludeList-ofc-%2.txt (
  type ..\exclude\ExcludeList-ofc-%2.txt >>"%TEMP%\ExcludeList-%1.txt"
  if exist ..\exclude\custom\ExcludeList-ofc-%2.txt type ..\exclude\custom\ExcludeList-ofc-%2.txt >>"%TEMP%\ExcludeList-%1.txt"
)
:SkipDetermineOfficeSpecificExclude

if exist ..\exclude\custom\ExcludeListForce-all.txt (
  type ..\exclude\custom\ExcludeListForce-all.txt >>"%TEMP%\ExcludeList-%1.txt"
)

for %%i in ("%TEMP%\ExcludeList-%1.txt") do if %%~zi==0 del %%i
if exist "%TEMP%\ExcludeList-%1.txt" (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\ExcludeList-%1.txt" "%TEMP%\CurrentDynamicLinks-%1-%2.txt" >"%TEMP%\ValidDynamicLinks-%1-%2.txt"
  del "%TEMP%\CurrentDynamicLinks-%1-%2.txt"
  del "%TEMP%\ExcludeList-%1.txt"
) else (
  move /Y "%TEMP%\CurrentDynamicLinks-%1-%2.txt" "%TEMP%\ValidDynamicLinks-%1-%2.txt" >nul
)
echo %TIME% - Done.
call :Log "Info: Determined dynamic update urls for %1 %2"

:DoDownload
rem *** Download updates for %1 %2 ***
if "%4"=="/skipdownload" (
  echo Skipping download/validation of updates for %1 %2 on demand.
  call :Log "Info: Skipped download/validation of updates for %1 %2 on demand"
  goto EndDownload
)
if not exist ..\client\%1\%2\nul md ..\client\%1\%2
if not exist "%TEMP%\ValidStaticLinks-%1-%2.txt" goto DownloadDynamicUpdates
echo Downloading/validating statically defined updates for %1 %2...
set LINES_COUNT=0
for /F "tokens=1* delims=:" %%i in ('%SystemRoot%\System32\findstr.exe /N $ "%TEMP%\ValidStaticLinks-%1-%2.txt"') do set LINES_COUNT=%%i
for /F "tokens=1* delims=:" %%i in ('%SystemRoot%\System32\findstr.exe /N $ "%TEMP%\ValidStaticLinks-%1-%2.txt"') do (
  echo Downloading/validating update %%i of %LINES_COUNT%...
  for /F "tokens=1,2 delims=," %%k in ("%%j") do (
    if "%%l" NEQ "" (
      if exist "..\client\%1\%2\%%l" (
        echo Renaming file ..\client\%1\%2\%%l to %%~nxk...
        ren "..\client\%1\%2\%%l" "%%~nxk"
        call :Log "Info: Renamed file ..\client\%1\%2\%%l to %%~nxk"
      )
    )
    %DLDR_PATH% %DLDR_COPT% %DLDR_UOPT% %DLDR_POPT% ..\client\%1\%2 "%%k"
    if errorlevel 1 (
      if exist "..\client\%1\%2\%%~nxk" del "..\client\%1\%2\%%~nxk"
      echo Warning: Download of %%k failed.
      call :Log "Warning: Download of %%k failed"
    ) else (
      call :Log "Info: Downloaded/validated %%k to ..\client\%1\%2"
    )
    if "%%l" NEQ "" (
      if exist "..\client\%1\%2\%%~nxk" (
        echo Renaming file ..\client\%1\%2\%%~nxk to %%l...
        ren "..\client\%1\%2\%%~nxk" "%%l"
        call :Log "Info: Renamed file ..\client\%1\%2\%%~nxk to %%l"
      )
    )
  )
)
call :Log "Info: Downloaded/validated %LINES_COUNT% statically defined updates for %1 %2"

:DownloadDynamicUpdates
if not exist "%TEMP%\ValidDynamicLinks-%1-%2.txt" goto CleanupDownload
echo Downloading/validating dynamically determined updates for %1 %2...
set LINES_COUNT=0
for /F "tokens=1* delims=:" %%i in ('%SystemRoot%\System32\findstr.exe /N $ "%TEMP%\ValidDynamicLinks-%1-%2.txt"') do set LINES_COUNT=%%i
if "%WSUS_URL%"=="" (
  for /F "tokens=1* delims=:" %%i in ('%SystemRoot%\System32\findstr.exe /N $ "%TEMP%\ValidDynamicLinks-%1-%2.txt"') do (
    echo Downloading/validating update %%i of %LINES_COUNT%...
    %DLDR_PATH% %DLDR_COPT% %DLDR_POPT% ..\client\%1\%2 "%%j"
    if errorlevel 1 (
      echo Warning: Download of %%j failed.
      call :Log "Warning: Download of %%j failed"
    ) else (
      call :Log "Info: Downloaded/validated %%j to ..\client\%1\%2"
    )
  )
) else (
  echo Creating WSUS download table for %1 %2...
  %CSCRIPT_PATH% //Nologo //B //E:vbs CreateDownloadTable.vbs "%TEMP%\ValidDynamicLinks-%1-%2.txt" %WSUS_URL%
  if errorlevel 1 goto DownloadError
  call :Log "Info: Created WSUS download table for %1 %2"
  for /F "tokens=1* delims=:" %%i in ('%SystemRoot%\System32\findstr.exe /N $ "%TEMP%\ValidDynamicLinks-%1-%2.csv"') do (
    echo Downloading/validating update %%i of %LINES_COUNT%...
    for /F "tokens=1-3 delims=," %%k in ("%%j") do (
      if "%%m"=="" (
        %DLDR_PATH% %DLDR_COPT% %DLDR_POPT% ..\client\%1\%2 "%%l"
        if errorlevel 1 (
          echo Warning: Download of %%l failed.
          call :Log "Warning: Download of %%l failed"
        ) else (
          call :Log "Info: Downloaded/validated %%l to ..\client\%1\%2"
        )
      ) else (
        if exist "..\client\%1\%2\%%k" (
          echo Renaming file ..\client\%1\%2\%%k to %%~nxl...
          ren "..\client\%1\%2\%%k" "%%~nxl"
          call :Log "Info: Renamed file ..\client\%1\%2\%%k to %%~nxl"
        )
        if "%WSUS_BY_PROXY%"=="1" (
          %DLDR_PATH% %DLDR_COPT% %DLDR_NVOPT% %DLDR_POPT% ..\client\%1\%2 %DLDR_LOPT% "%%l"
        ) else (
          %DLDR_PATH% %DLDR_COPT% %DLDR_NVOPT% --no-proxy %DLDR_POPT% ..\client\%1\%2 %DLDR_LOPT% "%%l"
        )
        if errorlevel 1 (
          if exist "..\client\%1\%2\%%~nxl" (
            echo Renaming file ..\client\%1\%2\%%~nxl to %%k...
            ren "..\client\%1\%2\%%~nxl" "%%k"
            call :Log "Info: Renamed file ..\client\%1\%2\%%~nxl to %%k"
          )
          if "%WSUS_ONLY%"=="1" (
            echo Warning: Download of %%l ^(%%k^) failed.
            call :Log "Warning: Download of %%l (%%k) failed"
          ) else (
            %DLDR_PATH% %DLDR_COPT% %DLDR_POPT% ..\client\%1\%2 "%%m"
            if errorlevel 1 (
              echo Warning: Download of %%m failed.
              call :Log "Warning: Download of %%m failed"
            ) else (
              call :Log "Info: Downloaded/validated %%m to ..\client\%1\%2"
            )
          )
        ) else (
          if exist "..\client\%1\%2\%%~nxl" (
            echo Renaming file ..\client\%1\%2\%%~nxl to %%k...
            ren "..\client\%1\%2\%%~nxl" "%%k"
            call :Log "Info: Renamed file ..\client\%1\%2\%%~nxl to %%k"
          )
        )
      )
    )
  )
)
call :Log "Info: Downloaded/validated %LINES_COUNT% dynamically determined updates for %1 %2"

echo Adjusting UpdateInstaller.ini file...
if exist ..\client\UpdateInstaller.ini (
  if exist ..\client\UpdateInstaller.ori del ..\client\UpdateInstaller.ori
  ren ..\client\UpdateInstaller.ini UpdateInstaller.ori
  for /F "tokens=1* delims==" %%i in (..\client\UpdateInstaller.ori) do (
    if /i "%%i"=="seconly" (
      if "%SECONLY%"=="1" (
        echo seconly=Enabled>>..\client\UpdateInstaller.ini
      ) else (
        echo seconly=Disabled>>..\client\UpdateInstaller.ini
      )
    ) else (
      if "%%j"=="" (
        echo %%i>>..\client\UpdateInstaller.ini
      ) else (
        echo %%i=%%j>>..\client\UpdateInstaller.ini
      )
    )
  )
  del ..\client\UpdateInstaller.ori
)
call :Log "Info: Adjusted UpdateInstaller.ini file"

:CleanupDownload
rem *** Clean up client directory for %1 %2 ***
if not exist ..\client\%1\%2\nul goto RemoveHashes
if "%CLEANUP_DL%"=="0" goto VerifyDownload

echo Cleaning up client directory for %1 %2...

if exist "%TEMP%\ValidLinks-%1-%2.txt" del "%TEMP%\ValidLinks-%1-%2.txt"
if exist "%TEMP%\ValidStaticLinks-%1-%2.txt"  type "%TEMP%\ValidStaticLinks-%1-%2.txt" >>"%TEMP%\ValidLinks-%1-%2.txt"
if exist "%TEMP%\ValidDynamicLinks-%1-%2.txt" type "%TEMP%\ValidDynamicLinks-%1-%2.txt" >>"%TEMP%\ValidLinks-%1-%2.txt"
if not exist "%TEMP%\ValidLinks-%1-%2.txt" echo. >>"%TEMP%\ValidLinks-%1-%2.txt"

for /F "delims=" %%i in ('dir ..\client\%1\%2 /A:-D /B 2^>nul') do (
  if exist "%TEMP%\ValidLinks-%1-%2.txt" (
    %SystemRoot%\System32\find.exe /I "%%i" "%TEMP%\ValidLinks-%1-%2.txt" >nul 2>&1
    if errorlevel 1 (
      del "..\client\%1\%2\%%i"
      call :Log "Info: Deleted ..\client\%1\%2\%%i"
    )
  ) else (
    del "..\client\%1\%2\%%i"
    call :Log "Info: Deleted ..\client\%1\%2\%%i"
  )
)

del "%TEMP%\ValidLinks-%1-%2.txt"

dir ..\client\%1\%2 /A:-D >nul 2>&1
if errorlevel 1 rd ..\client\%1\%2

call :Log "Info: Cleaned up client directory for %1 %2"

:VerifyDownload
if not exist ..\client\%1\%2\nul goto RemoveHashes
rem *** Remove NTFS alternate data streams for %1 %2 ***
if exist %STRMS_PATH% (
  %STRMS_PATH% /accepteula ..\client\%1\%2\*.* >nul 2>&1
  if errorlevel 1 (
    call :Log "Info: File system does not support streams"
  ) else (
    echo Removing NTFS alternate data streams for %1 %2...
    %STRMS_PATH% /accepteula -s -d ..\client\%1\%2\*.* >nul 2>&1
    if errorlevel 1 (
      echo Warning: Unable to remove NTFS alternate data streams for %1 %2.
      call :Log "Warning: Unable to remove NTFS alternate data streams for %1 %2"
    ) else (
      call :Log "Info: Removed NTFS alternate data streams for %1 %2"
    )
  )
) else (
  echo Warning: Sysinternals' NTFS alternate data stream handling tool %STRMS_PATH% not found.
  call :Log "Warning: Sysinternals' NTFS alternate data stream handling tool %STRMS_PATH% not found"
)
if "%VERIFY_DL%" NEQ "1" goto RemoveHashes
rem *** Verifying digital file signatures for %1 %2 ***
if not exist %SIGCHK_PATH% goto NoSigCheck
echo Verifying digital file signatures for %1 %2...
for /F "skip=1 tokens=1 delims=," %%i in ('%SIGCHK_PATH% %SIGCHK_COPT% -s ..\client\%1\%2 ^| %SystemRoot%\System32\findstr.exe /I /V "\"Signed\""') do (
  if /i "%%~xi" NEQ ".zip" (
    if /i "%%~xi" NEQ ".crt" (
      if /i "%%~xi" NEQ ".crl" (
        del "%%i"
        echo Warning: Deleted unsigned file %%i.
        call :Log "Warning: Deleted unsigned file '%%~i'"
      )
    )
  )
)
call :Log "Info: Verified digital file signatures for %1 %2"
rem *** Create integrity database for %1 %2 ***
if not exist ..\client\bin\%HASHDEEP_EXE% goto NoHashDeep
echo Creating integrity database for %1 %2...
if not exist ..\client\md\nul md ..\client\md
..\client\bin\%HASHDEEP_EXE% -c md5,sha1,sha256 -b -r ..\client\%1\%2 >..\client\md\hashes-%1-%2.txt
if errorlevel 1 (
  echo Warning: Error creating integrity database ..\client\md\hashes-%1-%2.txt.
  call :Log "Warning: Error creating integrity database ..\client\md\hashes-%1-%2.txt"
) else (
  call :Log "Info: Created integrity database for %1 %2"
)
for %%i in (..\client\md\hashes-%1-%2.txt) do if %%~zi==0 del %%i
if not exist ..\client\md\hashes-%1-%2.txt goto EndDownload
%SystemRoot%\System32\findstr.exe _[A-Fa-f0-9]*\.[A-Za-z0-9][A-Za-z0-9][A-Za-z0-9]$ ..\client\md\hashes-%1-%2.txt >"%TEMP%\sha1-%1-%2.txt"
for /F "usebackq tokens=3,5 delims=," %%i in ("%TEMP%\sha1-%1-%2.txt") do (
  for /F "tokens=2 delims=_" %%k in ("%%j") do (
    for /F "tokens=1 delims=." %%l in ("%%k") do (
      if /i "%%~xj" NEQ ".crt" (
        if /i "%%~xj" NEQ ".crl" (
          if /i "%%l" NEQ "%%i" (
            del "..\client\%1\%2\%%j"
            ren ..\client\md\hashes-%1-%2.txt hashes-%1-%2.bak
            %SystemRoot%\System32\findstr.exe /L /I /V "%%j" ..\client\md\hashes-%1-%2.bak >..\client\md\hashes-%1-%2.txt
            del ..\client\md\hashes-%1-%2.bak
            echo Warning: Deleted file %%j due to mismatching SHA-1 message digest ^(%%i^).
            call :Log "Warning: Deleted file %%j due to mismatching SHA-1 message digest (%%i)"
          )
        )
      )
    )
  )
)
del "%TEMP%\sha1-%1-%2.txt"
goto EndDownload

:RemoveHashes
if exist ..\client\md\hashes-%1-%2.txt (
  del ..\client\md\hashes-%1-%2.txt
  call :Log "Info: Deleted integrity database for %1 %2"
)
:EndDownload
if exist "%TEMP%\ValidStaticLinks-%1-%2.txt" del "%TEMP%\ValidStaticLinks-%1-%2.txt"
if exist "%TEMP%\ValidDynamicLinks-%1-%2.csv" del "%TEMP%\ValidDynamicLinks-%1-%2.csv"
if "%4"=="/skipdownload" (
  for %%i in (win w60 w61 w62 w63 w100) do (
    if /i "%1"=="%%i" (
      if exist "%TEMP%\ValidDynamicLinks-%1-%2.txt" move /Y "%TEMP%\ValidDynamicLinks-%1-%2.txt" ..\static\custom\StaticDownloadLinks-%1-%3-%2.txt >nul
    )
  )
  if exist "%TEMP%\ValidDynamicLinks-%1-%2.txt" move /Y "%TEMP%\ValidDynamicLinks-%1-%2.txt" ..\static\custom\StaticDownloadLinks-%1-%2.txt >nul
) else (
  if exist "%TEMP%\ValidDynamicLinks-%1-%2.txt" del "%TEMP%\ValidDynamicLinks-%1-%2.txt"
)
verify >nul
goto :eof

:SDDCore
rem %1 -> URL
rem %2 -> Target-Path

set SDDCoreReturnValue=

if "%1"=="" (
  set SDDCoreReturnValue=1
  goto :SDDCoreSkip
)
if "%2"=="" (
  set SDDCoreReturnValue=1
  goto :SDDCoreSkip
)

rem ** get file name from the URL ***
set SDDCoreFileName=
for /f "delims=" %%f in ('%CSCRIPT_PATH% //Nologo //E:vbs ExtractFileNameFromURL.vbs "%1"') do (
  if not "%%f"=="" (
    set SDDCoreFileName=%%f
  )
)
if "%SDDCoreFileName%"=="" (
  rem failed to determine file name
  set SDDCoreReturnValue=1
  goto :SDDCoreSkip
)

rem *** get local ETag ***
set SDDCoreETagLocal=
if not exist "..\static\SelfUpdateVersion-static.txt" (goto SDDCoreDownload)
if not exist "%2\%SDDCoreFileName%" (goto SDDCoreDownload)
for /f "tokens=1,2 delims==" %%a in (..\static\SelfUpdateVersion-static.txt) do (
  if /i "%SDDCoreFileName%"=="%%a" (set "SDDCoreETagLocal=%%b")
)

:SDDCoreDownload
if "%SDDCoreETagLocal%"=="" (
  rem not downloaded yet
  set SDDCoreWGetCmdLine=--progress=bar:noscroll -nv --server-response -P "%2" %1
) else (
  rem already some version downloaded
  set "SDDCoreWGetCmdLine=--progress=bar:noscroll -nv --server-response -P "%2" --header="If-None-Match: %SDDCoreETagLocal:"=\"%" %1"
)

if exist "%2\%SDDCoreFileName%.bak" (del "%2\%SDDCoreFileName%.bak" >nul)
if exist "%2\%SDDCoreFileName%" (ren "%2\%SDDCoreFileName%" "%SDDCoreFileName%.bak" >nul)

set SDDCoreWGetBuffer=
set SDDCoreResultBuffer=
set SDDCoreETagBuffer=
for /f "delims=" %%f in ('%WGET_PATH% %SDDCoreWGetCmdLine% 2^>^&1') do (
  set SDDCoreWGetBuffer=%%f
  if not "!SDDCoreWGetBuffer!"=="" (
    if "!SDDCoreWGetBuffer:~2,8!"=="HTTP/1.1" (
      set "SDDCoreResultBuffer=!SDDCoreWGetBuffer:~2!"
    ) else if "!SDDCoreWGetBuffer:~2,4!"=="Etag" (
      set "SDDCoreETagBuffer=!SDDCoreWGetBuffer:~8!"
    )
  )
)

if "%SDDCoreResultBuffer%"=="" (
  rem no result received
  if exist "%2\%SDDCoreFileName%.bak" (move /y "%2\%SDDCoreFileName%.bak" "%2\%SDDCoreFileName%" >nul)
  set SDDCoreReturnValue=1
  goto :SDDCoreSkip
)

if "%SDDCoreResultBuffer:~9,3%"=="200" (
  rem new file downloaded
  if exist "%2\%SDDCoreFileName%.bak" (del "%2\%SDDCoreFileName%.bak" >nul)
  goto SDDCoreUpdateETag
) else if "%SDDCoreResultBuffer:~9,3%"=="304" (
  rem nothing changed
  if exist "%2\%SDDCoreFileName%.bak" (move /y "%2\%SDDCoreFileName%.bak" "%2\%SDDCoreFileName%" >nul)
  set SDDCoreReturnValue=0
  goto :SDDCoreSkip
) else if "%SDDCoreResultBuffer:~9,3%"=="412" (
  rem nothing changed
  if exist "%2\%SDDCoreFileName%.bak" (move /y "%2\%SDDCoreFileName%.bak" "%2\%SDDCoreFileName%" >nul)
  set SDDCoreReturnValue=0
  goto :SDDCoreSkip
)
rem download error
if exist "%2\%SDDCoreFileName%.bak" (move /y "%2\%SDDCoreFileName%.bak" "%2\%SDDCoreFileName%" >nul)
set SDDCoreReturnValue=1
goto :SDDCoreSkip

:SDDCoreUpdateETag
if "%SDDCoreETagBuffer%"=="" (
  rem no ETag-Header received
  set SDDCoreReturnValue=1
  goto :SDDCoreSkip
)

if not exist "..\static\SelfUpdateVersion-static.txt" (goto SDDCoreAddNewETag)
move /Y ..\static\SelfUpdateVersion-static.txt ..\static\SelfUpdateVersion-static.ori >nul
for /f "tokens=1,2 delims==" %%a in (..\static\SelfUpdateVersion-static.ori) do (
  if not "%%a"=="%SDDCoreFileName%" (
    echo %%a=%%b>>..\static\SelfUpdateVersion-static.txt
  )
)
del ..\static\SelfUpdateVersion-static.ori
:SDDCoreAddNewETag
echo %SDDCoreFileName%=%SDDCoreETagBuffer%>>..\static\SelfUpdateVersion-static.txt
set SDDCoreReturnValue=0

:SDDCoreSkip
set SDDCoreFileName=
set SDDCoreETagLocal=
set SDDCoreWGetCmdLine=
set SDDCoreWGetBuffer=
set SDDCoreResultBuffer=
set SDDCoreETagBuffer=
verify >nul
rem goto EoF would be wrong here
exit /b

:RemindDate
if "%SKIP_DL%"=="1" goto EoF
rem *** Remind build date ***
echo Reminding build date...
echo %DATE:~-11%>..\client\builddate.txt
echo Reminding catalog date...
for /F "tokens=4*" %%i in ('%SIGCHK_PATH% /accepteula -q -nobanner ..\client\wsus\wsusscn2.cab ^| %SystemRoot%\System32\findstr.exe /I "Signing"') do (
  if "%%j"=="" (
    echo %%i>..\client\catalogdate.txt
  ) else (
    echo %%j>..\client\catalogdate.txt
  )
)
rem *** Create autorun.inf file ***
echo Creating autorun.inf file...
echo [autorun]>..\client\autorun.inf
echo open=UpdateInstaller.exe>>..\client\autorun.inf
echo icon=UpdateInstaller.exe,0 >>..\client\autorun.inf
echo action=Run WSUS Offline Update - Community Edition - v. %WSUSOFFLINE_VERSION% (%DATE:~-11%)>>..\client\autorun.inf
goto EoF

:NoExtensions
echo.
echo ERROR: No command extensions / delayed variable expansion available.
echo.
exit /b 1

:InvalidParams
echo.
echo ERROR: Invalid parameter: %*
echo Usage1: %~n0 {o2k13} {enu ^| fra ^| esn ^| jpn ^| kor ^| rus ^| ptg ^| ptb ^| deu ^| nld ^| ita ^| chs ^| cht ^| plk ^| hun ^| csy ^| sve ^| trk ^| ell ^| ara ^| heb ^| dan ^| nor ^| fin} [/excludesp ^| /excludestatics] [/excludewinglb] [/includedotnet] [/seconly] [/includemsse] [/includewddefs] [/nocleanup] [/verify] [/skiptz] [/skipdownload] [/skipdynamic] [/proxy http://[username:password@]^<server^>:^<port^>] [/wsus http://^<server^>] [/wsusonly] [/wsusbyproxy]
echo Usage2: %~n0 {w60 ^| w60-x64 ^| w61 ^| w61-x64 ^| w62-x64 ^| w63 ^| w63-x64 ^| w100 ^| w100-x64 ^| o2k16} {glb} [/excludesp ^| /excludestatics] [/excludewinglb] [/includedotnet] [/seconly] [/includemsse] [/includewddefs] [/nocleanup] [/verify] [/skiptz] [/skipdownload] [/skipdynamic] [/proxy http://[username:password@]^<server^>:^<port^>] [/wsus http://^<server^>] [/wsusonly] [/wsusbyproxy]
call :Log "Error: Invalid parameter: %*"
echo.
goto Error

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

:InsufficientRights
echo ERROR: Insufficient file system rights.
call :Log "Error: Insufficient file system rights"
echo.
goto Error

:NoCScript
echo.
echo ERROR: VBScript interpreter %CSCRIPT_PATH% not found.
call :Log "Error: VBScript interpreter %CSCRIPT_PATH% not found"
echo.
goto Error

:NoWGet
echo.
echo ERROR: Download utility %WGET_PATH% not found.
call :Log "Error: Download utility %WGET_PATH% not found"
echo.
goto Error

:NoDLdr
echo.
echo ERROR: Download utility %DLDR_PATH% not found.
call :Log "Error: Download utility %DLDR_PATH% not found"
echo.
goto Error

:NoUnZip
echo.
echo ERROR: Utility ..\bin\unzip.exe not found.
call :Log "Error: Utility ..\bin\unzip.exe not found"
echo.
goto Error

:NoHashDeep
echo.
echo ERROR: Hash computing/auditing utility ..\client\bin\%HASHDEEP_EXE% not found.
call :Log "Error: Hash computing/auditing utility ..\client\bin\%HASHDEEP_EXE% not found"
echo.
goto Error

:NoSigCheck
echo.
echo ERROR: Sysinternals' digital file signature verification tool %SIGCHK_PATH% not found.
call :Log "Error: Sysinternals' digital file signature verification tool %SIGCHK_PATH% not found"
echo.
goto Error

:DownloadError
echo.
echo ERROR: Download failure for %1 %2.
call :Log "Error: Download failure for %1 %2"
echo.
goto Error

:IntegrityError
echo.
echo ERROR: File integrity verification failure.
call :Log "Error: File integrity verification failure"
echo.
goto Error

:SignatureError
echo.
echo ERROR: Catalog file ..\client\wsus\wsusscn2.cab signature verification failure.
call :Log "Error: Catalog file ..\client\wsus\wsusscn2.cab signature verification failure"
echo.
goto Error

:Error
if "%EXIT_ERR%"=="1" (
  echo Note: To better help understanding this error, you can select and copy the last messages from this window using the context menu ^(right mouse click in the window^).
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
  call :Log "Info: Executed custom finalization hook (Errorlevel: %errorlevel%)"
)
echo Done.
call :Log "Info: Ending WSUS Offline Update - Community Edition - download for %1 %2"
title %ComSpec%
endlocal
