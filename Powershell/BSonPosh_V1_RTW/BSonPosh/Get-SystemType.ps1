function Get-SystemType
{
        
    <#
        .Synopsis 
            Gets the system type for specified host
            
        .Description
            Gets the system type info for specified host
            
        .Parameter ComputerName
            Name of the Computer to get the System Type from (Default is localhost.)
            
        .Example
            Get-SystemType
            Description
            -----------
            Gets System Type from local machine
    
        .Example
            Get-SystemType -ComputerName MyServer
            Description
            -----------
            Gets System Type from MyServer
            
        .Example
            $Servers | Get-SystemType
            Description
            -----------
            Gets System Type for each machine in the pipeline
            
        .OUTPUTS
            PSObject
            
        .Notes
            NAME:      Get-SystemType 
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
    
    Begin 
    {
    
        function ConvertTo-ChassisType($Type)
        {
            switch ($Type)
            {
                1    {"Other"}
                2    {"Unknown"}
                3    {"Desktop"}
                4    {"Low Profile Desktop"}
                5    {"Pizza Box"}
                6    {"Mini Tower"}
                7    {"Tower"}
                8    {"Portable"}
                9    {"Laptop"}
                10    {"Notebook"}
                11    {"Hand Held"}
                12    {"Docking Station"}
                13    {"All in One"}
                14    {"Sub Notebook"}
                15    {"Space-Saving"}
                16    {"Lunch Box"}
                17    {"Main System Chassis"}
                18    {"Expansion Chassis"}
                19    {"SubChassis"}
                20    {"Bus Expansion Chassis"}
                21    {"Peripheral Chassis"}
                22    {"Storage Chassis"}
                23    {"Rack Mount Chassis"}
                24    {"Sealed-Case PC"}
            }
        }
        function ConvertTo-SecurityStatus($Status)
        {
            switch ($Status)
            {
                1    {"Other"}
                2    {"Unknown"}
                3    {"None"}
                4    {"External Interface Locked Out"}
                5    {"External Interface Enabled"}
            }
        }
    
    }
    Process 
    {
    
        Write-Verbose " [Get-SystemType] :: Process Start"
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host $ComputerName -TCPPort 135)
        {
            try
            {
                Write-Verbose " [Get-SystemType] :: Getting System (Enclosure) Type  info use WMI"
                $SystemInfo = Get-WmiObject Win32_SystemEnclosure -ComputerName $ComputerName
                Write-Verbose " [Get-SystemType] :: Creating Hash Table"
                $myobj = @{}
                Write-Verbose " [Get-SystemType] :: Setting ComputerName   - $ComputerName"
                $myobj.ComputerName = $ComputerName
                
                Write-Verbose " [Get-SystemType] :: Setting Manufacturer   - $($SystemInfo.Manufacturer)"
                $myobj.Manufacturer = $SystemInfo.Manufacturer
                
                Write-Verbose " [Get-SystemType] :: Setting SerialNumber   - $($SystemInfo.SerialNumber)"
                $myobj.SerialNumber = $SystemInfo.SerialNumber
                
                Write-Verbose " [Get-SystemType] :: Setting SecurityStatus - $($SystemInfo.SecurityStatus)"
                $myobj.SecurityStatus = ConvertTo-SecurityStatus $SystemInfo.SecurityStatus
                
                Write-Verbose " [Get-SystemType] :: Setting Type           - $($SystemInfo.ChassisTypes)"
                $myobj.Type = ConvertTo-ChassisType $SystemInfo.ChassisTypes
                
                Write-Verbose " [Get-SystemType] :: Creating Custom Object"
                $obj = New-Object PSCustomObject -Property $myobj
                $obj.PSTypeNames.Clear()
                $obj.PSTypeNames.Add('BSonPosh.SystemType')
                $obj
            }
            catch
            {
                Write-Verbose " [Get-SystemType] :: [$ComputerName] Failed with Error: $($Error[0])" 
            }
        }
    
    }
}
    
