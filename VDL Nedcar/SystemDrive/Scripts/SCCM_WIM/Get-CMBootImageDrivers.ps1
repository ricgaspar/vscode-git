<#
.SYNOPSIS
    List all drivers that has been added to a specific Boot Image in ConfigMgr 2012 
.DESCRIPTION 
    This script will list all the drivers added to a Boot Image in ConfigMgr 2012. It's also possible to list 
    Microsoft standard drivers by specifying the All parameter. 
.PARAMETER SiteServer 
    Site server name with SMS Provider installed 
.PARAMETER BootImageName 
    Specify the Boot Image name as a string or an array of strings 
.PARAMETER MountPath 
    Default path to where the script will temporarly mount the Boot Image 
.PARAMETER All 
    When specified all drivers will be listed, including default Microsoft drivers 
.PARAMETER ShowProgress 
    Show a progressbar displaying the current operation 
.EXAMPLE 
    .\Get-CMBootImageDrivers.ps1 -SiteServer CM01 -BootImageName "Boot Image (x64)" -MounthPath C:\Temp\MountFolder 
    List all drivers in a Boot Image named 'Boot Image (x64)' on a Primary Site server called CM01:
.NOTES 
    Script name: Get-CMBootImageDrivers.ps1 
    Author:      Nickolaj Andersen 
    Contact:     @NickolajA 
    DateCreated: 2015-05-06 
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Specify the Boot Image name as a string or an array of strings")]
    [ValidateNotNullOrEmpty()]
    [string[]]$BootImageName,
    [parameter(Mandatory=$false, HelpMessage="Default path to where the script will temporarly mount the Boot Image")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+")]
    [string]$MountPath = "C:\MountFolder",
    [parameter(Mandatory=$false, HelpMessage="When specified all drivers will be listed, including default Microsoft drivers")]
    [switch]$All,
    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation")]
    [switch]$ShowProgress
)
Begin {
    # Determine SiteCode from WMI
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine SiteCode" ; break
    }
    # Determine if we need to load the Dism PowerShell module
    if (-not(Get-Module -Name Dism)) {
        try {
            Import-Module Dism -ErrorAction Stop -Verbose:$false
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to load the Dism PowerShell module" ; break
        }
    }
    # Determine if temporary mount folder is accessible, if not create it
    if (-not(Test-Path -Path $MountPath -PathType Container -ErrorAction SilentlyContinue -Verbose:$false)) {
        New-Item -Path $MountPath -ItemType Directory -Force -Verbose:$false | Out-Null
    }
}
Process {
    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }
    # Enumerate trough all specified boot image names
    foreach ($BootImageItem in $BootImageName) {
        try {
            Write-Verbose -Message "Querying for boot image: $($BootImageItem)"
            $BootImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_BootImagePackage -ComputerName $SiteServer -Filter "Name like '$($BootImageItem)'" -ErrorAction Stop
            if ($BootImage -ne $null) {
                $BootImagePath = $BootImage.PkgSourcePath
                Write-Verbose -Message "Located boot image wim file: $($BootImagePath)"
                # Mount Boot Image to temporary mount folder
                if ($PSCmdlet.ShouldProcess($BootImagePath, "Mount")) {
                    Mount-WindowsImage -ImagePath $BootImagePath -Path $MountPath -Index 1 -ErrorAction Stop -Verbose:$false | Out-Null
                }
                # Get all drivers in the mounted Boot Image
                $WindowsDriverArguments = @{
                    Path = $MountPath
                    ErrorAction = "Stop"
                    Verbose = $false
                }
                if ($PSBoundParameters["All"]) {
                    $WindowsDriverArguments.Add("All", $true)
                }
                if ($PSCmdlet.ShouldProcess($MountPath, "ListDrivers")) {
                    $Drivers = Get-WindowsDriver @WindowsDriverArguments
                    if ($Drivers -ne $null) {
                        $DriverCount = ($Drivers | Measure-Object).Count
                        foreach ($Driver in $Drivers) {
                            if ($PSBoundParameters["ShowProgress"]) {
                                $ProgressCount++
                                Write-Progress -Activity "Enumerating drivers in '$($BootImage.Name)'" -Id 1 -Status "Processing $($ProgressCount) / $($DriverCount)" -PercentComplete (($ProgressCount / $DriverCount) * 100)
                            }
                            $PSObject = [PSCustomObject]@{
                                Driver = $Driver.Driver
                                Version = $Driver.Version
                                Manufacturer = $Driver.ProviderName
                                ClassName = $Driver.ClassName
                                Date = $Driver.Date
                                BootImageName = $BootImage.Name
                            }
                            Write-Output $PSObject
                        }
                        if ($PSBoundParameters["ShowProgress"]) {
                            Write-Progress -Activity "Enumerating drivers in '$($BootImage.Name)'" -Id 1 -Completed
                        }
                    }
                    else {
                        Write-Warning -Message "No drivers was found"
                    }
                }
            }
            else {
                Write-Warning -Message "Unable to locate a boot image called '$($BootImageName)'"
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning -Message "Access denied" ; break
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
        # Dismount the boot image
        if ($PSCmdlet.ShouldProcess($BootImagePath, "Dismount")) {
            Dismount-WindowsImage -Path $MountPath -Discard -ErrorAction Stop -Verbose:$false | Out-Null
        }
    }
}
End {
    # Clean up mount folder
    try {
        Remove-Item -Path $MountPath -Force -ErrorAction Stop -Verbose:$false
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied"
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message
    }
}