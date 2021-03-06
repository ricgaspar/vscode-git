function Get-DiskPartition
{
        
    <#
        .Synopsis 
            Gets the disk partition info for specified host
            
        .Description
            Gets the disk partition info for specified host
            
        .Parameter ComputerName
            Name of the Computer to get the disk partition info from (Default is localhost.)
            
        .Example
            Get-DiskPartition
            Description
            -----------
            Gets Disk Partitions from local machine
    
        .Example
            Get-DiskPartition -ComputerName MyServer
            Description
            -----------
            Gets Disk Partitions from MyServer
            
        .Example
            $Servers | Get-DiskPartition
            Description
            -----------
            Gets Disk Partitions for each machine in the pipeline
            
        .OUTPUTS
            PSObject
            
        .Notes
        NAME:      Get-DiskPartition 
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
        Write-Verbose " [Get-DiskPartition] :: Process Start"
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host $ComputerName -TCPPort 135)
        {
            try
            {
                Write-Verbose " [Get-DiskPartition] :: Getting Partition info use WMI"
                $Partitions = Get-WmiObject Win32_DiskPartition -ComputerName $ComputerName
                Write-Verbose " [Get-DiskPartition] :: Found $($Partitions.Count) partitions" 
                foreach($Partition in $Partitions)
                {
                    Write-Verbose " [Get-DiskPartition] :: Creating Hash Table"
                    $myobj = @{}
                    
                    Write-Verbose " [Get-DiskPartition] :: Adding BlockSize        - $($Partition.BlockSize)"
                    $myobj.BlockSize = $Partition.BlockSize
                    
                    Write-Verbose " [Get-DiskPartition] :: Adding BootPartition    - $($Partition.BootPartition)"
                    $myobj.BootPartition = $Partition.BootPartition
                    
                    Write-Verbose " [Get-DiskPartition] :: Adding ComputerName     - $ComputerName"
                    $myobj.ComputerName = $ComputerName
                    
                    Write-Verbose " [Get-DiskPartition] :: Adding Description      - $($Partition.name)"
                    $myobj.Description = $Partition.Name
                    
                    Write-Verbose " [Get-DiskPartition] :: Adding PrimaryPartition - $($Partition.PrimaryPartition)"
                    $myobj.PrimaryPartition = $Partition.PrimaryPartition
                    
                    Write-Verbose " [Get-DiskPartition] :: Adding Index            - $($Partition.Index)"
                    $myobj.Index = $Partition.Index
                    
                    Write-Verbose " [Get-DiskPartition] :: Adding SizeMB           - $($Partition.Size)"
                    $myobj.SizeMB = ($Partition.Size/1mb).ToString("n2",$Culture)
                    
                    Write-Verbose " [Get-DiskPartition] :: Adding Type             - $($Partition.Type)"
                    $myobj.Type = $Partition.Type
                    
                    Write-Verbose " [Get-DiskPartition] :: Setting IsAligned "
                    $myobj.IsAligned = $Partition.StartingOffset%64kb -eq 0
                    
                    Write-Verbose " [Get-DiskPartition] :: Creating Object"
                    $obj = New-Object PSObject -Property $myobj
                    $obj.PSTypeNames.Clear()
                    $obj.PSTypeNames.Add('BSonPosh.DiskPartition')
                    $obj
                }
            }
            catch
            {
                Write-Verbose " [Get-SystemType] :: [$ComputerName] Failed with Error: $($Error[0])" 
            }
        }
        Write-Verbose " [Get-DiskPartition] :: Process End"
    }
}
    
