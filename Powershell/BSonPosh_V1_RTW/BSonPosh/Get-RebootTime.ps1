function Get-RebootTime
{
        
    <#
        .Synopsis 
            Gets the reboot time for specified host.
            
        .Description
            Gets the reboot time for specified host.
            
        .Parameter ComputerName
            Name of the Computer to get the reboot time from (Default is localhost.)
            
        .Example
            Get-RebootTime
            Description
            -----------
            Gets OS Version from local     
        
        .Example
            Get-RebootTime -Last
            Description
            -----------
            Gets last reboot time from local machine
            
        
    
        .Example
            Get-RebootTime -ComputerName MyServer
            Description
            -----------
            Gets reboot time from MyServer
            
        .Example
            $Servers | Get-RebootTime
            Description
            -----------
            Gets reboot time for each machine in the pipeline
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Link
            N/A
            
        .Notes
            NAME:      Get-RebootTime
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [cmdletbinding()]
    Param(
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME,
        
        [Parameter()]
        [Switch]$Last
    )
    process 
    {
    
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host $ComputerName -TCPPort 135)
        {
            try
            {
                if($Last)
                {
                    $date = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName -ea STOP | foreach{$_.LastBootUpTime}
                    $RebootTime = [System.DateTime]::ParseExact($date.split('.')[0],'yyyyMMddHHmmss',$null)
                    $myobj = @{}
                    $myobj.ComputerName = $ComputerName
                    $myobj.RebootTime = $RebootTime
                    
                    $obj = New-Object PSObject -Property $myobj
                    $obj.PSTypeNames.Clear()
                    $obj.PSTypeNames.Add('BSonPosh.RebootTime')
                    $obj
                }
                else
                {
                    $Query = "Select * FROM Win32_NTLogEvent WHERE SourceName='eventlog' AND EventCode='6009'"
                    Get-WmiObject -Query $Query -ea 0 -ComputerName $ComputerName | foreach {
                        $myobj = @{}
                        $RebootTime = [DateTime]::ParseExact($_.TimeGenerated.Split(".")[0],'yyyyMMddHHmmss',$null)
                        $myobj.ComputerName = $ComputerName
                        $myobj.RebootTime = $RebootTime
                        
                        $obj = New-Object PSObject -Property $myobj
                        $obj.PSTypeNames.Clear()
                        $obj.PSTypeNames.Add('BSonPosh.RebootTime')
                        $obj
                    }
                }
    
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
    
