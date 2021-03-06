function Get-OSVersion
{
        
    <#
        .Synopsis 
            Gets the OS Version for specified host.
            
        .Description
            Gets the OS Version for specified host.
            
        .Parameter ComputerName
            Name of the Computer to get the OS Version from (Default is localhost.)
            
        .Example
            Get-OSVersion
            Description
            -----------
            Gets OS Version from local machine
    
        .Example
            Get-OSVersion -ComputerName MyServer
            Description
            -----------
            Gets OS Version from MyServer
            
        .Example
            $Servers | Get-OSVersion
            Description
            -----------
            Gets OS Version for each machine in the pipeline
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Link
            N/A
            
        .Notes
            NAME:      Get-OSVersion
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
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
        if(Test-Host -ComputerName $ComputerName -TCPPort 135)
        {
            try
            {
                $OSInfo = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName -ea STOP
                $myobj = @{}
                $myobj.ComputerName = $ComputerName
                $myobj.OSName = $OSInfo.Caption
                $myobj.OSVersion = $OSInfo.Version
                $myobj.ServicePack = $OSInfo.ServicePackMajorVersion
                
                $obj = New-Object PSObject -Property $myobj
                $obj.PSTypeNames.Clear()
                $obj.PSTypeNames.Add('BSonPosh.OSVersion')
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
    
