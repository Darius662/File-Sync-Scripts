# Script to redirect log into file for sync-nas script
$dateTime = Get-Date -UFormat "%Y-%m-%d"
$logName = $dateTime + "_Sync.log"

# setup repeat timer
$timer = New-TimeSpan -Minutes 1
$clock = [diagnostics.stopwatch]::StartNew()

# seconds after each script execution
# set to 60 or higher to disable repeat execution
$wait = 15

# the script repeats the command inside the loop until 1 minute has passed
# => the script will terminate when the last sleep expires and 1 minute has passed
# Example: 15 s wait after each script execution => max. 4 possible runs;
#   If the command needs 10 s to run, we get only 3 runs. After the third waiting period the script terminates
#   15 seconds past the 1 minute mark
while ($clock.elapsed -lt $timer) {
    powershell ./sync-nas.ps1 2>&1 >> $logName
    start-sleep -seconds $wait
}
