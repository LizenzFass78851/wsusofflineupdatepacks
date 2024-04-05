@echo off
rem *** Author: T. Wittrock, Kiel ***

verify other 2>nul
setlocal enableextensions
if errorlevel 1 goto NoExtensions

cd /D "%~dp0"

for %%i in (enu fra esn jpn kor rus ptg ptb deu nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do if /i "%1"=="%%i" goto ValidParams
goto InvalidParams

:ValidParams
call RemoveOffice2010x64Support.cmd %1 /quiet

rem *** Add x64 support for %1 to Office 2013 custom URL files ***
if exist ..\static\StaticDownloadLinks-o2k13-x64-%1.txt (
  echo Adding x64 support for %1 to Office 2013 custom URL files...
  type ..\static\StaticDownloadLinks-o2k13-x64-%1.txt >>..\static\custom\StaticDownloadLinks-o2k13-%1.txt
)
rem *** Add x64 support for glb to Office 2013 custom URL files ***
if exist ..\static\StaticDownloadLinks-o2k13-x64-glb.txt (
  echo Adding x64 support for glb to Office 2013 custom URL files...
  type ..\static\StaticDownloadLinks-o2k13-x64-glb.txt >>..\static\custom\StaticDownloadLinks-o2k13-glb.txt
)
rem *** Add x64 support for %1 to Office 2016 custom URL files ***
if exist ..\static\StaticDownloadLinks-o2k16-x64-%1.txt (
  echo Adding x64 support for %1 to Office 2016 custom URL files...
  type ..\static\StaticDownloadLinks-o2k16-x64-%1.txt >>..\static\custom\StaticDownloadLinks-o2k16-%1.txt
)
rem *** Add x64 support for glb to Office 2016 custom URL files ***
if exist ..\static\StaticDownloadLinks-o2k16-x64-glb.txt (
  echo Adding x64 support for glb to Office 2016 custom URL files...
  type ..\static\StaticDownloadLinks-o2k16-x64-glb.txt >>..\static\custom\StaticDownloadLinks-o2k16-glb.txt
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
echo Usage: %~n0 {enu ^| fra ^| esn ^| jpn ^| kor ^| rus ^| ptg ^| ptb ^| deu ^| nld ^| ita ^| chs ^| cht ^| plk ^| hun ^| csy ^| sve ^| trk ^| ell ^| ara ^| heb ^| dan ^| nor ^| fin}
echo.
goto EoF

:EoF
endlocal
