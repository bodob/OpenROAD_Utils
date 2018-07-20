@echo off
setlocal
::
:: Copyright (c) 2018 Actian Corporation
::
:: Name: impappcomps.bat
::
:: Imports an application and all its components from a %OR_APPS_HOME%\<application> directory.
::   - Imports the application source from the file <application>.dsc (in XML format) in %OR_APPS_HOME%\<application>
::   - Imports the components export files <component>.xml (in XML format) in %OR_APPS_HOME%\<application>
::     using a component list file "export_comps.lst" in the same directory.
:: Requirements:
::	 %II_SYSTEM%\ingres\bin\w4gldev.exe or %OR_SYSTEM%\ingres\bin\w4glapp.exe must exist.
::   OR_APPS_HOME environment variable must be set and point to a writeable directory.
::   Directory %OR_APPS_HOME%\<application> must exist and contain files <application>.dsc,
::   "export_comps.lst" and the *.xml files referenced in "export_comps.lst".

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

if /i "%W4GLDEV_FOUND%" NEQ "TRUE"                    echo impappcomps: Could not find w4gldev.exe or w4glapp.exe
if /i "%W4GLDEV_FOUND%" NEQ "TRUE"                    goto end

if "%DBNAME%"          ==  ""                         echo impappcomps: 4GL Database is not defined
if "%DBNAME%"          ==  ""                         goto end
if "%APPNAME%"          ==  ""                        echo impappcomps: Application name is not defined
if "%APPNAME%"          ==  ""                        goto end
if "%OR_APPS_HOME%"          ==  ""                   echo impappcomps: OR_APPS_HOME environment variable is not defined
if "%OR_APPS_HOME%"          ==  ""                   goto end
if NOT EXIST "%OR_APPS_HOME%\."                       echo impappcomps: Directory "%OR_APPS_HOME%" does not exist
if NOT EXIST "%OR_APPS_HOME%\."                       goto end
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%"               echo impappcomps: Directory "%OR_APPS_HOME%\%APPNAME%" does not exist
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%"               goto end
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%\%APPNAME%.dsc" echo impappcomps: File "%OR_APPS_HOME%\%APPNAME%\%APPNAME%.dsc" does not exist
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%\%APPNAME%.dsc" goto end
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%\export_comps.lst" echo impappcomps: File "%OR_APPS_HOME%\%APPNAME%\export_comps.lst" does not exist
if NOT EXIST "%OR_APPS_HOME%\%APPNAME%\export_comps.lst" goto end

if "%FLAGS%"          ==  ""                          set FLAGS=-nreplace -Limpappcomps.log -Tyes,logonly

PUSHD "%OR_APPS_HOME%\%APPNAME%"

:: Create log file in current directory
SET II_LOG=.

::
::  Import application export file (AppSource only)
::
echo Importing application (appsource) ...
"%W4GLAPP_EXE%" backupapp in %DBNAME% %APPNAME% %APPNAME%.dsc -xml %FLAGS%
if errorlevel 1  echo ERROR importing application
if errorlevel 1  goto fin

::
::  Import components
::
echo Importing components ...
"%W4GLAPP_EXE%" backupapp in %DBNAME% %APPNAME% export_comps.lst -l -xml -t -A %FLAGS%
if errorlevel 1  echo ERROR importing components for application.
if errorlevel 1  goto fin

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
:fin
POPD
endlocal
:end
