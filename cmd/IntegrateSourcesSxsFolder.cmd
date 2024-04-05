@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions
if errorlevel 1 goto NoExtensions

rem clear vars storing parameters
set CLEANUP=

cd /D "%~dp0"

title %~n0 %1 %2 %3 %4
set DOWNLOAD_LOGFILE=..\log\download.log
if exist %DOWNLOAD_LOGFILE% (
  echo.>>%DOWNLOAD_LOGFILE%
  echo -------------------------------------------------------------------------------->>%DOWNLOAD_LOGFILE%
  echo.>>%DOWNLOAD_LOGFILE%
)
echo %DATE% %TIME% - Info: Starting %~n0 %1 %2 %3 %4>>%DOWNLOAD_LOGFILE%

for %%i in (w62-x64 w63 w63-x64 w100 w100-x64) do (
  if /i "%~2"=="%%i" (
    for %%j in (enu fra esn jpn kor rus ptg ptb deu nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do (
      if /i "%~3"=="%%j" goto EvalParam1
    )
  )
)
goto InvalidParams

:EvalParam1
if not exist "%~1" goto InvalidFolder
if /i "%4"=="/cleanup" set CLEANUP=1

rem *** Copy SourcesSxs tree ***
if not exist %SystemRoot%\System32\xcopy.exe goto NoXCopy
echo Integrating folder %1 into ..\client\%2\%3\sxs...
if "%CLEANUP%"=="1" (
  echo Cleaning up target directory ..\client\%2\%3\sxs...
  if exist ..\client\%2\%3\sxs rd /s /q ..\client\%2\%3\sxs
)
%SystemRoot%\System32\xcopy.exe %1 ..\client\%2\%3\sxs /E /I /Y
if errorlevel 1 goto XCopyError
echo %DATE% %TIME% - Info: Integrated folder %1 into ..\client\%2\%3\sxs>>%DOWNLOAD_LOGFILE%
goto EoF

:NoExtensions
echo.
echo ERROR: No command extensions available.
echo.
exit /b 1

:InvalidParams
echo.
echo ERROR: Invalid parameter: %*
echo Usage: %~n0 ^<SxsPath^> {w62-x64 ^| w63 ^| w63-x64 ^| w100 ^| w100-x64} {enu ^| fra ^| esn ^| jpn ^| kor ^| rus ^| ptg ^| ptb ^| deu ^| nld ^| ita ^| chs ^| cht ^| plk ^| hun ^| csy ^| sve ^| trk ^| ell ^| ara ^| heb ^| dan ^| nor ^| fin} [/cleanup]
echo Example: %~n0 D:\sources\sxs w63-x64 enu
echo %DATE% %TIME% - Error: Invalid parameter: %*>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:InvalidFolder
echo.
echo ERROR: Folder not found: %1
echo Usage: %~n0 ^<SxsPath^> {w62-x64 ^| w63 ^| w63-x64 ^| w100 ^| w100-x64} {enu ^| fra ^| esn ^| jpn ^| kor ^| rus ^| ptg ^| ptb ^| deu ^| nld ^| ita ^| chs ^| cht ^| plk ^| hun ^| csy ^| sve ^| trk ^| ell ^| ara ^| heb ^| dan ^| nor ^| fin} [/cleanup]
echo Example: %~n0 D:\sources\sxs w63-x64 enu
echo %DATE% %TIME% - Error: Folder not found: %1>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:NoXCopy
echo.
echo ERROR: Utility %SystemRoot%\System32\xcopy.exe not found.
echo %DATE% %TIME% - Error: Utility %SystemRoot%\System32\xcopy.exe not found>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:XCopyError
echo.
echo ERROR: Copying failed.
echo %DATE% %TIME% - Error: Copying failed>>%DOWNLOAD_LOGFILE%
echo.
goto Error

:Error
title %ComSpec%
endlocal
verify other 2>nul
goto :eof

:EoF
title %ComSpec%
endlocal
