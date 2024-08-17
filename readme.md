
## AntiSandwichMan's Elden Ring Save Manager

A PowerShell script which functions as a very basic save backup manager. Backup & restore your Elden Ring saves without having to worry about manually copying the save directory.

## Features

 - Create backups of your Elden Ring save data
 - Add notes to your backups so you can include more information if desired
 - Restore from backups you've made through the script
 - Delete previous backups
 - View a list of all backups you've made, with your notes and timestamp next to each backup

## Usage

 Download the script, open PowerShell, and `Set-Location` into the directory where the script is located. If you have not changed your execution policy before, you'll need to run (from an Admin PowerShell window) `Set-ExecutionPolicy Unrestricted` to be able to run the script.
 
 To view the interactive menu (recommended):
 

    .\ASM-ERSM.ps1

The menu gives you the full suite options outlined in the Features section above.


Some operations you can bypass the menu to do quickly:

    .\ASM-ERSM.ps1 -operation "backup" # This will make a quick backup of your current save data
    .\ASM-ERSM.ps1 -operation "list" # This will give you a list of past backups
    Get-Help .\ASM-ERSM.ps1 # Shows help page for the script

## Configuration & Other Notes on Functionality

Elden Ring save files are located in the `%APPDATA%\Elden Ring` directory. By default, the script will create a few items within this folder. 

 - **ASM-ERSM.json** - Stores the random numbers that ER uses as your save folder, as well as the full path to the save folder
 - **backupnotes.json** - A record is stored in this file any time a backup is created through the script, each entry includes: 
	 - The name given to the backup
	 - The description / notes on the backup, if any
	 - The date & time that the backup was taken on
 - **Backup** (this is a directory) - Stores all the save backups

The backup function of the script works by making a copy of the folder with the random numbers that houses all save data, copies it into the Backup folder, and makes note within the JSON file that it exists. 

Optional configuration changes you can choose to make, if desired:

 - If you would like to edit the description of any of your backups, you can do so by opening the backupnotes.json file in your favorite text editor. 
 - If you would like to relocate either JSON file, make sure to change the *settingsFile* and *notesFile* variables within the script to reflect their new
 - If you would like to be able to run the script from any working directory (getting rid of the need to Set-Location or CD into the directory in which you have the script saved), you can add the folder the script lives within to your PATH variable, either manually or using option 6 on the menu. Note that in order for option 6 to work, the script will need to be running from an Admin PowerShell session.
