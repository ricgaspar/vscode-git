function Get-MemoryConfiguration
{
        
    <#
        .Synopsis 
            Gets the Memory Config for specified host.
            
        .Description
            Gets the Memory Config for specified host.
            
        .Parameter ComputerName
            Name of the Computer to get the Memory Config from (Default is localhost.)
            
        .Example
            Get-MemoryConfiguration
            Description
            -----------
            Gets Memory Config from local machine
    
        .Example
            Get-MemoryConfiguration -ComputerName MyServer
            Description
            -----------
            Gets Memory Config from MyServer
            
        .Example
            $Servers | Get-MemoryConfiguration
            Description
            -----------
            Gets Memory Config for each machine in the pipeline
            
        .OUTPUTS
            PSCustomObject
            
        .Notes
            NAME:      Get-MemoryConfiguration 
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
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
    
        Write-Verbose " [Get-MemoryConfiguration] :: Begin Process"
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host $ComputerName -TCPPort 135)
        {
            Write-Verbose " [Get-MemoryConfiguration] :: Processing $ComputerName"
            try
            {
                $MemorySlots = Get-WmiObject Win32_PhysicalMemory -ComputerName $ComputerName -ea STOP
                foreach($Dimm in $MemorySlots)
                {
                    $myobj = @{}
                    $myobj.ComputerName = $ComputerName
                    $myobj.Description  = $Dimm.Tag
                    $myobj.Slot         = $Dimm.DeviceLocator
                    $myobj.Speed        = $Dimm.Speed
                    $myobj.SizeGB       = $Dimm.Capacity/1gb
                    
                    $obj = New-Object PSObject -Property $myobj
                    $obj.PSTypeNames.Clear()
                    $obj.PSTypeNames.Add('BSonPosh.MemoryConfiguration')
                    $obj
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
        Write-Verbose " [Get-MemoryConfiguration] :: End Process"
    
    }
}
    
