<#
  WSUS Management Tasks
  Author: Lloyd Folks
  Version: 1.00
  Copyright FOLKS Consulting, LLC | MIT License
 
  Description:
  Automate WSUS management such as deny updates by keywords such as x86, cleanup the WSUS server, and clean up the synchronization history using Task Scheduler.
  Usage:
  Task Scheduler via a scheduled task that runs based on your interval selection (weekly, monthly, quarterly)
  -OR-
  PS> .\wmt.ps1
  GitHub:
  https://github.com/folksconsulting/WSUS-Management-Tasks
#>

# Define Program Variables
$logFilePath = "C:\logs\wmt\" # Logfile path
$logFileName = "WMTLogFile.txt" # Logfile name
$maxLogFileSize = 5MB # Set the max size of the logfile. If invalid integer, null, or greater than 10MB, the value is set to the default 10MB
$daysToKeepLogs = 7  # Define the number of days to keep logs. If invalid integer or null, the default value of 7 days will be kept
$wsusServer = "wsus_hostname" # WSUS server hostname
$wsusPort = 8530 # WSUS port (default ports: http = 8530 or https = 8531)
# $wsusDatabase = "wsus_database_name_here" # WSUS database name (default SUSDB)
# $daysToKeepSyncHistory = 7 # Number of days to keep sync history
###

### Program Classes and Functions - DO NOT edit below this line

# Class for logging functions
class Logger {
    [string]$logFilePath
    [string]$logFileName
    [string]$logFile
    [int]$maxLogFileSize
    [int]$daysToKeepLogs

    Logger([string]$path, [string]$name, [int]$maxSize = 10MB, [int]$daysToKeep) {

        ### TODO: Validate that the value for $logFilePath can be a valid directory, if not default to C:\Logs\WMT\ as the directory.
        <#
            ## NOTE: Currently, this is checking if the path exists. There is already a method to create the directory if it doesn't exist.
            ## GOAL: Validate that the set path is a valid path and if not, fail to the default path of C:\Logs\WMT\
            # Validate logFilePath
            if (-not (Test-Path -Path $path -PathType Container)) {
                $path = "C:\Logs\WMT\"
            }
        #>
        $this.logFilePath = $path

        ### TODO: Validate that the value for $logFileName can be a valid filename, if not default to WMTLogFile.txt.
        <#
            ## NOTE: This needs further testing.
            ## GOAL: Validate that the set file name is a valid file name and if not, fail to default file name of WMTLogFile.txt
            # Validate logFileName
            $validFileName = [System.IO.Path]::GetInvalidFileNameChars() -notcontains ($name -split '\\')[-1]
            if (-not $validFileName) {
                $name = "WMTLogFile.txt"
            }
        #>
        $this.logFileName = $name

        $this.logFile = Join-Path -Path $this.logFilePath -ChildPath $this.logFileName

        # Validate and set maxLogFileSize
        if ($maxSize -gt 0) {
            $this.maxLogFileSize = $maxSize
        } else {
            $this.maxLogFileSize = 10MB
        }

        # Set days to keep logs
        if ($daysToKeep -gt 0) {
            $this.daysToKeepLogs = $daysToKeep
        } else {
            $this.daysToKeepLogs = 7  # Default value if null or invalid
        }
    }

    # Check if the directory exists; if not, create it
    [void]CheckLogFolder() {
        if (-not (Test-Path -Path $this.logFilePath -PathType Container)) {
            New-Item -Path $this.logFilePath -ItemType Directory -Force
        }
    }

    # Rotate log file if it exceeds the maximum size
    [void]RotateLogFile() {
        if ((Test-Path -Path $this.logFile) -and ((Get-Item $this.logFile).length -ge $this.maxLogFileSize)) {
            $timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
            $newFileName = "{0}_{1}" -f $this.logFileName, $timestamp
            Rename-Item -Path $this.logFile -NewName $newFileName
            New-Item -Path $this.logFilePath -ItemType File -Name $this.logFileName | Out-Null
        }
    }

