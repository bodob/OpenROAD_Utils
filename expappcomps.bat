@echo off
setlocal enabledelayedexpansion
::
:: Copyright (c) 2018 Actian Corporation
::
:: Name: expappcomps.bat
::
:: Exports an application and all its components from a database repository.
::   - Creates %OR_APPS_HOME%\<application> directory (if not existing yet)
::   - Exports (in XML format) the application source into the file <application>.dsc in %OR_APPS_HOME%\<application>
::     Rather than "dsc" the file extension for this file can be specified by the OR_FILEEXT_APP environment variable.
::   - Creates a component list file "export_comps.lst" in %OR_APPS_HOME%\<application>
::   - Exports (in XML format) all components into files <component>.xml in %OR_APPS_HOME%\<application>
::     Rather than "xml" the file extension for the files can be specified by the OR_FILEEXT_COMP environment variable.
::
:: Requirements:
::	%II_SYSTEM%\ingres\bin\sql.exe (terminal monitor) must exist.
::	%II_SYSTEM%\ingres\bin\w4gldev.exe or %OR_SYSTEM%\ingres\bin\w4glapp.exe must exist.
::  OR_APPS_HOME environment variable must be set and point to a writeable directory.

if /i "%1" == ""                                      goto usage
if /i "%2" == ""                                      goto usage

SET DBNAME=%1 
SET APPNAME=%2
SET FLAGS=%3
SET BATCHNAME=expappcomps

::
::  Perform sanity checking before proceeding
::
if EXIST "%II_SYSTEM%\ingres\bin\w4gldev.exe" (
 set W4GLAPP_EXE=!II_SYSTEM!\ingres\bin\w4gldev.exe
 set W4GLDEV_FOUND=TRUE
 set W4GLAPP_NAME=w4gldev
) ELSE (
 if EXIST "!OR_SYSTEM!\ingres\bin\w4glapp.exe" (
  set W4GLAPP_EXE=!OR_SYSTEM!\ingres\bin\w4glapp.exe
  set W4GLDEV_FOUND=TRUE
  set W4GLAPP_NAME=w4glapp
 )
)
if /i "%W4GLDEV_FOUND%" NEQ "TRUE" echo %BATCHNAME%: Could not find w4gldev.exe or w4glapp.exe & goto end

if EXIST "%II_SYSTEM%\ingres\bin\sql.exe" goto sql_found
echo %BATCHNAME%: Could not find sql.exe & goto end
:sql_found
set SQL_EXE=%II_SYSTEM%\ingres\bin\sql.exe

if "%DBNAME%" == "" echo %BATCHNAME%: 4GL Database is not defined & goto end
if "%APPNAME%" == "" echo %BATCHNAME%: Application name is not defined & goto end
if "%OR_APPS_HOME%" ==  "" echo %BATCHNAME%: OR_APPS_HOME environment variable is not defined & goto end
if NOT EXIST "%OR_APPS_HOME%\." echo %BATCHNAME%: Directory "%OR_APPS_HOME%" does not exist & goto end

if "%FLAGS%" == "" set FLAGS=-Lexpappcomps.log -Tyes,logonly
if "%OR_FILEEXT_APP%" == "" set OR_FILEEXT_APP=dsc
if "%OR_FILEEXT_COMP%" == "" set OR_FILEEXT_COMP=xml

::
::  Create application directory under %OR_APPS_HOME%
::
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%"   echo Creating directory "%OR_APPS_HOME%\%APPNAME%" ...
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%"   MKDIR "%OR_APPS_HOME%\%APPNAME%"
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%"   echo  ERROR: Directory "%OR_APPS_HOME%\%APPNAME%" could not be created.
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%"   goto end
PUSHD "%OR_APPS_HOME%\%APPNAME%"

::
::  Create component list
::
echo Creating component list ...
if EXIST export_comps.lst del export_comps.lst
echo DECLARE GLOBAL TEMPORARY TABLE ec AS SELECT e.entity_name + ',' + lowercase(e.entity_name)+'.%OR_FILEEXT_COMP%' FROM ii_entities e, ii_entities a WHERE e.folder_id=a.entity_id AND e.version_number=-1 AND lowercase(a.entity_name)=lowercase('%APPNAME%') ON COMMIT PRESERVE ROWS WITH NORECOVERY; COPY session.ec(col1=TEXT(0)nl) INTO 'export_comps.lst';\g\q | "%SQL_EXE%" -S %DBNAME%
if errorlevel 1  echo ERROR using sql to create export_comps.lst
if errorlevel 1  goto fin
if NOT EXIST export_comps.lst echo ERROR: export_comps.lst could not be created.
if NOT EXIST export_comps.lst goto end

:: Make sure XML export files are indented (Makes "diff" easier)
SET II_W4GL_EXPORT_INDENTED=TRUE
:: Create log file in current directory
SET II_LOG=.

::
::  Create application export file (AppSource only)
::
echo Exporting application (appsource) ...
"%W4GLAPP_EXE%" backupapp out %DBNAME% %APPNAME% %APPNAME%.%OR_FILEEXT_APP% -xml -appsource %FLAGS%
if errorlevel 1  echo ERROR exporting application & goto fin
if NOT EXIST %APPNAME%.%OR_FILEEXT_APP% echo expappcomps: %APPNAME%.%OR_FILEEXT_APP% could not be created & goto fin
::
::  Export components
::
echo Exporting components ...
"%W4GLAPP_EXE%" backupapp out %DBNAME% %APPNAME% export_comps.lst -l -xml -A %FLAGS%
if errorlevel 1  echo ERROR exporting components for application & goto fin

echo.
echo Application "%APPNAME%" and its components exported into directory "%OR_APPS_HOME%\%APPNAME%".
echo.
goto fin

:usage
echo.
echo USAGE:
echo.
echo         expappcomps ^<database^> ^<application^> ^[^<backupapp flags^>^]
echo.
goto end
:fin
POPD
endlocal
:end
