# OpenROAD_Utils

This repository contains tools and utilities which can be useful when working with Actian OpenROAD.

## Tools for exporting & importing application and components ##

The following tools can be used on Windows to export/import applications and components (one file per component) using XML export format.

Requirements:

- The executable %`II_SYSTEM`%\ingres\bin\w4gldev.exe or %`OR_SYSTEM`%\ingres\bin\w4glapp.exe must exist.
- The `OR_APPS_HOME` environment variable must be set and point to a writeable directory.

### `expappcomps.bat` ###

Creates an `application` subdirectory under `OR_APPS_HOME` with an application export file (created using `-appsourceonly` flag) and export files for each component, using component list file `export_comps.lst`, which also gets created.
The names of the export files have the form:  `<name of application or component>`.`<extension>`  
The file extensions for the export files of application (default: `dsc`) and components (default: `xml`) are configurable using the `OR_FILEEXT_APP` and `OR_FILEEXT_COMP` environment variables, resp.  
The output of the export commands is written to the log file `expappcomps.log`. 

Additional requirement:

- `%II_SYSTEM%\ingres\bin\sql.exe` (terminal monitor) must exist.

Usage:

    expappcomps database application [backupapp flags]

### expallappcomps.bat ###

Exports all applications (incl all components) from a database repository.
It creates a list of all apllications in file `apps.lst` in the directory referenced by the `OR_APPS_HOME` environment variable and calls `expappcomps.bat` for each application, which creates and populates according subdirectories. 

Additional requirement:

- `%II_SYSTEM%\ingres\bin\sql.exe` (terminal monitor) must exist.

Usage:

    expappcomps database [backupapp flags]

### `impappcomps.bat` ###

Imports application and components by using the files created by `expappcomps.bat`.  
It imports (creates/overwrites) the application by using an application export file and imports the component export files (for each component), using the component list file `export_comps.lst`.  
The files must be located in the `application` subdirectory of `OR_APPS_HOME`.
The output of the import commands is written to the log file `impappcomps.log`. 

Usage:

    impappcomps database application [backupapp flags]

### `impcomps.bat` ###

Imports components by using the files created by `expappcomps.bat` into an existing application.  
It imports the component export files (for each component), using component list file `export_comps.lst`.  
The files must be located in the `application` subdirectory of `OR_APPS_HOME`.  
The output of the import commands is written to the log file `impcomps.log`. 

Usage:

    impcomps database application [backupapp flags]

## Bash scripts ##

The following utilities require a `bash` shell.  
On Windows it is provided by 3rd party packages like Cygwin.
For Cygwin/Windows make sure to set the SHELLOPTS environment variable to ignore carriage return characters (at the end of lines):

    SET SHELLOPTS=igncr

### `force_del_comp.bash` ###

Forces the deletion of an application component by deleting the rows for the component from the repository tables.  
This is a kind of "last resort cleanup action" if the component in the repository got corrupted, so it could not be deleted from the Workbench or using the according command line utility (w4gldev destroyapp *database* *application* -c*component*).

Usage:

    bash force_del_comp.bash database application component
