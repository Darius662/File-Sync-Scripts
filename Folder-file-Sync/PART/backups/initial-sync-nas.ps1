param (
    [string]$rootfolder = (Split-Path -Path $PSScriptRoot -Leaf)  # Automatically gets the folder name where the script is placed
)

# Define source paths
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

# Function to sync main folders from E:\ to Z:\ if files are older than the threshold
function SyncMainFoldersToZ {
    $sourcePaths = Get-ChildItem -Path "$sourceE" -Recurse -Directory
    foreach ($sourcePath in $sourcePaths) {
        $relativePath = $sourcePath.FullName.Substring($sourceE.Length)
        $destPath = Join-Path -Path $sourceZ -ChildPath $relativePath

        # Only move files from E: to Z: in the main folders, excluding specific subfolders
        if (!(($relativePath -match "_fehler") -or ($relativePath -match "_logs") -or ($relativePath -match "_readme"))) {
            if (Test-Path -Path $destPath) {
                # Move files older than the threshold from E: to Z:
                Get-ChildItem -Path $sourcePath.FullName -File | Where-Object {
                    ($_.LastWriteTime -lt (Get-Date).AddSeconds(-$fileAgeThreshold))
                } | ForEach-Object {
                    Move-Item -Path $_.FullName -Destination $destPath -Force
                    Write-Log "Moved file from $($_.FullName) to $destPath"
                }
            } else {
                Write-Log "Destination directory does not exist: $destPath. Skipping."
            }
        }
    }
}

# Function to sync specific sub folders (_fehler, _logs, _readme) from Z:\ to E:\ if older than the threshold
function SyncSubFoldersToE {
    $subFolderNames = @("_fehler", "_logs", "_readme")
    
    foreach ($subFolder in $subFolderNames) {
        $sourcePaths = Get-ChildItem -Path "$sourceZ" -Recurse -Directory | Where-Object { $_.Name -eq $subFolder }
        foreach ($sourcePath in $sourcePaths) {
            $relativePath = $sourcePath.FullName.Substring($sourceZ.Length)
            $destPath = Join-Path -Path $sourceE -ChildPath $relativePath

            if (Test-Path -Path $destPath) {
                # Move files older than the threshold from Z: to E: in the specified subfolders only
                Get-ChildItem -Path $sourcePath.FullName -File | Where-Object {
                    ($_.LastWriteTime -lt (Get-Date).AddSeconds(-$fileAgeThreshold))
                } | ForEach-Object {
                    Move-Item -Path $_.FullName -Destination $destPath -Force
                    Write-Log "Moved file from $($_.FullName) to $destPath"
                }
            } else {
                Write-Log "Destination directory does not exist: $destPath. Skipping."
            }
        }
    }
}

# Run the sync functions
Write-Log "Starting synchronization..."
SyncMainFoldersToZ
SyncSubFoldersToE
Write-Log "Synchronization complete."
