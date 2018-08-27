@echo off
setlocal enabledelayedexpansion
::
:: Copyright (c) 2018 Actian Corporation
::
:: Name: impappcomps.bat
::
:: Imports an application and all its components from a %OR_APPS_HOME%\<application> directory.
::   - Imports the application source from the file <application>.dsc (in XML format) in %OR_APPS_HOME%\<application>
::     Rather than "dsc" the file extension for this file can be specified by the OR_FILEEXT_APP environment variable.
::   - Imports the components export files (in XML format) in %OR_APPS_HOME%\<application>
::     using a component list file "export_comps.lst" in the same directory.
:: Requirements:
::	 %II_SYSTEM%\ingres\bin\w4gldev.exe or %OR_SYSTEM%\ingres\bin\w4glapp.exe must exist.
::   OR_APPS_HOME environment variable must be set and point to a writeable directory.
::   Directory %OR_APPS_HOME%\<application> must exist and contain files <application>.dsc,
::   "export_comps.lst" and the component export files referenced in "export_comps.lst".

if /i "%1" == ""                                      goto usage
if /i "%2" == ""                                      goto usage

SET DBNAME=%1 
SET APPNAME=%2
SET FLAGS=%3
SET BATCHNAME=impappcomps

if "%OR_FILEEXT_APP%" ==  ""                          set OR_FILEEXT_APP=dsc

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

if "%DBNAME%" == "" echo %BATCHNAME%: 4GL Database is not defined & goto end
if "%APPNAME%" == "" echo %BATCHNAME%: Application name is not defined & goto end
if "%OR_APPS_HOME%" ==  "" echo %BATCHNAME%: OR_APPS_HOME environment variable is not defined & goto end
if NOT EXIST "%OR_APPS_HOME%\." echo %BATCHNAME%: Directory "%OR_APPS_HOME%" does not exist & goto end
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%" echo %BATCHNAME%: Directory "%OR_APPS_HOME%\%APPNAME%" does not exist & goto end
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%\%APPNAME%.%OR_FILEEXT_APP%" echo %BATCHNAME%: File "%OR_APPS_HOME%\%APPNAME%\%APPNAME%.%OR_FILEEXT_APP%" does not exist & goto end
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%\export_comps.lst" echo %BATCHNAME%: File "%OR_APPS_HOME%\%APPNAME%\export_comps.lst" does not exist & goto end

if "%FLAGS%" == "" set FLAGS=-nreplace -Limpappcomps.log -Tyes,logonly

PUSHD "%OR_APPS_HOME%\%APPNAME%"

:: Create log file in current directory
SET II_LOG=.

::
::  Import application export file (AppSource only)
::
echo Importing application (appsource) ...
"%W4GLAPP_EXE%" backupapp in %DBNAME% %APPNAME% %APPNAME%.%OR_FILEEXT_APP% -xml %FLAGS%
if errorlevel 1  echo ERROR importing application & goto fin

::
::  Import components
::
echo Importing components ...
"%W4GLAPP_EXE%" backupapp in %DBNAME% %APPNAME% export_comps.lst -l -xml -t -A %FLAGS%
if errorlevel 1  echo ERROR importing components for application & goto fin

echo.
echo Application "%APPNAME%" and its components imported from directory "%OR_APPS_HOME%\%APPNAME%".
echo.
goto fin

:usage
echo.
echo USAGE:
echo.
echo         impappcomps ^<database^> ^<application^> ^[^<backupapp flags^>^]
echo.
goto end
:fin
POPD
endlocal
:end
