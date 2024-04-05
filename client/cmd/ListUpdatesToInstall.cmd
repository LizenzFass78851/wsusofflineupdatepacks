@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions enabledelayedexpansion
if errorlevel 1 goto NoExtensions

rem clear vars storing parameters
set SECONLY=
set EXC_STATICS=
set IGNORE_BL=

if "%UPDATE_LOGFILE%"=="" set UPDATE_LOGFILE=%SystemRoot%\wsusofflineupdate.log

set UPDATEID_DEBUG=0

if "%TEMP%"=="" goto NoTemp
pushd "%TEMP%"
if errorlevel 1 goto NoTempDir
popd
if "%OS_NAME%"=="" goto NoOSName
if "%OS_LANG%"=="" goto NoOSLang
if "%OS_ARCH%"=="" goto NoOSArch

:EvalParams
if "%1"=="" goto NoMoreParams
if /i "%1"=="/seconly" set SECONLY=1
if /i "%1"=="/excludestatics" set EXC_STATICS=1
if /i "%1"=="/ignoreblacklist" set IGNORE_BL=1
shift /1
goto EvalParams

:EvalStatics
if not exist %1 goto :eof
for %%i in (%1) do if %%~zi==0 goto :eof
if exist "%TEMP%\StaticUpdateIds.txt" del "%TEMP%\StaticUpdateIds.txt"
for /F "tokens=1* delims=kbKB,;" %%i in (%1) do (
  if exist "%TEMP%\MissingUpdateIds.txt" (
    %SystemRoot%\System32\find.exe /I "%%i" "%TEMP%\MissingUpdateIds.txt" >nul 2>&1
    if errorlevel 1 echo %%i>>"%TEMP%\StaticUpdateIds.txt"
  ) else (
    echo %%i>>"%TEMP%\StaticUpdateIds.txt"
  )
)
if not exist "%TEMP%\StaticUpdateIds.txt" goto :eof
if exist "%TEMP%\InstalledUpdateIds.txt" (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\InstalledUpdateIds.txt" "%TEMP%\StaticUpdateIds.txt" >>"%TEMP%\AllStaticUpdateIds.txt"
) else (
  type "%TEMP%\StaticUpdateIds.txt" >>"%TEMP%\AllStaticUpdateIds.txt"
)
del "%TEMP%\StaticUpdateIds.txt"
goto :eof