    # Delete logs older than specified days
    [void]DeleteOldLogs() {
        $cutoffDate = (Get-Date).AddDays(-$this.daysToKeepLogs)
        $logFiles = Get-ChildItem -Path $this.logFilePath | Where-Object { $_.CreationTime -lt $cutoffDate }

        foreach ($file in $logFiles) {
            if ($file.Name -ne $this.logFileName) {
                Remove-Item -Path $file.FullName -Force
                $this.logger.LogToLogFile("Log File Removed:"+$file.FullName)
            }
        }
    }

    # Append log entry to the logfile with a timestamp
    [void]LogToLogFile([string]$message) {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $logEntry = "$timestamp - $message"
        try {
            $logEntry | Out-File -FilePath $this.logFile -Append -ErrorAction Stop
        }
        catch {
            Write-Host "Error writing to log file: $_"
            throw $_
        }
    }

    # Append log entry without timestamp
    [void]LogMessage([string]$message) {
        $message | Out-File -FilePath $this.logFile -Append
    }
}

# Initiate logger class
$logger = [Logger]::new($logFilePath, $logFileName, $maxLogFileSize, $daysToKeepLogs)
# Check log file folder location and create if needed
$logger.CheckLogFolder()
$logger.RotateLogFile()

# Class for handling time controls
class TimeControl {
    [Logger]$logger

    TimeControl([Logger]$logger) {
        $this.logger = $logger
    }

    # Get timestamp method
    [string]GetTimestamp() {
        return Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    [void]CalculateTimeDifference([datetime]$start, [datetime]$end) {
        try {
            $timeDifference = New-TimeSpan -Start $start -End $end
            $hours = $timeDifference.Hours
            $minutes = $timeDifference.Minutes
            $seconds = $timeDifference.Seconds

            $timeDifferenceMessage = "Total time taken: "

            # Format hours, minutes, and seconds for display
            if ($hours -gt 0) {
                $timeDifferenceMessage += "$hours hour(s), "
            }
            if ($minutes -gt 0) {
                $timeDifferenceMessage += "$minutes minute(s), "
            }
            $timeDifferenceMessage += "$seconds second(s)."

            $this.logger.LogMessage($timeDifferenceMessage)
        }
        catch {
            $errorMessage = "Error calculating time difference: $_"
            $this.logger.LogToLogFile($errorMessage)
            throw $_
        }
    }
}

# Initiate time control class
$timeControl = [TimeControl]::new($logger)

# Import the UpdateServices module
Import-Module -Name UpdateServices -ErrorAction Stop
# Class for WSUS Management Tasks
class WMT {
    [Logger]$logger
    [string]$wsusServer
    [int]$wsusPort

    WMT([Logger]$logger, [string]$wsusServer, [int]$wsusPort) {
        $this.logger = $logger
        $this.wsusServer = $wsusServer
        $this.wsusPort = $wsusPort
    }

    [void] TestWSUSConnection() {
        try {
            $this.logger.LogToLogFile("Starting WSUS Connection Test")
            $wsusConfig = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($this.wsusServer, $false, $this.wsusPort)

            if ($null -ne $wsusConfig) {
                $connectionStatus = "Connection to WSUS server successful."
                $this.logger.LogToLogFile($connectionStatus)
            } else {
                $connectionStatus = "Failed to connect to WSUS server."
                $this.logger.LogToLogFile($connectionStatus)
            }
            $this.logger.LogToLogFile("Completed WSUS Connection Test")
        } catch {
            $errorMessage = "Error occurred while testing WSUS connection: $_"
            $this.logger.LogToLogFile($errorMessage)
        }
    }

