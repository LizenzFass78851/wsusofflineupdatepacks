@echo off
rem *** Author: T. Wittrock, Kiel ***

verify other 2>nul
setlocal enableextensions
if errorlevel 1 goto NoExtensions

cd /D "%~dp0"

for %%i in (enu fra esn jpn kor rus ptg ptb deu nld ita chs cht plk hun csy sve trk ell ara heb dan nor fin) do if /i "%1"=="%%i" goto ValidParams
goto InvalidParams

:ValidParams
rem *** Remove x64 support from Office 2013 custom URL files for %1 ***
if /i "%2" NEQ "/quiet" echo Removing x64 support from Office 2013 custom URL files for %1...
for /F %%i in (..\static\StaticDownloadLinks-o2k13-x64-%1.txt) do (
  if exist ..\static\custom\StaticDownloadLinks-o2k13-%1.txt (
    ren ..\static\custom\StaticDownloadLinks-o2k13-%1.txt StaticDownloadLinks-o2k13-%1.tmp
    %SystemRoot%\System32\findstr.exe /L /I /V "%%~nxi" ..\static\custom\StaticDownloadLinks-o2k13-%1.tmp>..\static\custom\StaticDownloadLinks-o2k13-%1.txt
    del ..\static\custom\StaticDownloadLinks-o2k13-%1.tmp
  )
)
for %%i in (..\static\custom\StaticDownloadLinks-o2k13-%1.txt) do if %%~zi==0 del %%i
rem *** Remove x64 support from Office 2013 custom URL files for glb ***
if /i "%2" NEQ "/quiet" echo Removing x64 support from Office 2013 custom URL files for glb...
for /F %%i in (..\static\StaticDownloadLinks-o2k13-x64-glb.txt) do (
  if exist ..\static\custom\StaticDownloadLinks-o2k13-glb.txt (
    ren ..\static\custom\StaticDownloadLinks-o2k13-glb.txt StaticDownloadLinks-o2k13-glb.tmp
    %SystemRoot%\System32\findstr.exe /L /I /V "%%~nxi" ..\static\custom\StaticDownloadLinks-o2k13-glb.tmp>..\static\custom\StaticDownloadLinks-o2k13-glb.txt
    del ..\static\custom\StaticDownloadLinks-o2k13-glb.tmp
  )
)
for %%i in (..\static\custom\StaticDownloadLinks-o2k13-glb.txt) do if %%~zi==0 del %%i
rem *** Remove x64 support from Office 2016 custom URL files for %1 ***
if exist ..\static\StaticDownloadLinks-o2k16-x64-%1.txt (
  if /i "%2" NEQ "/quiet" echo Removing x64 support from Office 2016 custom URL files for %1...
  for /F %%i in (..\static\StaticDownloadLinks-o2k16-x64-%1.txt) do (
    if exist ..\static\custom\StaticDownloadLinks-o2k16-%1.txt (
      ren ..\static\custom\StaticDownloadLinks-o2k16-%1.txt StaticDownloadLinks-o2k16-%1.tmp
      %SystemRoot%\System32\findstr.exe /L /I /V "%%~nxi" ..\static\custom\StaticDownloadLinks-o2k16-%1.tmp>..\static\custom\StaticDownloadLinks-o2k16-%1.txt
      del ..\static\custom\StaticDownloadLinks-o2k16-%1.tmp
    )
  )
)
for %%i in (..\static\custom\StaticDownloadLinks-o2k16-%1.txt) do if %%~zi==0 del %%i
rem *** Remove x64 support from Office 2016 custom URL files for glb ***
if /i "%2" NEQ "/quiet" echo Removing x64 support from Office 2016 custom URL files for glb...
for /F %%i in (..\static\StaticDownloadLinks-o2k16-x64-glb.txt) do (
  if exist ..\static\custom\StaticDownloadLinks-o2k16-glb.txt (
    ren ..\static\custom\StaticDownloadLinks-o2k16-glb.txt StaticDownloadLinks-o2k16-glb.tmp
    %SystemRoot%\System32\findstr.exe /L /I /V "%%~nxi" ..\static\custom\StaticDownloadLinks-o2k16-glb.tmp>..\static\custom\StaticDownloadLinks-o2k16-glb.txt
    del ..\static\custom\StaticDownloadLinks-o2k16-glb.tmp
  )
)
for %%i in (..\static\custom\StaticDownloadLinks-o2k16-glb.txt) do if %%~zi==0 del %%i
goto EoF

:NoExtensions
echo.
echo ERROR: No command extensions / delayed variable expansion available.
echo.
goto EoF

:InvalidParams
echo.
echo ERROR: Invalid parameter: %*
echo Usage: %~n0 {enu ^| fra ^| esn ^| jpn ^| kor ^| rus ^| ptg ^| ptb ^| deu ^| nld ^| ita ^| chs ^| cht ^| plk ^| hun ^| csy ^| sve ^| trk ^| ell ^| ara ^| heb ^| dan ^| nor ^| fin} [/quiet]
echo.
goto EoF

:EoF
endlocal
