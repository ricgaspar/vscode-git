function Get-HyperVSetting
{
    <#
        .Synopsis 
            Gets the HyperV settings from the ComputerName passed.
            
        .Description
            Gets the HyperV settings from the ComputerName passed.
            
        .Parameter ComputerName
            Name of the Computer to get the settings from.
            
        .Example
            Get-HyperVSetting -computername MyHyperVisor
            Description
            -----------
            Gets the HyperV settings from 'MyHyperVisor'
            
        .Example
            $MyHyperVisors | Get-HyperVSetting 
            Description
            -----------
            Gets the HyperV settings from each HyperVisor in the pipeline
    
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
        .System/String
        
        .Notes
            NAME:      Get-HyperVSetting
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
            $WMISettings = Get-WMIObject -Namespace root\virtualization -Class Msvm_VirtualSystemManagementServiceSettingData -Comp $ComputerName
            $myobj = @{
                ComputerName         = $ComputerName
                VirtualMachinePath   = $WMISettings.DefaultExternalDataRoot
                VirtualHardDiskPath  = $WMISettings.DefaultVirtualHardDiskPath
                MaximumMacAddress    = $WMISettings.MaximumMacAddress
                MinimumMacAddress    = $WMISettings.MinimumMacAddress
            }
            $obj = New-Object PSObject -Property $myobj
            $obj.PSTypeNames.Clear()
            $obj.PSTypeNames.Add('BSonPosh.HyperVSetting')
            $obj
    
    }
}
    
