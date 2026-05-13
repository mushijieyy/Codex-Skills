@echo off
setlocal

set "IGG_EXE=D:\NUMECA_SOFTWARE\fine161\bin64\iggx86_64.exe"
set "SCRIPT_DIR=%~dp0"
set "DEFAULT_TRB=%SCRIPT_DIR%COON1-4 stage.trb"
set "DEFAULT_GEOM=%SCRIPT_DIR%COON1-4 stage.geomTurbo"
set "DEFAULT_OUTPUT=%SCRIPT_DIR%COON1-4 stage.batch.igg"

if "%~1"=="" (
  set "GEOM=%DEFAULT_GEOM%"
) else (
  set "GEOM=%~1"
)

if "%~2"=="" (
  set "OUTPUT=%DEFAULT_OUTPUT%"
) else (
  set "OUTPUT=%~2"
)

if "%~3"=="" (
  set "TRB=%DEFAULT_TRB%"
) else (
  set "TRB=%~3"
)

if not exist "%IGG_EXE%" (
  echo ERROR: IGG/AutoGrid executable not found:
  echo   %IGG_EXE%
  exit /b 2
)

if not exist "%TRB%" (
  echo ERROR: AutoGrid template .trb not found:
  echo   %TRB%
  exit /b 3
)

if not exist "%GEOM%" (
  echo ERROR: geomTurbo file not found:
  echo   %GEOM%
  exit /b 4
)

for %%I in ("%OUTPUT%") do set "OUTPUT_DIR=%%~dpI"
if not exist "%OUTPUT_DIR%" (
  echo Creating output directory:
  echo   %OUTPUT_DIR%
  mkdir "%OUTPUT_DIR%"
  if errorlevel 1 (
    echo ERROR: Could not create output directory.
    exit /b 5
  )
)

set "JOB_ID=%RANDOM%%RANDOM%"
set "WORK_DIR=%TEMP%\agbatch_%JOB_ID%"
mkdir "%WORK_DIR%"
if errorlevel 1 (
  echo ERROR: Could not create temporary work directory:
  echo   %WORK_DIR%
  exit /b 6
)

set "WORK_TRB=%WORK_DIR%\template.trb"
set "WORK_GEOM=%WORK_DIR%\template.geomTurbo"
set "WORK_MESH=%WORK_DIR%\mesh.igg"
set "WORK_PROJECT=%WORK_DIR%\mesh.trb"
set "WORK_REPORT=%WORK_DIR%\qualityReport.txt"
set "WORK_LOG=%WORK_DIR%\autogrid.log"
set "PY_SCRIPT=%WORK_DIR%\run_autogrid_project.py"

copy /y "%TRB%" "%WORK_TRB%" >nul
if errorlevel 1 (
  echo ERROR: Could not copy template to temporary work directory.
  exit /b 7
)

copy /y "%GEOM%" "%WORK_GEOM%" >nul
if errorlevel 1 (
  echo ERROR: Could not copy geomTurbo to temporary work directory.
  exit /b 8
)

(
  echo import os
  echo import sys
  echo.
  echo work_dir = os.getcwd^(^).replace^("\\", "/"^)
  echo template = work_dir + "/template.trb"
  echo project = work_dir + "/mesh.trb"
  echo.
  echo print^("embedded run_autogrid_project.py argv = %%s" %% ^(sys.argv,^)^)
  echo print^("Working directory: %%s" %% work_dir^)
  echo print^("Opening template: %%s" %% template^)
  echo a5_open_template^(template^)
  echo.
  echo print^("Generating 3D mesh"^)
  echo a5_generate_3d^(^)
  echo.
  echo print^("Saving AutoGrid project: %%s" %% project^)
  echo a5_save_project^(project^)
  echo.
  echo print^("Exiting"^)
  echo exit_session^(^)
) > "%PY_SCRIPT%"
if errorlevel 1 (
  echo ERROR: Could not create embedded AutoGrid Python script:
  echo   %PY_SCRIPT%
  exit /b 11
)

echo AutoGrid executable:
echo   %IGG_EXE%
echo Template:
echo   %TRB%
echo Geometry:
echo   %GEOM%
echo Output mesh:
echo   %OUTPUT%
echo Temporary work directory:
echo   %WORK_DIR%
echo.

cd /d "%WORK_DIR%"
"%IGG_EXE%" -autogrid5 -batch -script "%PY_SCRIPT:\=/%" > "%WORK_LOG%" 2>&1
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  echo.
  echo ERROR: AutoGrid failed with exit code %EXIT_CODE%.
  echo Log file:
  echo   %WORK_LOG%
  exit /b %EXIT_CODE%
)

if not exist "%WORK_PROJECT%" (
  echo.
  echo ERROR: AutoGrid finished but did not create the expected project file.
  echo Expected:
  echo   %WORK_PROJECT%
  echo Log file:
  echo   %WORK_LOG%
  exit /b 9
)

if not exist "%WORK_MESH%" (
  echo.
  echo ERROR: AutoGrid finished but did not create the expected mesh file.
  echo Expected:
  echo   %WORK_MESH%
  echo Log file:
  echo   %WORK_LOG%
  exit /b 12
)

copy /y "%WORK_MESH%" "%OUTPUT%" >nul
if errorlevel 1 (
  echo ERROR: Could not copy generated mesh to output path:
  echo   %OUTPUT%
  echo Temporary mesh remains here:
  echo   %WORK_MESH%
  exit /b 10
)

for %%I in ("%OUTPUT%") do (
  set "OUTPUT_BASE=%%~dpnI"
)

copy /y "%WORK_PROJECT%" "%OUTPUT_BASE%.trb" >nul
if exist "%WORK_DIR%\mesh.geomTurbo" copy /y "%WORK_DIR%\mesh.geomTurbo" "%OUTPUT_BASE%.geomTurbo" >nul

for %%E in (bcs cgns config geom info qualityReport xmt_txt) do (
  if exist "%WORK_DIR%\mesh.%%E" copy /y "%WORK_DIR%\mesh.%%E" "%OUTPUT_BASE%.%%E" >nul
)

if exist "%WORK_LOG%" copy /y "%WORK_LOG%" "%OUTPUT_BASE%.autogrid.log" >nul

echo.
echo Done.
echo Generated mesh:
echo   %OUTPUT%
echo Generated companion files:
echo   %OUTPUT_BASE%.trb
echo   %OUTPUT_BASE%.geomTurbo
echo   %OUTPUT_BASE%.cgns
echo   %OUTPUT_BASE%.bcs
echo   %OUTPUT_BASE%.config
echo   %OUTPUT_BASE%.info
echo   %OUTPUT_BASE%.qualityReport
echo   %OUTPUT_BASE%.autogrid.log
echo Log file:
echo   %WORK_LOG%
exit /b 0
