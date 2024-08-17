<#
.SYNOPSIS
    Provides backup, restore, and management for Elden Ring save files.

.DESCRIPTION
    This script simplifies the process of backing up, restoring, and managing Elden Ring saves.
    It automatically detects the current save location and provides a user-friendly menu 
    for various operations.

.PARAMETER operation
    Optional parameter to perform a specific action without using the interactive menu:
        * 'backup': Creates a quick backup with the current date and time.
        * 'list': Lists existing backups.
        * 'help': Displays the script's help information.

.EXAMPLE
    .\EldenRingBackup.ps1 backup
    Creates a quick backup of the current save.

    .\EldenRingBackup.ps1 list
    Lists all available backups with their details.

    .\EldenRingBackup.ps1
    Launches the interactive menu for manual backup, restore, and management.

.NOTES
    * Ensure that PowerShell execution policy allows running scripts (e.g., 'Set-ExecutionPolicy RemoteSigned').
    * This script assumes the default save location for Elden Ring on Windows.
    * Backups are stored in the 'Backup' folder within the save directory.
#>

param(
    [string]$operation
)

# Error messages used throughout the script
$errorMessages = @{
    backupNotFound = "A backup with the provided name cannot be found"
    backupAlreadyExists = "There already exists a backup with the requested name"
    cancelledByUser = "Operation cancelled by user"
}

# Default save location for Elden Ring on Windows
$saveLocation = "C:\Users\$env:Username\AppData\Roaming\EldenRing"
$settingsFile = "$saveLocation\ASM-ERSM.json"
$notesFile = "$saveLocation\backupnotes.json"

# Find the current Elden Ring save directory
$currentSaveDir = Get-ChildItem -Path $saveLocation | Where-Object { $_.PSIsContainer -and $_.Name -match "^\d+$" }
$currentSave = $currentSaveDir.FullName

# Default settings if the settings file doesn't exist
$defaultSettings = @{
    backupLocation = "$saveLocation\Backup"
    numbers = $currentSaveDir.Name
}

# Default notes if the notes file doesn't exist
$defaultNotes = @{
    notes = @()
}

# Create the settings file with default values if it doesn't exist
if(-not (Test-Path $settingsFile)){
    $defaultSettings | ConvertTo-Json -Depth 100 | Set-Content -Path $settingsFile
}

# Create the notes file with default values if it doesn't exist
if(-not (Test-Path $notesFile)){
    $defaultNotes | ConvertTo-Json -Depth 100 | Set-Content -Path $notesFile
}

# Load settings from the JSON file
$settings = Get-Content $settingsFile -ErrorAction Stop | Out-String | ConvertFrom-Json
$notes = Get-Content $notesFile -ErrorAction Stop | Out-String | ConvertFrom-Json

<#
.FUNCTION Save-JSON
.SYNOPSIS
    Saves a JSON object to a specified file path.

.PARAMETER json
    The JSON object to be saved.

.PARAMETER path
    The file path where the JSON object should be saved.
#>
function Save-JSON{
    param(
        [System.Object]$json,
        [string]$path
    )

    $json | ConvertTo-Json -Depth 100 | Set-Content -Path $path
}

<#
.FUNCTION Wait-ForInput
.SYNOPSIS
    Pauses the script and waits for the user to press Enter.
#>
function Wait-ForInput{
    Read-Host -Prompt "Press Enter to continue"
}

<#
.FUNCTION Backup-Save
.SYNOPSIS
    Creates a backup of the current Elden Ring save.

.PARAMETER name
    The name to give the backup.

.PARAMETER backupnotes
    Optional description for the backup.
#>
function Backup-Save{
    param(
        [string]$name,
        [string]$backupnotes
    )
    if($backupnotes -eq ""){
        $backupnotes = "No description provided"
    }
    $newBackup = @{
        name = $name
        description = $backupnotes
        backupdate = Get-Date -Format "MM/dd/yyyy, HH:mm"
    }

    if(-not (Test-Path -PathType Container $settings.backupLocation)){
        New-Item -ItemType Directory -Path $settings.backupLocation
    }

    Copy-Item -Path $currentSave -Destination $settings.backupLocation -Recurse -Force
    if(Test-Path -PathType Container "$($settings.backupLocation)\$name"){
        Write-Error $errorMessages.backupAlreadyExists
        Remove-Item -Path "$($settings.backupLocation)\$($settings.numbers)" -Recurse -Force
        return
    }

    Rename-Item -Path "$($settings.backupLocation)\$($settings.numbers)" -NewName $name
    $notes.notes += $newBackup
    $notes.notes = $notes.notes | Sort-Object { $_.backupdate } -Descending
    Save-JSON -json $notes -path $notesFile
}

