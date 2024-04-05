@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions
if errorlevel 1 goto NoExtensions

cd /D "%~dp0"

rem *** Remove support for deu from static URL files ***
pushd ..\static
if /i "%1" NEQ "/quiet" echo Removing support for deu from static URL files...
for %%i in (dotnet w62) do (
  for %%j in (x86 x64) do (
    if exist StaticDownloadLinks-%%i-%%j-glb.txt (
      if /i "%1" NEQ "/quiet" echo Processing file ..\static\StaticDownloadLinks-%%i-%%j-glb.txt
      if exist StaticDownloadLinks-%%i-%%j-glb.ori del StaticDownloadLinks-%%i-%%j-glb.ori
      ren StaticDownloadLinks-%%i-%%j-glb.txt StaticDownloadLinks-%%i-%%j-glb.ori  
      %SystemRoot%\System32\findstr.exe /L /I /V "deu. de. de-de" StaticDownloadLinks-%%i-%%j-glb.ori>StaticDownloadLinks-%%i-%%j-glb.txt
      del StaticDownloadLinks-%%i-%%j-glb.ori
      for %%k in (StaticDownloadLinks-%%i-%%j-glb.txt) do if %%~zk==0 del %%k
    )
  )
  if exist StaticDownloadLinks-%%i-glb.txt (
    if /i "%1" NEQ "/quiet" echo Processing file ..\static\StaticDownloadLinks-%%i-glb.txt
    if exist StaticDownloadLinks-%%i-glb.ori del StaticDownloadLinks-%%i-glb.ori
    ren StaticDownloadLinks-%%i-glb.txt StaticDownloadLinks-%%i-glb.ori  
    %SystemRoot%\System32\findstr.exe /L /I /V "deu. de. de-de" StaticDownloadLinks-%%i-glb.ori>StaticDownloadLinks-%%i-glb.txt
    del StaticDownloadLinks-%%i-glb.ori
    for %%k in (StaticDownloadLinks-%%i-glb.txt) do if %%~zk==0 del %%k
  )
  if exist StaticDownloadLinks-%%i.txt (
    if /i "%1" NEQ "/quiet" echo Processing file ..\static\StaticDownloadLinks-%%i.txt
    if exist StaticDownloadLinks-%%i.ori del StaticDownloadLinks-%%i.ori
    ren StaticDownloadLinks-%%i.txt StaticDownloadLinks-%%i.ori  
    %SystemRoot%\System32\findstr.exe /L /I /V "deu. de. de-de" StaticDownloadLinks-%%i.ori>StaticDownloadLinks-%%i.txt
    del StaticDownloadLinks-%%i.ori
    for %%k in (StaticDownloadLinks-%%i.txt) do if %%~zk==0 del %%k
  )
)
popd
goto EoF

:NoExtensions
echo.
echo ERROR: No command extensions / delayed variable expansion available.
echo.
goto EoF

:EoF
endlocal
