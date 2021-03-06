function Get-DiskSpace 
{
        
    <#
        .Synopsis  
            Gets the disk space for specified host
            
        .Description
            Gets the disk space for specified host
            
        .Parameter ComputerName
            Name of the Computer to get the diskspace from (Default is localhost.)
            
        .Example
            Get-Diskspace
            # Gets diskspace from local machine
    
        .Example
            Get-Diskspace -ComputerName MyServer
            Description
            -----------
            Gets diskspace from MyServer
            
        .Example
            $Servers | Get-Diskspace
            Description
            -----------
            Gets diskspace for each machine in the pipeline
            
        .OUTPUTS
            PSCustomObject
            
        .Notes
            NAME:      Get-DiskSpace 
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
        Write-Verbose " [Get-DiskSpace] :: Start Begin"
        $Culture = New-Object System.Globalization.CultureInfo("en-US") 
        Write-Verbose " [Get-DiskSpace] :: End Begin"
    }
    
    Process 
    {
        Write-Verbose " [Get-DiskSpace] :: Start Process"
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
            
        }
        Write-Verbose " [Get-DiskSpace] :: `$ComputerName - $ComputerName"
        Write-Verbose " [Get-DiskSpace] :: Testing Connectivity"
        if(Test-Host $ComputerName -TCPPort 135)
        {
            Write-Verbose " [Get-DiskSpace] :: Connectivity Passed"
            try
            {
                Write-Verbose " [Get-DiskSpace] :: Getting Operating System Version using - Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName -Property Version"
                $OSVersionInfo = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName -Property Version -ea STOP
                Write-Verbose " [Get-DiskSpace] :: Getting Operating System returned $($OSVersionInfo.Version)"
                if($OSVersionInfo.Version -gt 5.2)
                {
                    Write-Verbose " [Get-DiskSpace] :: Version high enough to use Win32_Volume"
                    Write-Verbose " [Get-DiskSpace] :: Calling Get-WmiObject -class Win32_Volume -ComputerName $ComputerName -Property `"Name`",`"FreeSpace`",`"Capacity`" -filter `"DriveType=3`""
                    $DiskInfos = Get-WmiObject -class Win32_Volume                          `
                                            -ComputerName $ComputerName                  `
                                            -Property "Name","FreeSpace","Capacity"      `
                                            -filter "DriveType=3" -ea STOP
                    Write-Verbose " [Get-DiskSpace] :: Win32_Volume returned $($DiskInfos.count) disks"
                    foreach($DiskInfo in $DiskInfos)
                    {
                        $myobj = @{}
                        $myobj.ComputerName = $ComputerName
                        $myobj.OSVersion    = $OSVersionInfo.Version
                        $Myobj.Drive        = $DiskInfo.Name
                        $Myobj.CapacityGB   = [float]($DiskInfo.Capacity/1GB).ToString("n2",$Culture)
                        $Myobj.FreeSpaceGB  = [float]($DiskInfo.FreeSpace/1GB).ToString("n2",$Culture)
                        $Myobj.PercentFree  = "{0:P2}" -f ($DiskInfo.FreeSpace / $DiskInfo.Capacity)
                        $obj = New-Object PSObject -Property $myobj
                        $obj.PSTypeNames.Clear()
                        $obj.PSTypeNames.Add('BSonPosh.DiskSpace')
                        $obj
                    }
                }
                else
                {
                    Write-Verbose " [Get-DiskSpace] :: Version not high enough to use Win32_Volume using Win32_LogicalDisk"
                    $DiskInfos = Get-WmiObject -class Win32_LogicalDisk                       `
                                            -ComputerName $ComputerName                       `
                                            -Property SystemName, DeviceID, FreeSpace, Size   `
                                            -filter "DriveType=3" -ea STOP
                    foreach($DiskInfo in $DiskInfos)
                    {
                        $myobj = @{}
                        $myobj.ComputerName = $ComputerName
                        $myobj.OSVersion    = $OSVersionInfo.Version
                        $Myobj.Drive       = "{0}\" -f $DiskInfo.DeviceID
                        $Myobj.CapacityGB   = [float]($DiskInfo.Capacity/1GB).ToString("n2",$Culture)
                        $Myobj.FreeSpaceGB  = [float]($DiskInfo.FreeSpace/1GB).ToString("n2",$Culture)
                        $Myobj.PercentFree  = "{0:P2}" -f ($DiskInfo.FreeSpace / $DiskInfo.Capacity)
                        $obj = New-Object PSObject -Property $myobj
                        $obj.PSTypeNames.Clear()
                        $obj.PSTypeNames.Add('BSonPosh.DiskSpace')
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
        Write-Verbose " [Get-DiskSpace] :: End Process"
    
    }
}
    