<#
.FUNCTION Remove-Backup
.SYNOPSIS
    Deletes a specified backup.

.PARAMETER name
    The name of the backup to delete.
#>
function Remove-Backup{
    param(
        [string]$name
    )
    try{
        if(-not (Test-Path -PathType Container "$($settings.backupLocation)\$name")){
            Write-Error $errorMessages.backupNotFound
        }
        Remove-Item -Path "$($settings.backupLocation)\$name" -Recurse -Force
        $notes.notes = $notes.notes | Where-Object { $_.name -ne $name }
        Save-JSON -json $notes -path $notesFile
    }catch{
        return
    }
}

<#
.FUNCTION Restore-Save
.SYNOPSIS
    Restores a specified backup as the current save.

.PARAMETER name
    The name of the backup to restore.
#>
function Restore-Save{
    param(
        [string]$name
    )
    $tempBackupName = "temp-"
    try{
        Backup-Save -name $tempbackupName -backupnotes "Temporary backup made prior to restore operation"
        if(-not (Test-Path -PathType Container "$($settings.backupLocation)\$name")){
            Write-Error $errorMessages.backupNotFound
        }
        Write-Debug "Backup found"
        Copy-Item -Path "$($settings.backupLocation)\$name" -Destination $saveLocation -Recurse -Force
        Remove-Item -Path "$saveLocation\$($settings.numbers)" -Recurse -Force
        Rename-Item "$saveLocation\$name" -NewName $settings.numbers
        if(Test-Path -PathType Container "$saveLocation\$($settings.numbers)"){
            Remove-Backup -name $tempBackupName
        }
    }catch{
        return
    }
}

<#
.FUNCTION Get-Saves
.SYNOPSIS
    Lists all available backups with their details.
#>
function Get-Saves{
    # Get the width of the console window
    $consoleWidth = $Host.UI.RawUI.WindowSize.Width 

    foreach($note in $notes.notes){
        # Calculate padding for right-alignment
        $padding = " " * ($consoleWidth - $note.name.Length - $note.backupdate.Length - 2) 

        # Format the output with padding
        $formattedLine = "{0}{1} {2}" -f $note.name, $padding, $note.backupdate
        Write-Host $formattedLine -ForegroundColor Green

        Write-Host "$($note.description)`n"
    }
}

# Handle automatic actions if specified
if($operation -eq "backup"){
    Backup-Save -name "QUICKSAVE-$(Get-Date -Format "yyyyMMdd_HHmm")" -backupnotes "This is a quicksave"
}elseif($operation -eq "list"){
    Get-Saves
}elseif ($operation -eq "help") { 
    Get-Help $MyInvocation.MyCommand.Path # Display help from comment-based help
}else{
    # Interactive menu
    While($true){
        Clear-Host
        Write-Host "MENU OPTIONS"
        Write-Host "------------"
        Write-Host "1. Backup"
        Write-Host "2. Restore backup"
        Write-Host "3. Delete backup"
        Write-Host "4. List backups"
        Write-Host "5. Help"
        Write-Host "6. Exit"
        $action = Read-Host -Prompt "Choice"
        switch($action){
            1{
                $backup = Read-Host -Prompt "Enter the name for your backup, or simply EXIT to cancel backup"
                $backupnotes = Read-Host -Prompt "Enter a description for the backup (or leave blank)"
                if($backup -eq "EXIT"){
                    Write-Error $errorMessages.cancelledByUser
                    break
                }
                Backup-Save -name $backup -backupnotes $backupnotes
                Wait-ForInput
            }
            2{
                $backupToRestore = Read-Host -Prompt "Enter the name of the backup to restore"
                Restore-Save -name $backupToRestore
                Wait-ForInput
            }
            3{
                $backupToDelete = Read-Host -Prompt "Enter the name of the backup to delete"
                Remove-Backup -name $backupToDelete
                Wait-ForInput
            }
            4{
                Get-Saves
                Wait-ForInput
            }
            5{ # Handle help option
                Get-Help $MyInvocation.MyCommand.Path
                Wait-ForInput
            }
            6{
                exit
            }
        }
    }
}