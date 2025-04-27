# Script to copy files from NAS to cloud
param (
    [string]$rootfolder = (Split-Path -Path $PSScriptRoot -Leaf)  # Automatically gets the folder name where the script is placed
)
# Fully qualified directories required ("C:/path/to/source")
$sourceDir = "E:\$rootfolder"
$targetDir = "Z:\$rootfolder"

# create / override alive.txt
#New-Item -ItemType file $targetDir\alive.txt -Force > $null 2>&1
#(gci $targetDir\alive.txt).LastWriteTime = Get-Date

# find files older than 60 seconds (excluding directories) and move them
Get-Childitem -Path $sourceDir -Recurse |
    Where-Object {$_.LastWriteTime -lt (Get-Date).AddSeconds(-60)} |
    foreach {
        $isContainer = $_.PSIsContainer
        $sourceFile = $_.FullName
        $targetFile = $targetDir + $sourceFile.Substring($sourceDir.Length)
        $targetFileDir = $targetFile.Substring(0, $targetFile.Length - $_.Name.Length)

        if ($isContainer) {
            # directories must not be shortened further after replacing the source dir
            $targetFileDir = $targetFile
        }

        # create target directory if it does not already exist
        $targetFileDirExists = Test-Path -Path $targetFileDir
        if (!$targetFileDirExists) {
            New-Item -ItemType Directory -Path $targetFileDir -Force > $null 2>&1
        }

        # move file
        $targetFileDirExists = Test-Path -Path $targetFileDir
        if (!($isContainer) -and $targetFileDirExists) {
            Move-Item $_.FullName -destination $targetFile -Force > $null 2>&1
            if ($?) {
                "$(Get-Date -Format "HH:mm:ss") Successfully moved $sourceFile to $targetFile"
            } else {
                "Error copying $sourceFile"
            }
        } elseif(!$isContainer) {
            "Could not create directory $targetFileDir. Did not move of $sourceFile."
        }
    }