:NoMoreParams
rem *** Add statically defined update ids ***
if "%EXC_STATICS%"=="1" goto ListFiles
if exist "%TEMP%\AllStaticUpdateIds.txt" del "%TEMP%\AllStaticUpdateIds.txt"
if "%OS_NAME%"=="w100" (
  call :EvalStatics ..\static\custom\StaticUpdateIds-%OS_NAME%-%OS_VER_BUILD%-%OS_ARCH%.txt
  call :EvalStatics ..\static\StaticUpdateIds-%OS_NAME%-%OS_VER_BUILD%-%OS_ARCH%.txt
  call :EvalStatics ..\static\custom\StaticUpdateIds-%OS_NAME%-%OS_VER_BUILD%.txt
  call :EvalStatics ..\static\StaticUpdateIds-%OS_NAME%-%OS_VER_BUILD%.txt
  if exist ..\static\StaticUpdateIds-%OS_NAME%-%OS_VER_BUILD%-dotnet4-%DOTNET4_RELEASE%.txt (
    call :EvalStatics ..\static\custom\StaticUpdateIds-%OS_NAME%-%OS_VER_BUILD%-dotnet4-%DOTNET4_RELEASE%.txt
    call :EvalStatics ..\static\StaticUpdateIds-%OS_NAME%-%OS_VER_BUILD%-dotnet4-%DOTNET4_RELEASE%.txt
    if "%DOTNET35_VER_MAJOR%%DOTNET35_VER_MINOR%"=="%DOTNET35_VER_TARGET_MAJOR%%DOTNET35_VER_TARGET_MINOR%" (
      call :EvalStatics ..\static\custom\StaticUpdateIds-%OS_NAME%-%OS_VER_BUILD%-dotnet.txt
      call :EvalStatics ..\static\StaticUpdateIds-%OS_NAME%-%OS_VER_BUILD%-dotnet.txt
    )
  ) else (
    call :EvalStatics ..\static\custom\StaticUpdateIds-%OS_NAME%-%OS_VER_BUILD%-dotnet.txt
    call :EvalStatics ..\static\StaticUpdateIds-%OS_NAME%-%OS_VER_BUILD%-dotnet.txt
  )
) else (
  if "%SECONLY%"=="1" (
    call :EvalStatics ..\static\custom\StaticUpdateIds-%OS_NAME%-%OS_ARCH%-seconly.txt
    call :EvalStatics ..\static\StaticUpdateIds-%OS_NAME%-%OS_ARCH%-seconly.txt
    call :EvalStatics ..\static\custom\StaticUpdateIds-%OS_NAME%-seconly.txt
    call :EvalStatics ..\static\StaticUpdateIds-%OS_NAME%-seconly.txt
    call :EvalStatics ..\static\custom\StaticUpdateIds-%OS_NAME%-dotnet%DOTNET35_VER_MAJOR%%DOTNET35_VER_MINOR%-seconly.txt
    call :EvalStatics ..\static\StaticUpdateIds-%OS_NAME%-dotnet%DOTNET35_VER_MAJOR%%DOTNET35_VER_MINOR%-seconly.txt
    call :EvalStatics ..\static\custom\StaticUpdateIds-%OS_NAME%-dotnet4-%DOTNET4_RELEASE%-seconly.txt
    call :EvalStatics ..\static\StaticUpdateIds-%OS_NAME%-dotnet4-%DOTNET4_RELEASE%-seconly.txt
  ) else (
    call :EvalStatics ..\static\custom\StaticUpdateIds-%OS_NAME%-%OS_ARCH%.txt
    call :EvalStatics ..\static\StaticUpdateIds-%OS_NAME%-%OS_ARCH%.txt
    call :EvalStatics ..\static\custom\StaticUpdateIds-%OS_NAME%.txt
    call :EvalStatics ..\static\StaticUpdateIds-%OS_NAME%.txt
    call :EvalStatics ..\static\custom\StaticUpdateIds-%OS_NAME%-dotnet%DOTNET35_VER_MAJOR%%DOTNET35_VER_MINOR%.txt
    call :EvalStatics ..\static\StaticUpdateIds-%OS_NAME%-dotnet%DOTNET35_VER_MAJOR%%DOTNET35_VER_MINOR%.txt
    call :EvalStatics ..\static\custom\StaticUpdateIds-%OS_NAME%-dotnet4-%DOTNET4_RELEASE%.txt
    call :EvalStatics ..\static\StaticUpdateIds-%OS_NAME%-dotnet4-%DOTNET4_RELEASE%.txt
  )
)
if "%O2K13_VER_MAJOR%" NEQ "" (
  call :EvalStatics ..\static\custom\StaticUpdateIds-o2k13.txt
  call :EvalStatics ..\static\StaticUpdateIds-o2k13.txt
)
if "%O2K16_VER_MAJOR%" NEQ "" (
  call :EvalStatics ..\static\custom\StaticUpdateIds-o2k16.txt
  call :EvalStatics ..\static\StaticUpdateIds-o2k16.txt
)
for %%i in ("%TEMP%\AllStaticUpdateIds.txt") do if %%~zi==0 del %%i
if exist "%TEMP%\AllStaticUpdateIds.txt" (
  if exist "%TEMP%\MissingUpdateIds.txt" (
    if exist "%TEMP%\MissingDynamicIds.txt" del "%TEMP%\MissingDynamicIds.txt"
    ren "%TEMP%\MissingUpdateIds.txt" MissingDynamicIds.txt
    type "%TEMP%\AllStaticUpdateIds.txt" >>"%TEMP%\MissingUpdateIds.txt"
    type "%TEMP%\MissingDynamicIds.txt" >>"%TEMP%\MissingUpdateIds.txt"
    del "%TEMP%\MissingDynamicIds.txt"
    del "%TEMP%\AllStaticUpdateIds.txt"
  ) else (
    ren "%TEMP%\AllStaticUpdateIds.txt" MissingUpdateIds.txt
  )
)

