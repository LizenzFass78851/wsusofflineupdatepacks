@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions
if errorlevel 1 goto NoExtensions

rem clear vars storing parameters
set SEARCH_LEFT_MOST=
set APPEND_UPDATES=

if "%DIRCMD%" NEQ "" set DIRCMD=
if "%UPDATE_LOGFILE%"=="" set UPDATE_LOGFILE=%SystemRoot%\wsusofflineupdate.log

if "%1"=="" goto NoParam
if "%2"=="" goto NoParam

:EvalParams
if "%3"=="" goto NoMoreParams
if /i "%3"=="/searchleftmost" set SEARCH_LEFT_MOST=1
if /i "%3"=="/append" set APPEND_UPDATES=1
shift /3
goto EvalParams

:NoMoreParams
if exist "%TEMP%\Update.txt" (
  if not "%APPEND_UPDATES%"=="1" (
    goto EoF
  )
)
if not exist %2\nul goto EoF

if /i "%SEARCH_LEFT_MOST%"=="1" (
  set UPDATE_SEARCH_MASK=%2\%1*.*
) else (
  set UPDATE_SEARCH_MASK=%2\*%1*.*
)
dir /A:-D /B /OD %UPDATE_SEARCH_MASK% >"%TEMP%\Update.tmp" 2>nul
if errorlevel 1 (
  if exist "%TEMP%\Update.tmp" del "%TEMP%\Update.tmp"
) else (
  for /F "usebackq" %%i in ("%TEMP%\Update.tmp") do echo %2\%%i >>"%TEMP%\UpdatesToInstall.txt"
  rem for /F "usebackq" %%i in ("%TEMP%\Update.tmp") do echo %2\%%i>>"%TEMP%\UpdatesToInstall.txt"
  if "%APPEND_UPDATES%"=="1" (
    type "%TEMP%\Update.tmp">>"%TEMP%\Update.txt"
    del "%TEMP%\Update.tmp"
  ) else (
    move /y "%TEMP%\Update.tmp" "%TEMP%\Update.txt" >nul
  )
)
goto EoF

:NoExtensions
echo ERROR: No command extensions available.
goto Error

:NoParam
echo ERROR: Invalid parameter. Usage: %~n0 {kbid} {directory} [/searchleftmost] [/append]
echo %DATE% %TIME% - Error: Invalid parameter. Usage: %~n0 {kbid} {directory} [/searchleftmost] [/append]>>%UPDATE_LOGFILE%
goto Error

:Error
endlocal
exit /b 1

:EoF
endlocal
