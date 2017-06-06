<#
.Synopsis
   Remove scheduled Restart-Computer job and script.
.DESCRIPTION
   Remove scheduled Restart-Computer job and script.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 6/2/2017
.PARAMETER Name
    The full name of the scheduled restart computer job if known.
.PARAMETER JobNamePrefix
    The prefix of the scheduled restart computer job exists to differentiate
    the restart jobs from other PowerShell scheduled jobs.
.PARAMETER ScriptFilePath
    The path to the script file that is executed by the scheduled restart computer
    job. 
.EXAMPLE
   Remove-ScheduledRestartComputerJob
.EXAMPLE
   Remove-ScheduledRestartComputerJob -Name MyJob -JobNamePrefix 'RestartComputerJob' -ScriptFilePath 'C:\Scripts'
#>
#Requires -RunAsAdministrator
#Requires -Modules PSScheduledJob
function Remove-ScheduledRestartComputerJob
{
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param
    (
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
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

        Write-Verbose -Message 'Gathering Restart jobs to remove.'
        $RestartJobs = Get-ScheduledRestartComputerJob | Where-Object -FilterScript {$_.Name -like $Name}
        
        foreach ($RestartJob in $RestartJobs) {
            
            if ($RestartJob.JobStatus -eq 'Running') {
                Write-Warning -Message "RestartJob $($RestartJob.Name) is currently $($RestartJob.JobStatus). Skipping removal of job."
            }
            else {
                Write-Verbose -Message "RestartJob $($RestartJob.Name) is currently $($RestartJob.JobStatus). Proceeding to remove job."
                Write-Verbose -Message "Unregistering RestartJob $($RestartJob.Name)"
                Unregister-ScheduledJob -Id $RestartJob.Id
                if (Test-Path -Path $RestartJob.JobScript) {
                    Write-Verbose -Message "Deleting RestartJob Script $($RestartJob.JobScript)"
                    Remove-Item $RestartJob.JobScript
                    }
            }
            
        }
            
    }
    End
    {
    }
}