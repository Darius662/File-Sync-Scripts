param (
    [string]$rootfolder = (Split-Path -Path $PSScriptRoot -Leaf)  # Automatically gets the folder name where the script is placed
)

# Define source paths with network share
$sourceE = "E:\$rootfolder"
$sourceZ = "Z\Folder\$rootfolder"

# Define log file path within a "Logs" folder in the script's directory
$logFolder = Join-Path -Path $PSScriptRoot -ChildPath "Logs"
$logFile = Join-Path -Path $logFolder -ChildPath "UploadLog_$(Get-Date -Format 'yyyy-MM-dd').log"

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

# Function to upload files from E:\ to Z:\ for a specific folder
function UploadFolder {
    param (
        [string]$folderName
    )

    $sourcePath = Join-Path -Path $sourceE -ChildPath $folderName
    $destPath = Join-Path -Path $sourceZ -ChildPath $folderName

    if (Test-Path -Path $sourcePath) {
        Write-Log "Uploading files from $sourcePath to $destPath..."
        
        # Ensure the destination folder exists
        New-Item -ItemType Directory -Path $destPath -Force

        # Move files from source folder to destination folder if older than threshold
        Get-ChildItem -Path $sourcePath -File -Recurse | Where-Object {
            ($_.LastWriteTime -lt (Get-Date).AddSeconds(-$fileAgeThreshold))
        } | ForEach-Object {
            $destFilePath = Join-Path -Path $destPath -ChildPath $_.Name
            Move-Item -Path $_.FullName -Destination $destFilePath -Force
            Write-Log "Moved file from $($_.FullName) to $destFilePath"
        }
    } else {
        Write-Log "Source folder does not exist: $sourcePath. Skipping."
    }
}

# Start the upload process
Write-Log "Starting upload process..."

# Upload big_files first
UploadFolder -folderName "big_files"

# Upload small_files second
UploadFolder -folderName "small_files"

Write-Log "Upload process complete."
