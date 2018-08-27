@echo off
setlocal enabledelayedexpansion
::
:: Copyright (c) 2018 Actian Corporation
::
:: Name: expallappcomps.bat
::
:: Exports all application (incl. all components) from a database repository.
::	It calls "expappcomps.bat" for each application, which creates and populates directories
::	under the one referenced by the OR_APPS_HOME environment variable.
:: Requirements:
::	%II_SYSTEM%\ingres\bin\sql.exe (terminal monitor) must exist.
::	%II_SYSTEM%\ingres\bin\w4gldev.exe or %OR_SYSTEM%\ingres\bin\w4glapp.exe must exist.
::	OR_APPS_HOME environment variable must be set and point to a writeable directory.
::	The directory of the expappcomps.bat utility must be in the PATH environment variable.

if /i "%1" == ""                                      goto usage

SET DBNAME=%1 
SET FLAGS=%2
SET BATCHNAME=expallappcomps
::
::  Perform sanity checking before proceeding
::
if EXIST "%II_SYSTEM%\ingres\bin\w4gldev.exe" goto w4gl_found
if EXIST "%OR_SYSTEM%\ingres\bin\w4glapp.exe" goto w4gl_found
echo %BATCHNAME%: Could not find w4gldev.exe or w4glapp.exe & goto end
:w4gl_found

if EXIST "%II_SYSTEM%\ingres\bin\sql.exe" goto sql_found
echo %BATCHNAME%: Could not find sql.exe & goto end
:sql_found
set SQL_EXE=%II_SYSTEM%\ingres\bin\sql.exe


if "%DBNAME%" == "" echo %BATCHNAME%: 4GL Database is not defined & goto end
if "%OR_APPS_HOME%" ==  "" echo %BATCHNAME%: OR_APPS_HOME environment variable is not defined & goto end
if NOT EXIST "%OR_APPS_HOME%\." echo %BATCHNAME%: Directory "%OR_APPS_HOME%" does not exist & goto end

:: Check for expappcomps.bat
%SystemRoot%\system32\where expappcomps.bat 1>NUL 2>NUL
if errorlevel 1 echo ERROR: expappcomps.bat not found in PATH & goto end
for /f "tokens=*" %%J IN ('%SystemRoot%\system32\where expappcomps.bat') DO SET EXPAC=%%~sJ

::
::  Create application list file apps.lst under %OR_APPS_HOME%
::
PUSHD "%OR_APPS_HOME%
echo Creating application list ...
if EXIST apps.lst del apps.lst
echo DECLARE GLOBAL TEMPORARY TABLE apps AS SELECT entity_name AS app FROM ii_entities WHERE version_number=0 AND entity_type='appsource' ON COMMIT PRESERVE ROWS WITH NORECOVERY; COPY session.apps(app=TEXT(0)nl) INTO 'apps.lst';\g\q | "%SQL_EXE%" -S %DBNAME%
if errorlevel 1  echo ERROR using sql to create apps.lst & goto fin
if NOT EXIST apps.lst echo ERROR: apps.lst could not be created & goto fin

:: Export alll applications and their components
for /f %%A in (apps.lst) DO %EXPAC% %DBNAME% %%A %FLAGS%

goto fin

:usage
echo.
echo USAGE:
echo.
echo         expallappcomps ^<database^> ^[^<backupapp flags^>^]
echo.
goto end
:fin
POPD
endlocal
:end
