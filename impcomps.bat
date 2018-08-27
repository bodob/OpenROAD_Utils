@echo off
setlocal enabledelayedexpansion
::
:: Copyright (c) 2018 Actian Corporation
::
:: Name: impcomps.bat
::
:: Imports components from a %OR_APPS_HOME%\<application> directory into an existing application <application>.
:: Component export files are expected to be in XML format in %OR_APPS_HOME%\<application>.
:: Import is done using a component list file "export_comps.lst" in the same directory.
::
:: Requirements:
::	 %II_SYSTEM%\ingres\bin\w4gldev.exe or %OR_SYSTEM%\ingres\bin\w4glapp.exe must exist.
::   OR_APPS_HOME environment variable must be set and point to a writeable directory.
::   Directory %OR_APPS_HOME%\<application> must exist and contain files
::   "export_comps.lst" and the files referenced in "export_comps.lst".
::   The database must contain the application <application>.

if /i "%1" == ""                                      goto usage
if /i "%2" == ""                                      goto usage

SET DBNAME=%1 
SET APPNAME=%2
SET FLAGS=%3
SET BATCHNAME=impcomps

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
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%\export_comps.lst" echo %BATCHNAME%: File "%OR_APPS_HOME%\%APPNAME%\export_comps.lst" does not exist & goto end

if "%FLAGS%" == "" set FLAGS=-nreplace -Limpcomps.log -Tyes,logonly

PUSHD "%OR_APPS_HOME%\%APPNAME%"

:: Create log file in current directory
SET II_LOG=.

::
::  Import components
::
echo Importing components ...
"%W4GLAPP_EXE%" backupapp in %DBNAME% %APPNAME% export_comps.lst -l -xml -t %FLAGS%
if errorlevel 1 echo ERROR importing components for application & goto fin

echo.
echo Components imported into application "%APPNAME%" from directory "%OR_APPS_HOME%\%APPNAME%".
echo.
goto fin

:usage
echo.
echo USAGE:
echo.
echo         impcomps ^<database^> ^<application^> ^[^<backupapp flags^>^]
echo.
goto end
:fin
POPD
endlocal
:end
