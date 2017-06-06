<#
.Synopsis
   Get scheduled Restart-Computer job and associated script.
.DESCRIPTION
   Get Scheduled Restart-Computer job and associated script.
.PARAMETER Name
    The full name of the scheduled restart computer job if known.
.PARAMETER JobNamePrefix
    The prefix of the scheduled restart computer job exists to differentiate
    the restart jobs from other PowerShell scheduled jobs.
.PARAMETER ScriptFilePath
    The path to the script file that is executed by the scheduled restart computer
    job. 
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 6/2/2017
.EXAMPLE
   Get-ScheduledRestartComputerJob
.EXAMPLE
   Get-ScheduledRestartComputerJob -JobNamePrefix 'RestartComputerJob' -ScriptFilePath 'C:\Scripts'
#>
#Requires -RunAsAdministrator
#Requires -Modules PSScheduledJob,ScheduledTasks
function Get-ScheduledRestartComputerJob
{
    [CmdletBinding()]
    Param
    (
        [string]$Name,
        [string]$JobNamePrefix = 'RestartComputer-',
                
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$ScriptFilePath="C:\Temp\"

    )

    Begin
    {
    }
    Process
    {

        # Forcing the import of ScheduledTasks to avoid conflict with Carbon\Get-ScheduledTask
        Import-Module ScheduledTasks
        Write-Verbose -Message 'Gathering existing Restart Jobs.'
        if ($Name) {
            $RestartJobs = Get-ScheduledJob | Where-Object -FilterScript {$_.Name -like "*$Name*"}    
        }
        else {
            $RestartJobs = Get-ScheduledJob | Where-Object -FilterScript {$_.Name -like "$JobNamePrefix*"}
        }
        
        foreach ($RestartJob in $RestartJobs) {
            
            $IsJobExpired = $false
            
            Write-Verbose "Checking state of RestartJob $($RestartJob.Name)."
            $RestartJobStatus = Get-ScheduledTask -TaskPath '\Microsoft\Windows\PowerShell\ScheduledJobs\' -TaskName $RestartJob.Name
            Write-Verbose "RestartJob $($RestartJob.Name) is currently $($RestartJobStatus.State)."

            foreach ($JobTrigger in $RestartJob.JobTriggers) {
                
                if ($JobTrigger.At -lt $(Get-Date)) {
                    Write-Verbose "JobTrigger for $($RestartJob.Name) has expired."
                    $IsJobExpired = $true
                    }
                }
        
            $RestartJobScriptPath = $ScriptFilePath + $RestartJob.Name + ".ps1"

            $ScheduledRestartComputerJobProperties = [ordered]@{
                    'Id' = $RestartJob.Id
                    'Name' = $RestartJob.Name
                    'JobTrigger' = $RestartJob.JobTriggers[0].At
                    'JobStatus' = $RestartJobStatus.State
                    'JobScript' = $RestartJobScriptPath
                    'IsJobExpired' = $IsJobExpired
                    'Enabled' = $RestartJob.Enabled
                    'JobScriptSource' = if (Test-Path $RestartJobScriptPath) {Get-Content -Path $RestartJobScriptPath}
                }

            $ScheduledRestartComputerJob = New-Object -TypeName PSCustomObject -Property $ScheduledRestartComputerJobProperties
            $ScheduledRestartComputerJob

            }
    }
    End
    {
    }
}