function Get-Uptime
{
        
    <#
        .Synopsis 
            Gets the Uptime for the target machine.
            
        .Description
            Gets the Uptime for the target machine.
            
        .Parameter ComputerName
            Target to the Get-Uptime Command
            
        .Example
            Get-Uptime -ComputerName MyPC
            Description
            -----------
            Gets uptimne for MyPC
            
        .Example
            $Serverse | Get-Uptime 
            Description
            -----------
            Gets uptime for all the servers in the pipeline
    
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Notes
            NAME:      Get-Uptime
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [cmdletbinding()]
    Param(
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
    )
    
    Process 
    {
    
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host $ComputerName -TCPPort 135)
        {
            try
            {
                $os = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName -Property LastBootUpTime,LocalDateTime -ea STOP
                $uptime = [DateTime]::ParseExact($os.LastBootUpTime.Split(".")[0],"yyyyMMddHHmmss",$null)
                $RemoteTime = [DateTime]::ParseExact($os.LocalDateTime.Split(".")[0],"yyyyMMddHHmmss",$null)
                $timespan = $RemoteTime - $Uptime
                
                $myobj = @{}
                $myobj.ComputerName = $ComputerName
                $myobj.Uptime  = "\\$ComputerName has been up for: $($timespan.days) days, $($timespan.Hours) hours, $($timespan.Minutes) minutes, $($timespan.seconds) seconds"
                $myobj.Days    = $timespan.days
                $myobj.Hours   = $timespan.hours
                $myobj.Minutes = $timespan.minutes
                $myobj.Seconds = $timespan.Seconds
                
                $obj = New-Object PSObject -Property $myobj
                $obj.PSTypeNames.Clear()
                $obj.PSTypeNames.Add('BSonPosh.UPtime')
                $obj
            }
            catch
            {
                Write-Host " Host [$ComputerName] Failed with Error: $($Error[0])" -ForegroundColor Red
            }
        }
        else
        {
            Write-Host " Host [$ComputerName] Failed Connectivity Test " -ForegroundColor Red
        }
    
    }
}
    
