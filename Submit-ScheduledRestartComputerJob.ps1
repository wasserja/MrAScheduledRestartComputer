<#
.Synopsis
   Schedule a restart of a computer using PowerShell scheduled jobs.
.DESCRIPTION
   Schedule a restart of a computer. You can specify a time in the future
   when a computer or list of computers will be restarted.
.PARAMETER ComputerName
    Enter the name(s) of computers for which you need to schedule a restart.
.PARAMETER RestartDateTime
    Enter a date/time in the future for when you need to restart the provided
    computers. 
.PARAMETER JobNamePrefix
    The prefix of the scheduled restart computer job exists to differentiate
    the restart jobs from other PowerShell scheduled jobs.
.PARAMETER Timeout
    The timeout parameter specifies how long to allow the Restart-Computer job to wait
    until it gives up.
.PARAMETER WhatIf
    Use the WhatIf switch to add a -WhatIf paramter to the Restart-Computer command to test
    what would happen. 
.PARAMETER RestartCommandParameters
    You can put your custom parameters that will be added to the Restart-Computer command in 
    the scheduled restart computer job.
.PARAMETER Credential
    A credential object is required to schedule a restart of a remote computer.
.PARAMETER ScriptFilePath
    The path to the script file that is executed by the scheduled restart computer
    job. 
.PARAMETER JobLogPath
    The path where the scheduled restart computer job will store the transcript log.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 6/2/2017
.EXAMPLE
   Submit-ScheduledRestartComputer -ComputerName SERVER01 -RestartDateTime 11:30pm -Credential $Credential
.EXAMPLE
   Submit-ScheduledRestartComputer -ComputerName SERVER01 -RestartDateTime '1/1/2020 12:00 AM' -Credential $Credential
#>
#Requires -RunAsAdministrator
#Requires -Modules PSScheduledJob
function Submit-ScheduledRestartComputerJob
{
    [CmdletBinding(ConfirmImpact='High')]
    Param
    (

        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromPipeline=$true)]
        [string[]]$ComputerName,

        [Parameter(Mandatory=$true)]
        [ValidateScript({$_ -gt (Get-Date)})]
        [datetime]$RestartDateTime,
        
        [string]$JobNamePrefix = 'RestartComputer-',
                        
        [int]$Timeout=1200,

        [switch]$WhatIf,
        
        [string]$RestartCommandParameters = "-Wait -Force -Timeout $TimeOut -Verbose",
        
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$ScriptFilePath="C:\Temp\",

        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$JobLogPath = "C:\Logs\"

    )

    Begin
    {
    }
    Process
    {
        # Initialize variable naming 
        $ErrorActionPreference = 'Stop'
        $JobName = $JobNamePrefix + "$(Get-Date $RestartDateTime -Format 'yyyyMMddHHmmss')"
        $ScriptFileFullPath = $ScriptFilePath + "\$JobName.ps1"
        $JobLogFullPath = $JobLogPath + "\JobLog-$JobName.log"
        
        
        if ($PSBoundParameters.ContainsKey('WhatIf')) {
            $RestartCommandParameters += ' -WhatIf'
            }

# Here strings don't like white space. Please ignore the lack of identation.          
$Script = @"
Start-Transcript -Path $JobLogFullPath
Disable-NagiosHostNotifications -ComputerName $($ComputerName -join ',')
Restart-Computer -ComputerName $($ComputerName -join ',') $RestartCommandParameters
Enable-NagiosHostNotifications -ComputerName $($ComputerName -join ',')
Stop-Transcript
"@            
            
            try {
                # Writing the $Script out to a file to be executed by the scheduled job.
                Write-Output $Script | Out-File $ScriptFileFullPath -NoClobber
                
                # Creating the job trigger
                $Trigger = New-JobTrigger -Once -At $RestartDateTime
                
                # Create
                $Job = Register-ScheduledJob -Name $JobName -FilePath $ScriptFileFullPath -Trigger $Trigger -Credential $Credential
                #$Job
                Get-ScheduledRestartComputerJob | Where-Object -FilterScript {$_.Name -eq $Job.Name}                
                }
            catch {
                Write-Output $Error[0].Exception.Message
                }    
    
    }
    End
    {
    }
}
