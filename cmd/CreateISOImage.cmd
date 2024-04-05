@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions
if errorlevel 1 goto NoExtensions

rem clear vars storing parameters
set EXC_SW=
set INC_DOTNET=
set INC_WDDEFS=
set EXIT_ERR=
set SKIP_HASHES=
set OUTPUT_PATH=

cd /D "%~dp0"

title %~n0 %1 %2 %3 %4 %5 %6 %7 %8 %9
echo Starting ISO image creation for %1 %2 %3 %4 %5 %6 %7 %8 %9...
set DOWNLOAD_LOGFILE=..\log\download.log
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
  echo %DATE% %TIME% - Info: Executed custom initialization hook ^(Errorlevel: %ERR_LEVEL%^)>>%DOWNLOAD_LOGFILE%
  set ERR_LEVEL=
)
echo %DATE% %TIME% - Info: Starting ISO image creation for %1 %2 %3 %4 %5 %6 %7 %8 %9>>%DOWNLOAD_LOGFILE%

if "%TEMP%"=="" goto NoTemp
pushd "%TEMP%"
if errorlevel 1 goto NoTempDir
popd

for %%i in (all all-x86 all-x64 enu fra esn jpn kor rus ptg ptb deu nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do (if /i "%1"=="%%i" goto V1EvalParams)
for %%i in (w60 w60-x64 w61 w61-x64 w62-x64 w63 w63-x64 w100 w100-x64 o2k16) do (
  if /i "%1"=="%%i" (
    if /i "%2"=="glb" shift /2
    goto V1EvalParams
  )
)
for %%i in (o2k13) do (
  if /i "%1"=="%%i" (
    for %%j in (glb enu fra esn jpn kor rus ptg ptb deu nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do (if /i "%2"=="%%j" goto V2EvalParams)
    goto V1EvalParams
  )
)
goto InvalidParams

:V1EvalParams
if "%2"=="" goto V1CreateFilter
if /i "%2"=="/excludesw" set EXC_SW=1
if /i "%2"=="/includedotnet" set INC_DOTNET=1
if /i "%2"=="/includewddefs" set INC_WDDEFS=1
if /i "%2"=="/exitonerror" set EXIT_ERR=1
if /i "%2"=="/skiphashes" set SKIP_HASHES=1
if /i "%2"=="/outputpath" (
  if %3~==~ (goto InvalidParams) else (set OUTPUT_PATH=%~fs3)
  shift /2
)
shift /2
goto V1EvalParams

:V2EvalParams
if "%3"=="" goto V2CreateFilter
if /i "%3"=="/excludesw" set EXC_SW=1
if /i "%3"=="/includedotnet" set INC_DOTNET=1
if /i "%3"=="/includewddefs" set INC_WDDEFS=1
if /i "%3"=="/exitonerror" set EXIT_ERR=1
if /i "%3"=="/skiphashes" set SKIP_HASHES=1
if /i "%3"=="/outputpath" (
  if %4~==~ (goto InvalidParams) else (set OUTPUT_PATH=%~fs4)
  shift /3
)
shift /3
goto V2EvalParams

:CopyFilter
rem *** Copy ISO filter ***
if exist ..\exclude\ExcludeListISO-%1.txt (
  copy /Y ..\exclude\ExcludeListISO-%1.txt %ISO_FILTER% >nul
) else (
  copy /Y ..\exclude\ExcludeListISO-%1-x86.txt %ISO_FILTER% >nul
)
if exist ..\exclude\custom\ExcludeListISO-%1.txt (
  type ..\exclude\custom\ExcludeListISO-%1.txt >>%ISO_FILTER%
)
if exist ..\exclude\custom\ExcludeListISO-%1-x86.txt (
  type ..\exclude\custom\ExcludeListISO-%1-x86.txt >>%ISO_FILTER%
)
goto :eof

:LocaleFilter
for %%i in (enu fra esn jpn kor rus ptg ptb deu nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do (
  if /i "%1" NEQ "%%i" (
    if /i "%%i"=="enu" (echo */*/%%i/*>>%ISO_FILTER%) else (
      if /i "%%i"=="ell" (echo */*/%%i/*>>%ISO_FILTER%) else (echo *%%i*>>%ISO_FILTER%)
    )
  )
)
goto :eof

:ExtendFilter
if "%EXC_SW%"=="1" (
  for /F %%i in (..\exclude\ExcludeList-software.txt) do echo %%i/>>%ISO_FILTER%
)
for %%i in (o2k13 o2k16 ) do (
  if /i "%1"=="%%i" (
    for /F %%j in (..\exclude\ExcludeListISO-dotnet.txt) do echo %%j/>>%ISO_FILTER%
  )
)
if "%INC_DOTNET%" NEQ "1" (
  for /F %%i in (..\exclude\ExcludeListISO-dotnet.txt) do echo %%i/>>%ISO_FILTER%
)
if "%INC_WDDEFS%" NEQ "1" (
  for /F %%i in (..\exclude\ExcludeList-wddefs.txt) do echo %%i/>>%ISO_FILTER%
)
goto :eof

:V1CreateFilter
rem *** Create ISO filter ***
echo Creating ISO filter for %1...
set ISO_FILTER="%TEMP%\ExcludeListISO-%1.txt"
for %%i in (all all-x86 all-x64 w60 w60-x64 w61 w61-x64 w62-x64 w63 w63-x64 w100 w100-x64 o2k13 o2k16) do (if /i "%1"=="%%i" goto V1CopyFilter)
set ISO_NAME=wsusoffline-%1-x86
set ISO_VOLID=WOU_%1_x86
copy /Y ..\exclude\ExcludeListISO-all-x86.txt %ISO_FILTER% >nul
if exist ..\exclude\custom\ExcludeListISO-all-x86.txt (
  type ..\exclude\custom\ExcludeListISO-all-x86.txt >>%ISO_FILTER%
)
call :LocaleFilter %1
call :ExtendFilter %1
goto CreateImage

:V1CopyFilter
set ISO_NAME=wsusoffline-%1
set ISO_VOLID=WOU_%1
call :CopyFilter %1
call :ExtendFilter %1
goto CreateImage

:V2CreateFilter
rem *** Create ISO filter ***
echo Creating ISO filter for %1 %2...
set ISO_FILTER="%TEMP%\ExcludeListISO-%1-%2.txt"
set ISO_NAME=wsusoffline-%1-%2
set ISO_VOLID=WOU_%1_%2
call :CopyFilter %1
call :LocaleFilter %2
call :ExtendFilter %1
goto CreateImage

:CreateImage
rem *** Create ISO image ***
if %OUTPUT_PATH%~==~ set OUTPUT_PATH=..\iso
if not exist %OUTPUT_PATH%\. goto NoOutputPath
if not exist ..\bin\mkisofs.exe goto NoMkIsoFs
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set HASHDEEP_EXE=hashdeep64.exe) else (
  if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" (set HASHDEEP_EXE=hashdeep64.exe) else (set HASHDEEP_EXE=hashdeep.exe)
)
echo Creating ISO image %OUTPUT_PATH%\%ISO_NAME%.iso...
if exist %OUTPUT_PATH%\%ISO_NAME%.iso del %OUTPUT_PATH%\%ISO_NAME%.iso
if exist %OUTPUT_PATH%\%ISO_NAME%-hashes.txt del %OUTPUT_PATH%\%ISO_NAME%-hashes.txt
if exist "%TEMP%\ExcludeListISO_2.txt" del "%TEMP%\ExcludeListISO_2.txt"
ren %ISO_FILTER% ExcludeListISO_2.txt
for /F "usebackq tokens=1,2* delims=\" %%i in ("%TEMP%\ExcludeListISO_2.txt") do (
  if "%%k"=="" (
    if "%%j"=="" (echo %%i>>%ISO_FILTER%) else (echo */%%i/*>>%ISO_FILTER%)
  ) else (echo */%%i/%%j/*>>%ISO_FILTER%)
)
if exist "%TEMP%\ExcludeListISO_2.txt" del "%TEMP%\ExcludeListISO_2.txt"
..\bin\mkisofs.exe -iso-level 4 -joliet -joliet-long -rational-rock -udf -exclude-list %ISO_FILTER% -output %OUTPUT_PATH%\%ISO_NAME%.iso -volid %ISO_VOLID% ..\client
if errorlevel 1 (
  if exist %ISO_FILTER% del %ISO_FILTER%
  goto MkIsoError
)
if exist %ISO_FILTER% del %ISO_FILTER%
echo %DATE% %TIME% - Info: Created ISO image %OUTPUT_PATH%\%ISO_NAME%.iso>>%DOWNLOAD_LOGFILE%
if "%SKIP_HASHES%"=="1" goto SkipHashes
if exist ..\client\bin\%HASHDEEP_EXE% (
  echo Creating message digest file %OUTPUT_PATH%\%ISO_NAME%-hashes.txt...
  ..\client\bin\%HASHDEEP_EXE% -c md5,sha1,sha256 -b -j1 %OUTPUT_PATH%\%ISO_NAME%.iso >%OUTPUT_PATH%\%ISO_NAME%.mds
  %SystemRoot%\System32\findstr.exe /L /I /C:## /V %OUTPUT_PATH%\%ISO_NAME%.mds >%OUTPUT_PATH%\%ISO_NAME%-hashes.txt
  del %OUTPUT_PATH%\%ISO_NAME%.mds
  echo %DATE% %TIME% - Info: Created message digest file %OUTPUT_PATH%\%ISO_NAME%-hashes.txt>>%DOWNLOAD_LOGFILE%
) else (
  echo Warning: Hash computing/auditing utility ..\client\bin\%HASHDEEP_EXE% not found.
  echo %DATE% %TIME% - Warning: Hash computing/auditing utility ..\client\bin\%HASHDEEP_EXE% not found>>%DOWNLOAD_LOGFILE%
)
:SkipHashes
echo Done.
goto EoF

:NoExtensions
echo.
echo ERROR: No command extensions available.
echo.
exit /b 1

:NoTemp
echo.
echo ERROR: Environment variable TEMP not set.
echo %DATE% %TIME% - Error: Environment variable TEMP not set>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:NoTempDir
echo.
echo ERROR: Directory "%TEMP%" not found.
echo %DATE% %TIME% - Error: Directory "%TEMP%" not found>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:InvalidParams
echo.
echo ERROR: Invalid parameter: %*
echo Usage1: %~n0 {o2k13} {enu ^| fra ^| esn ^| jpn ^| kor ^| rus ^| ptg ^| ptb ^| deu ^| nld ^| ita ^| chs ^| cht ^| plk ^| hun ^| csy ^| sve ^| trk ^| ell ^| ara ^| heb ^| dan ^| nor ^| fin} [/excludesw] [/includedotnet] [/includewddefs] [/skiphashes] [/outputpath ^<OutputPath^>]
echo Usage2: %~n0 {all ^| all-x86 ^| all-x64 ^| w60 ^| w60-x64 ^| w61 ^| w61-x64 ^| w62-x64 ^| w63 ^| w63-x64 ^| w100 ^| w100-x64 ^| o2k16} {enu ^| fra ^| esn ^| jpn ^| kor ^| rus ^| ptg ^| ptb ^| deu ^| nld ^| ita ^| chs ^| cht ^| plk ^| hun ^| csy ^| sve ^| trk ^| ell ^| ara ^| heb ^| dan ^| nor ^| fin} [/excludesw] [/includedotnet] [/includewddefs] [/skiphashes] [/outputpath ^<OutputPath^>]
echo %DATE% %TIME% - Error: Invalid parameter: %*>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:NoOutputPath
echo.
echo ERROR: Output path %OUTPUT_PATH% not found.
echo %DATE% %TIME% - Error: Output path %OUTPUT_PATH% not found>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:NoMkIsoFs
echo.
echo ERROR: Utility ..\bin\mkisofs.exe not found.
echo %DATE% %TIME% - Error: Utility ..\bin\mkisofs.exe not found>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:MkIsoError
echo.
echo ERROR: Creation of ISO image failed.
echo %DATE% %TIME% - Error: Creation of ISO image failed>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:Error
if "%EXIT_ERR%"=="1" (
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
  echo %DATE% %TIME% - Info: Executed custom finalization hook ^(Errorlevel: %errorlevel%^)>>%DOWNLOAD_LOGFILE%
)
echo %DATE% %TIME% - Info: Ending ISO image creation for %1 %2 %3 %4 %5 %6 %7 %8 %9>>%DOWNLOAD_LOGFILE%
title %ComSpec%
endlocal
