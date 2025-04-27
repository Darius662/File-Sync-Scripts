param (
    [string]$rootfolder = (Split-Path -Path $PSScriptRoot -Leaf)  # Automatically gets the folder name where the script is placed
)

# Define source paths with network share
$sourceE = "E:\$rootfolder"
$sourceZ = "Z:\$rootfolder"

# Define log file path within a "Logs" folder in the script's directory
$logFolder = Join-Path -Path $PSScriptRoot -ChildPath "Logs"
$logFile = Join-Path -Path $logFolder -ChildPath "SyncLog_$(Get-Date -Format 'yyyy-MM-dd').log"

# Create the Logs directory if it doesn't exist
if (-not (Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force
}

# Time threshold for file age (in seconds)
$fileAgeThreshold = 60

# Function to write a log entry
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Output $logEntry  # Optional: also outputs log to the console
}

# Check if network paths are available
if (!(Test-Path -Path $sourceE)) {
    Write-Log "Source E path not accessible: $sourceE"
    exit
}
if (!(Test-Path -Path $sourceZ)) {
    Write-Log "Source Z path not accessible: $sourceZ"
    exit
}

# Function to sync main files from E:\ to Z:\, excluding specified folders
function SyncFilesFromEtoZ {
    # Move all files from $sourceE to $sourceZ, excluding _fehler, _logs, and _readme
    Get-ChildItem -Path $sourceE -File -Recurse | Where-Object {
        ($_.LastWriteTime -lt (Get-Date).AddSeconds(-$fileAgeThreshold)) -and
        ($_.FullName -notmatch "\\_fehler|\\_logs|\\_readme")
    } | ForEach-Object {
        $relativePath = $_.FullName.Substring($sourceE.Length).TrimStart('\')
        $destPath = Join-Path -Path $sourceZ -ChildPath $relativePath
        New-Item -ItemType Directory -Path (Split-Path -Path $destPath) -Force  # Ensure directory exists
        Move-Item -Path $_.FullName -Destination $destPath -Force
        Write-Log "Moved file from $($_.FullName) to $destPath"
    }
}

# Function to sync specific subfolders (_fehler, _logs, _readme) from Z:\ to E:\
function SyncSpecialFoldersFromZtoE {
    $subFolderNames = @("_fehler", "_logs", "_readme")
    
    foreach ($subFolder in $subFolderNames) {
        $sourceSubFolderPath = Join-Path -Path $sourceZ -ChildPath $subFolder
        $destSubFolderPath = Join-Path -Path $sourceE -ChildPath $subFolder

        if (Test-Path -Path $sourceSubFolderPath) {
            # Move files from Z:\_subFolder to E:\_subFolder if older than threshold
            Get-ChildItem -Path $sourceSubFolderPath -File | Where-Object {
                $_.LastWriteTime -lt (Get-Date).AddSeconds(-$fileAgeThreshold)
            } | ForEach-Object {
                $destFilePath = Join-Path -Path $destSubFolderPath -ChildPath $_.Name
                New-Item -ItemType Directory -Path $destSubFolderPath -Force  # Ensure directory exists
                Move-Item -Path $_.FullName -Destination $destFilePath -Force
                Write-Log "Moved file from $($_.FullName) to $destFilePath"
            }
        } else {
            Write-Log "Source subfolder does not exist: $sourceSubFolderPath. Skipping."
        }
    }
}

# Run the sync functions
Write-Log "Starting synchronization..."
SyncFilesFromEtoZ
SyncSpecialFoldersFromZtoE
Write-Log "Synchronization complete."