    [void] DeclineUpdates() {
        try {
            $this.logger.LogToLogFile("Starting Decline Update Process")
            $wsusConfig = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($this.wsusServer, $false, $this.wsusPort)
            $updates = $wsusConfig.GetUpdates()

            foreach ($update in $updates) {
                $title = $update.Title
                $isDeclined = $update.IsDeclined

                if ($title -like "*x86*" -or $title -like "*ARM64*" -and !$isDeclined) {
                    $declinedUpdateInfo = "Declining update: $($update.Title)"
                    $this.logger.LogMessage($declinedUpdateInfo)
                    $update.Decline()
                }
            }
            $this.logger.LogToLogFile("Completed Decline Update Process")
        } catch {
            $errorMessage = "Error occurred while declining updates: $_"
            $this.logger.LogToLogFile($errorMessage)
        }
    }

    [void] PerformCleanup() {
        try {
            $wsusConfig = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($this.wsusServer, $false, $this.wsusPort)

            # Define cleanupScope
            $cleanupScope = New-Object Microsoft.UpdateServices.Administration.CleanupScope
            $cleanupScope.DeclineSupersededUpdates = $true
            $cleanupScope.DeclineExpiredUpdates = $true
            $cleanupScope.CleanupObsoleteUpdates = $true
            $cleanupScope.CleanupObsoleteComputers = $true
            $cleanupScope.CleanupUnneededContentFiles = $true
            $cleanupScope.CompressUpdates = $true
            
            $cleanupManager = $wsusConfig.GetCleanupManager()
            $cleanupResults = $cleanupManager.PerformCleanup($cleanupScope)

            # Log cleanup results
            $cleanupResultsMessage =  "Cleanup Results:`n"
            $cleanupResultsMessage += "Declined Updates: $($cleanupResults.DeclinedUpdatesCount)`n"
            $cleanupResultsMessage += "Deleted Updates: $($cleanupResults.DeletedUpdatesCount)`n"
            $cleanupResultsMessage += "Computers Removed: $($cleanupResults.ComputersRemovedCount)`n"
            $cleanupResultsMessage += "Content Files Removed: $($cleanupResults.ContentFilesRemovedCount)`n"

            $this.logger.LogMessage($cleanupResultsMessage)
        } catch {
            $errorMessage = "Error occurred while performing cleanup: $_"
            $this.logger.LogToLogFile($errorMessage)
        }
    }
}

# Initiate WMT class
$WMT = [WMT]::new($logger, $wsusServer, $wsusPort)


# Start of script message
$startScriptTime = $timeControl.GetTimestamp()
$logger.LogMessage("=====================================================`n WSUS Management Tasks Started - $startScriptTime`n=====================================================`n")

### Script Body Start

$logger.LogMessage("Test WSUS Connection:`n")
$WMT.TestWSUSConnection()
$logger.LogMessage("`n=====================================================`n")

$logger.LogMessage("Decline Update Process:`n")
$startDeclineUpdates = $timeControl.GetTimestamp()
$WMT.DeclineUpdates()
$endDeclineUpdates = $timeControl.GetTimestamp()
$logger.LogToLogFile("Decline Updates:")
$timeControl.CalculateTimeDifference($startDeclineUpdates, $endDeclineUpdates)
$logger.LogMessage("`n=====================================================`n")

$logger.LogMessage("Perform WSUS Cleanup:`n")
$startPerformCleanup = $timeControl.GetTimestamp()
$WMT.PerformCleanup()
$endPerformCleanup = $timeControl.GetTimestamp()
$timeControl.CalculateTimeDifference($startPerformCleanup, $endPerformCleanup)
$logger.LogMessage("`n=====================================================`n")

### Script Body End

# End of script message
$endScriptTime = $timeControl.GetTimestamp()
$logger.LogMessage("Script Completion Time:")
$timeControl.CalculateTimeDifference($startScriptTime, $endScriptTime)
$logger.LogMessage("=======================================================`n WSUS Management Tasks Completed - $endScriptTime`n=======================================================`n")