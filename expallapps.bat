@echo off
setlocal enabledelayedexpansion
::
:: Copyright (c) 2018 Actian Corporation
::
:: Name: expallapps.bat
::
:: Exports all applications in XML format from a database repository
:: into the current directory (which must be writeable).
::
::	It calls "w4gldev backupapp out" for each application (with -xml flag).
::	Default "backupapp flags" are: -Tyes,logonly -Lexpallapps.log -A
::	When specifiying (overriding) them on command line,
::	flags containing comma or spaces have to be enclosed in double quotes.
::	You can use %A when specifying separate log files for each application, e.g.
::	expallapps localhostii::mydatabase "-Tyes,logonly" -L%A.log
::
:: Requirements:
::	%II_SYSTEM%\ingres\bin\sql.exe (terminal monitor) must exist.
::	%II_SYSTEM%\ingres\bin\w4gldev.exe must exist.

if /i "%~1" == "" goto usage

SET DBNAME=%~1
SET FLAGS=%~2 %~3 %~4 %~5 %~6 %~7 %~8 %~9
SET BATCHNAME=expallapps
::
::  Perform sanity checking before proceeding
::
if EXIST "%II_SYSTEM%\ingres\bin\w4gldev.exe" goto w4gl_found
echo %BATCHNAME%: Could not find w4gldev.exe & goto end
:w4gl_found

if EXIST "%II_SYSTEM%\ingres\bin\sql.exe" goto sql_found
echo %BATCHNAME%: Could not find sql.exe & goto end
:sql_found
set SQL_EXE=%II_SYSTEM%\ingres\bin\sql.exe


if "%DBNAME%" == "" echo %BATCHNAME%: 4GL Database is not defined & goto end
if "%FLAGS%" == "" set FLAGS=-Tyes,logonly -Lexpallapps.log -A

::
::  Create application list file apps.lst
::
echo Creating application list ...
if EXIST apps.lst del apps.lst
echo DECLARE GLOBAL TEMPORARY TABLE apps AS SELECT entity_name AS app FROM ii_entities WHERE version_number=0 AND entity_type='appsource' ON COMMIT PRESERVE ROWS WITH NORECOVERY; COPY session.apps(app=TEXT(0)nl) INTO 'apps.lst';\g\q | "%SQL_EXE%" -S %DBNAME%
if errorlevel 1  echo ERROR using sql to create apps.lst & goto fin
if NOT EXIST apps.lst echo ERROR: apps.lst could not be created & goto fin

set II_LOG=.
echo Exporting applications ...
for /f %%A in (apps.lst) DO w4gldev backupapp out %DBNAME% %%A %%A.xml -xml %FLAGS%

goto fin

:usage
echo.
echo USAGE:
echo.
echo         expallapps ^<database^> ^[^<backupapp flags^>^]
echo.
goto end
:fin
echo %BATCHNAME% finished.
endlocal
:end
