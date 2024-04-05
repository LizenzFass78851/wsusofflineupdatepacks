@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions
if errorlevel 1 goto NoExtensions

cd /D "%~dp0"

for %%i in (fra esn jpn kor rus ptg ptb nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do if /i "%1"=="%%i" goto ValidParams
goto InvalidParams

:ValidParams
call RemoveCustomLanguageSupport.cmd %1 /quiet

rem *** Add support for %1 to .NET custom URL files ***
if /i "%2" NEQ "/quiet" echo Adding support for %1 to .NET custom URL files...
for /F %%i in (..\static\StaticDownloadLinks-dotnet-%1.txt) do (
  echo %%i | %SystemRoot%\System32\find.exe /I "ndp48-x86-x64-allos-">>..\static\custom\StaticDownloadLinks-dotnet.txt
)
rem *** Add support for %1 to IEx custom URL files ***
if /i "%2" NEQ "/quiet" echo Adding support for %1 to IEx custom URL files...
for %%i in (x86 x64) do (
  if exist ..\static\StaticDownloadLinks-ie11-w62-%%i-%1.txt (
    type ..\static\StaticDownloadLinks-ie11-w62-%%i-%1.txt >>..\static\custom\StaticDownloadLinks-w62-%%i-glb.txt
  )
)
goto EoF

:NoExtensions
echo.
echo ERROR: No command extensions / delayed variable expansion available.
echo.
goto EoF

:InvalidParams
echo.
echo ERROR: Invalid parameter: %*
echo Usage: %~n0 {fra ^| esn ^| jpn ^| kor ^| rus ^| ptg ^| ptb ^| nld ^| ita ^| chs ^| cht ^| plk ^| hun ^| csy ^| sve ^| trk ^| ell ^| ara ^| heb ^| dan ^| nor ^| fin}
echo.
goto EoF

:EoF
endlocal