:ListFiles
rem *** List update files ***
if exist "%TEMP%\InstalledUpdateIds.txt" del "%TEMP%\InstalledUpdateIds.txt"
if exist "%TEMP%\UpdatesToInstall.txt" del "%TEMP%\UpdatesToInstall.txt"
for %%i in ("%TEMP%\MissingUpdateIds.txt") do if %%~zi==0 del %%i
if not exist "%TEMP%\MissingUpdateIds.txt" goto EoF
echo.>"%TEMP%\ExcludeList.txt"
if "%IGNORE_BL%"=="1" goto IgnoreBL
if exist ..\exclude\ExcludeList.txt (
  type ..\exclude\ExcludeList.txt >"%TEMP%\ExcludeList.txt"
)
if exist ..\exclude\custom\ExcludeList.txt (
  type ..\exclude\custom\ExcludeList.txt >>"%TEMP%\ExcludeList.txt"
)
:IgnoreBL
if "%OS_ARCH%"=="x64" (set OS_SEARCH_DIR=%OS_NAME%-%OS_ARCH%) else (set OS_SEARCH_DIR=%OS_NAME%)
for /F "usebackq tokens=1,2 delims=," %%i in ("%TEMP%\MissingUpdateIds.txt") do (
  if exist "%TEMP%\Update.txt" del "%TEMP%\Update.txt"
  %SystemRoot%\System32\find.exe /I "%%i" "%TEMP%\ExcludeList.txt" >nul 2>&1
  if errorlevel 1 (
    if not "%%j"=="" (
      rem dynamisch ermittelte Updates als CAB
      for %%k in (%OS_LANG% glb) do (
        if exist ..\UpdateTable\UpdateTable-%OS_NAME%-%%k.csv (
          for /F "tokens=1,2 delims=," %%l in (..\UpdateTable\UpdateTable-%OS_NAME%-%%k.csv) do (
            if "%%l"=="%%j" (
              if "%OS_NAME%"=="w100" (
                if exist "..\%OS_SEARCH_DIR%\%%k\%OS_VER_BUILD_INTERNAL%" (call ListUpdateFile.cmd %%m ..\%OS_SEARCH_DIR%\%%k\%OS_VER_BUILD_INTERNAL% /searchleftmost /append)
              )
              call ListUpdateFile.cmd %%m ..\%OS_SEARCH_DIR%\%%k /searchleftmost /append
            )
          )
        )
      )
      if not "%O2K13_VER_MAJOR%"=="" (
        for %%k in (%O2K13_LANG% glb) do (
          if exist ..\UpdateTable\UpdateTable-o2k13-%%k.csv (
            for /F "tokens=1,2 delims=," %%l in (..\UpdateTable\UpdateTable-o2k13-%%k.csv) do (
              if "%%l"=="%%j" (
                call ListUpdateFile.cmd %%m ..\o2k13\%%k /searchleftmost /append
              )
            )
          )
        )
      )
      if not "%O2K16_VER_MAJOR%"=="" (
        for %%k in (%O2K16_LANG% glb) do (
          if exist ..\UpdateTable\UpdateTable-o2k16-%%k.csv (
            for /F "tokens=1,2 delims=," %%l in (..\UpdateTable\UpdateTable-o2k16-%%k.csv) do (
              if "%%l"=="%%j" (
                call ListUpdateFile.cmd %%m ..\o2k16\%%k /searchleftmost /append
              )
            )
          )
        )
      )
    )
    rem statisch definierte Windows-Updates als CAB/MSU/...
    if not exist "%TEMP%\Update.txt" (
      for %%l in (%OS_LANG% glb) do (
        if "%OS_NAME%"=="w100" (
          if exist "..\%OS_SEARCH_DIR%\%%l\%OS_VER_BUILD_INTERNAL%" (
            if %IE_VER_MAJOR%%IE_VER_MINOR%0 GEQ 9100 (
              call ListUpdateFile.cmd ie%IE_VER_MINOR%-*%%i ..\%OS_SEARCH_DIR%\%%l\%OS_VER_BUILD_INTERNAL%
            ) else (
              call ListUpdateFile.cmd ie%IE_VER_MAJOR%-*%%i ..\%OS_SEARCH_DIR%\%%l\%OS_VER_BUILD_INTERNAL%
            )
            call ListUpdateFile.cmd windows*%%i ..\%OS_SEARCH_DIR%\%%l\%OS_VER_BUILD_INTERNAL% /searchleftmost
            call ListUpdateFile.cmd %%i ..\%OS_SEARCH_DIR%\%%l\%OS_VER_BUILD_INTERNAL%
          )
        )
        if %IE_VER_MAJOR%%IE_VER_MINOR%0 GEQ 9100 (
          call ListUpdateFile.cmd ie%IE_VER_MINOR%-*%%i ..\%OS_SEARCH_DIR%\%%l
        ) else (
          call ListUpdateFile.cmd ie%IE_VER_MAJOR%-*%%i ..\%OS_SEARCH_DIR%\%%l
        )
        call ListUpdateFile.cmd windows*%%i ..\%OS_SEARCH_DIR%\%%l /searchleftmost
        call ListUpdateFile.cmd %%i ..\%OS_SEARCH_DIR%\%%l
      )
    )
    rem statisch definierte Office-Updates als EXE
    if not exist "%TEMP%\Update.txt" (
      if not "%O2K13_VER_MAJOR%"=="" (
        for %%k in (%O2K13_LANG% glb) do (
          call ListUpdateFile.cmd %%i*%O2K13_ARCH% ..\o2k13\%%k
          call ListUpdateFile.cmd %%i ..\o2k13\%%k
        )
      )
    )
    if not exist "%TEMP%\Update.txt" (
      if not "%O2K16_VER_MAJOR%"=="" (
        for %%k in (%O2K16_LANG% glb) do (
          call ListUpdateFile.cmd %%i*%O2K16_ARCH% ..\o2k16\%%k
          call ListUpdateFile.cmd %%i ..\o2k16\%%k
        )
      )
    )
    if exist "%TEMP%\Update.txt" (
      if "%UPDATEID_DEBUG%"=="1" (
        if not exist "%SystemRoot%\wsusofflineupdate_Debug" (mkdir "%SystemRoot%\wsusofflineupdate_Debug" >nul)
        if "%%j"=="" (
          move /y "%TEMP%\Update.txt" "%SystemRoot%\wsusofflineupdate_Debug\ListUpdatesToInstall_%%i.txt" >nul
        ) else (
          move /y "%TEMP%\Update.txt" "%SystemRoot%\wsusofflineupdate_Debug\ListUpdatesToInstall_%%i_%%j.txt" >nul
        )
	  ) else (
        del "%TEMP%\Update.txt"
	  )
    ) else (
      set TMP_UPDATE_NAME=%%i
      if not "!TMP_UPDATE_NAME:~0,2!"=="kb" (set TMP_UPDATE_NAME=kb!TMP_UPDATE_NAME!)
      if "%%j"=="" (
        echo Warning: Update !TMP_UPDATE_NAME! not found.
        echo %DATE% %TIME% - Warning: Update !TMP_UPDATE_NAME! not found>>%UPDATE_LOGFILE%
      ) else (
        echo Warning: Update !TMP_UPDATE_NAME! ^(id: %%j^) not found.
        echo %DATE% %TIME% - Warning: Update !TMP_UPDATE_NAME! ^(id: %%j^) not found>>%UPDATE_LOGFILE%
      )
      set TMP_UPDATE_NAME=
    )
  ) else (
    for /F "tokens=1* delims=,;" %%k in ('%SystemRoot%\System32\findstr.exe /I "%%i" "%TEMP%\ExcludeList.txt"') do (
      if "%%l"=="" (
        echo Info: Skipping update %%k due to matching black list entry.
        echo %DATE% %TIME% - Info: Skipped update %%k due to matching black list entry>>%UPDATE_LOGFILE%
      ) else (
        echo Info: Skipping update %%k ^(%%l^) due to matching black list entry.
        echo %DATE% %TIME% - Info: Skipped update %%k ^(%%l^) due to matching black list entry>>%UPDATE_LOGFILE%
      )
    )
  )
)
del "%TEMP%\MissingUpdateIds.txt"
del "%TEMP%\ExcludeList.txt"
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

:NoOSLang
echo ERROR: Environment variable OS_LANG not set.
echo %DATE% %TIME% - Error: Environment variable OS_LANG not set>>%UPDATE_LOGFILE%
goto Error

:NoOSArch
echo ERROR: Environment variable OS_ARCH not set.
echo %DATE% %TIME% - Error: Environment variable OS_ARCH not set>>%UPDATE_LOGFILE%
goto Error

:Error
endlocal
exit /b 1

:EoF
endlocal
