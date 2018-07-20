@echo off
setlocal
::
:: Copyright (c) 2018 Actian Corporation
::
:: Name: impcomps.bat
::
:: Imports components from a %OR_APPS_HOME%\<application> directory into an existing application <application>.
:: Component export files are expected to be in XML format (<component>.xml) in %OR_APPS_HOME%\<application>.
:: Import is done using a component list file "export_comps.lst" in the same directory.
::
:: Requirements:
::	 %II_SYSTEM%\ingres\bin\w4gldev.exe or %OR_SYSTEM%\ingres\bin\w4glapp.exe must exist.
::   OR_APPS_HOME environment variable must be set and point to a writeable directory.
::   Directory %OR_APPS_HOME%\<application> must exist and contain files
::   "export_comps.lst" and the *.xml files referenced in "export_comps.lst".
::   The database must contain the application <application>.

if /i "%1" == ""                                      goto usage
if /i "%2" == ""                                      goto usage

SET DBNAME=%1 
SET APPNAME=%2
SET FLAGS=%3

::
::  Perform sanity checking before proceeding
::
if EXIST "%OR_SYSTEM%\ingres\bin\w4glapp.exe"         set W4GLAPP_EXE=%OR_SYSTEM%\ingres\bin\w4glapp.exe
if EXIST "%OR_SYSTEM%\ingres\bin\w4glapp.exe"         set W4GLDEV_FOUND=TRUE
if EXIST "%OR_SYSTEM%\ingres\bin\w4glapp.exe"         set W4GLAPP_NAME=w4glapp
if EXIST "%OR_SYSTEM%\ingres\bin\w4glapp.exe"         set USEW4GLAPP=TRUE

if EXIST "%II_SYSTEM%\ingres\bin\w4gldev.exe"         set W4GLAPP_EXE=%II_SYSTEM%\ingres\bin\w4gldev.exe
if EXIST "%II_SYSTEM%\ingres\bin\w4gldev.exe"         set W4GLDEV_FOUND=TRUE
if EXIST "%II_SYSTEM%\ingres\bin\w4gldev.exe"         set W4GLAPP_NAME=w4gldev
if EXIST "%II_SYSTEM%\ingres\bin\w4gldev.exe"         set USEW4GLDEV=TRUE

if /i "%W4GLDEV_FOUND%" NEQ "TRUE"                    echo impcomps: Could not find w4gldev.exe or w4glapp.exe
if /i "%W4GLDEV_FOUND%" NEQ "TRUE"                    goto end

if "%DBNAME%"          ==  ""                         echo impcomps: 4GL Database is not defined
if "%DBNAME%"          ==  ""                         goto end
if "%APPNAME%"          ==  ""                        echo impcomps: Application name is not defined
if "%APPNAME%"          ==  ""                        goto end
if "%OR_APPS_HOME%"          ==  ""                   echo impcomps: OR_APPS_HOME environment variable is not defined
if "%OR_APPS_HOME%"          ==  ""                   goto end
if NOT EXIST "%OR_APPS_HOME%\."                       echo impcomps: Directory "%OR_APPS_HOME%" does not exist
if NOT EXIST "%OR_APPS_HOME%\."                       goto end
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%"               echo impcomps: Directory "%OR_APPS_HOME%\%APPNAME%" does not exist
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%"               goto end
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%\export_comps.lst" echo impcomps: File "%OR_APPS_HOME%\%APPNAME%\export_comps.lst" does not exist
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%\export_comps.lst" goto end

if "%FLAGS%"          ==  ""                          set FLAGS=-nreplace -Limpcomps.log -Tyes,logonly

PUSHD "%OR_APPS_HOME%\%APPNAME%"

:: Create log file in current directory
SET II_LOG=.

::
::  Import components
::
echo Importing components ...
"%W4GLAPP_EXE%" backupapp in %DBNAME% %APPNAME% export_comps.lst -l -xml -t %FLAGS%
if errorlevel 1  echo ERROR importing components for application.
if errorlevel 1  goto fin

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
:fin
POPD
endlocal
:end
