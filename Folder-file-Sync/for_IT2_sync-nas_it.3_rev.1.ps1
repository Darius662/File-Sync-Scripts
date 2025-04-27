# Define the root folder based on the script location
param (
    [string]$rootfolder = (Split-Path -Path $PSScriptRoot -Leaf)  # Automatically gets the folder name where the script is placed
)

# Define the file age threshold (in seconds)
$fileAgeThreshold = 120  # Files must be older than this threshold to be moved

# Define source paths with network share
$sourceE = "E:\$rootfolder"
$sourceZ = "Z:\emil-input\OFMT\$rootfolder"
$folders = @("OFMT_IN", "emil_ofmt")

# Define log file path within a "Logs" folder in the script's directory
$logFolder = Join-Path -Path $PSScriptRoot -ChildPath "Logs"
$logFile = Join-Path -Path $logFolder -ChildPath "UploadLog_$(Get-Date -Format 'yyyy-MM-dd').log"

# Create the Logs directory if it doesn't exist
if (-not (Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force
}

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

# Check if source and destination paths are available
if (!(Test-Path -Path $sourceE)) {
    Write-Log "Source E path not accessible: $sourceE"
    exit
}
if (!(Test-Path -Path $sourceZ)) {
    Write-Log "Destination Z path not accessible: $sourceZ"
    exit
}

# Upload function
function UploadFolder {
    param (
        [string]$folderName
    )

    $sourceFolderPath = Join-Path -Path $sourceE -ChildPath $folderName
    $destFolderPath = Join-Path -Path $sourceZ -ChildPath $folderName

    if (Test-Path -Path $sourceFolderPath) {
        # Ensure destination directory exists
        New-Item -ItemType Directory -Path $destFolderPath -Force | Out-Null

        # Move files older than $fileAgeThreshold
        $currentTime = Get-Date
        Get-ChildItem -Path $sourceFolderPath -File -Recurse | Where-Object {
            ($currentTime - $_.LastWriteTime).TotalSeconds -ge $fileAgeThreshold
        } | ForEach-Object {
            $relativePath = $_.FullName.Substring($sourceFolderPath.Length).TrimStart('\')
            $destFilePath = Join-Path -Path $destFolderPath -ChildPath $relativePath
            New-Item -ItemType Directory -Path (Split-Path -Path $destFilePath) -Force | Out-Null  # Ensure subdirectory exists
            Move-Item -Path $_.FullName -Destination $destFilePath -Force
            Write-Log "Moved file from $($_.FullName) to $destFilePath"
        }

        Write-Log "Upload complete for folder: $folderName"
    } else {
        Write-Log "Source folder does not exist: $sourceFolderPath. Skipping."
    }
}

# Start the upload process
Write-Log "Starting upload..."
foreach ($folder in $folders) {
    UploadFolder -folderName $folder
}
Write-Log "Upload process complete."

#   Ordered Upload: Processes "OFMT" first and then "emil_ofmt" based on the $folders array.
#   Directory Creation: Ensures all necessary directories are created in Z:/ before moving files.
#   Logging: Tracks all operations, including skipped folders, successful moves, and completion times.
