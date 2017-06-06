<#
.Synopsis
   Clean up expired Scheduled Restart-Computer jobs and scripts.
.DESCRIPTION
   Clean up expired Scheduled Restart-Computer jobs and scripts.
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
   Remove-ExpiredScheduledRestartComputerJob
.EXAMPLE
   Remove-ExpiredScheduledRestartComputerJob -JobNamePrefix 'RestartComputerJob' -ScriptFilePath 'C:\Scripts'
#>
#Requires -RunAsAdministrator
#Requires -Modules PSScheduledJob
function Remove-ExpiredScheduledRestartComputerJob
{
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param
    (
        
        [string]$JobNamePrefix = 'RestartComputer-',
                
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$ScriptFilePath="C:\Temp\"

    )

    Begin
    {
    }
    Process
    {

        Write-Verbose -Message 'Performing cleanup of any existing expired Restart Jobs.'
        $ExpiredRestartJobs = Get-ScheduledRestartComputerJob | Where-Object -FilterScript {$_.JobStatus -ne 'Running' -and $_.IsJobExpired}
        foreach ($RestartJob in $ExpiredRestartJobs) {
            Remove-ScheduledRestartComputerJob -Name $RestartJob.Name -WhatIf:$PSBoundParameters.ContainsKey('WhatIf')
            }
            
    }
    End
    {
    }
}