Function Get-SMSSiteCode {
    [Cmdletbinding()]    
    Param (    	
        [Parameter()]
        [string]
        $SiteServer     
    )
    try { 
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'" 
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop 
        foreach ($SiteCodeObject in $SiteCodeObjects) { 
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) { 
                $SiteCode = $SiteCodeObject.SiteCode 
                Write-Debug "SiteCode: $($SiteCode)" 
            }
            return $SiteCode
        } 
    } 
    catch [Exception] { 
        Throw "Unable to determine SiteCode" 
    }
}

Function Get-AutoDeploymentRules {
# ---------------------------------------------------------
# Return the names of all Auto Deployment Rules
# ---------------------------------------------------------
    [Cmdletbinding()]    
    Param (    	
        [Parameter()]
        [string]
        $SiteServer,
        
        [Parameter()]
        [string]
		$SiteCode    
    )
    process {
        try {
            $result = Get-WmiObject -Class SMS_AutoDeployment -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer
        }
        catch {
            Write-Host "Error: Cannot retrieve ADR set from WMI."
        }
        return $result
    }
}

Function Set-AutoDeploymentRules-PackageID {
    [Cmdletbinding()]    
    Param (    	
        [Parameter()]
        [string]
        $SiteServer,       

        [Parameter()]
        [string]
		$PackageID
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
        catch [Exception] { 
            Throw "Unable to determine SiteCode" 
        } 
    }

    process {        
        $Rules = Get-AutoDeploymentRules -SiteServer $SiteServer -SiteCode $SiteCode
        if($Rules) {
            foreach ($ADR in $Rules) {
                $AutoDeploymentName = $ADR.Name                    

                # Retrieve the Auto Deployment Rule
                [wmi]$AutoDeployment = (Get-WmiObject -Class SMS_AutoDeployment -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer | Where-Object -FilterScript {$_.Name -eq $AutoDeploymentName}).__PATH

                # Retrieve the Content template that contains the package ID of the Deployment Package.
                [xml]$ContentTemplateXML = $AutoDeployment.ContentTemplate

                $OldPackageID = $ContentTemplateXML.ContentActionXML.PackageId
                if($OldPackageID -ne $PackageID) { 
                    # Set the new package ID in the content template                    
                    $ContentTemplateXML.ContentActionXML.PackageId = $PackageId

                    # Write back the template to the deployment rule
                    $AutoDeployment.ContentTemplate = $ContentTemplateXML.OuterXML

                    # Save and apply.
                    [void]($AutoDeployment.Put())
                }
            }
        }      
    }
}

Function Create-DeploymentPackage {
<# 
.SYNOPSIS 
    Create a Deployment Package in Configuration Manager 2012. 
.DESCRIPTION 
    Use this script if you need to create a Deployment Package in Configuration Manager 2012.  
.PARAMETER SiteServer 
    Primary Site server name with SMS Provider installed 
.PARAMETER Name 
    Name of the Deployment Package 
.PARAMETER Description 
    Description of the Deployment Package 
.PARAMETER SourcePath 
    UNC path to the source location where downloaded patches will be stored 
.EXAMPLE 
    .\New-CMDeploymentPackage.ps1 -SiteServer CM01 -Name "Critical and Security Patches" -SourcePath "\\CAS01\Source$\SUM\ADRs\CS" -Description "Contains Critical and Security patches" 
    Create a Deployment Package called 'Critical and Security Patches', specifying a source path and description on a Primary Site server called 'CM01': 
.NOTES 
    Script name: New-CMDeploymentPackage.ps1 
    Author:      Nickolaj Andersen 
    Contact:     @NickolajA 
    DateCreated: 2014-11-05 
#> 
    [CmdletBinding(SupportsShouldProcess=$true)] 
    param( 
        [parameter(Mandatory=$true,HelpMessage="Site server where the SMS Provider is installed")] 
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})] 
        [string]$SiteServer, 
        [parameter(Mandatory=$true,HelpMessage="Name of the Deployment Package")] 
        [string]$Name, 
        [parameter(Mandatory=$false,HelpMessage="Description of the Deployment Package")] 
        [string]$Description, 
        [parameter(Mandatory=$true,HelpMessage="UNC path to the source location where downloaded patches will be stored")] 
        [string]$SourcePath 
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
        catch [Exception] { 
            Throw "Unable to determine SiteCode" 
        } 
    } 
    Process { 
        function Get-DuplicateInfo { 
            $IsDuplicatePkg = $false 
            $EnumDeploymentPackages = Get-CimInstance -CimSession $CimSession -Namespace "root\SMS\site_$($SiteCode)" -ClassName SMS_SoftwareUpdatesPackage -ErrorAction SilentlyContinue -Verbose:$false 
            foreach ($Pkgs in $EnumDeploymentPackages) { 
                if ($Pkgs.PkgSourcePath -like "$($SourcePath)") { 
                    $IsDuplicatePkg = $true 
                } 
            } 
            return $IsDuplicatePkg 
        } 
        function Remove-CimSessions { 
            foreach ($Session in $(Get-CimSession -ComputerName $SiteServer -ErrorAction SilentlyContinue -Verbose:$false)) { 
                if ($Session.TestConnection()) { 
                    Write-Verbose -Message "Closing CimSession against '$($Session.ComputerName)'" 
                    Remove-CimSession -CimSession $Session -ErrorAction SilentlyContinue -Verbose:$false 
                } 
            } 
        } 
    
        try { 
            Write-Verbose -Message "Establishing a Cim session against '$($SiteServer)'" 
            $CimSession = New-CimSession -ComputerName $SiteServer -Verbose:$false 
            # Check if there's an existing Deployment Package with the same name 
            if ((Get-CimInstance -CimSession $CimSession -Namespace "root\SMS\site_$($SiteCode)" -ClassName SMS_SoftwareUpdatesPackage -Filter "Name like '$($Name)'" -ErrorAction SilentlyContinue -Verbose:$false | Measure-Object).Count -eq 0) { 
                # Check if there's an existing Deployment Package with the same source path 
                if ((Get-DuplicateInfo) -eq $false) { 
                    $CimProperties = @{ 
                        "Name" = "$($Name)" 
                        "PkgSourceFlag" = 2 
                        "PkgSourcePath" = "$($SourcePath)" 
                    } 
                    if ($PSBoundParameters["Description"]) { 
                        $CimProperties.Add("Description",$Description) 
                    } 
                    $CMDeploymentPackage = New-CimInstance -CimSession $CimSession -Namespace "root\SMS\site_$($SiteCode)" -ClassName SMS_SoftwareUpdatesPackage -Property $CimProperties -Verbose:$false -ErrorAction Stop 
                    $PSObject = [PSCustomObject]@{ 
                        "Name" = $CMDeploymentPackage.Name 
                        "Description" = $CMDeploymentPackage.Description 
                        "PackageID" = $CMDeploymentPackage.PackageID 
                        "PkgSourcePath" = $CMDeploymentPackage.PkgSourcePath 
                    } 
                    Write-Output $PSObject 
                } 
                else { 
                    Write-Warning -Message "A Deployment Package with the specified source path already exists" 
                } 
            } 
            else { 
                Write-Warning -Message "A Deployment Package with the name '$($Name)' already exists" 
            } 
        } 
        catch [Exception] { 
            Remove-CimSessions 
            Throw $_.Exception.Message 
        } 
    } 
    End { 
        # Remove active Cim session established to $SiteServer 
        Remove-CimSessions 
    }
}

Function Get-UpdateDeploymentPackage {
    [CmdletBinding(SupportsShouldProcess=$true)] 
    param( 
        [parameter(Mandatory=$true,HelpMessage="Site server where the SMS Provider is installed")] 
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})] 
        [string]$SiteServer, 
        [parameter(Mandatory=$true,HelpMessage="Name of the Updates Deployment Package")] 
        [string]$Name        
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
        catch [Exception] { 
            Throw "Unable to determine SiteCode" 
        } 
    } 
    Process { 
        $CimSession = New-CimSession -ComputerName $SiteServer -Verbose:$false 
        # Check if there's an existing Deployment Package with the same name 
        $Package = Get-CimInstance -CimSession $CimSession -Namespace "root\SMS\site_$($SiteCode)" -ClassName SMS_SoftwareUpdatesPackage -Filter "Name like '$($Name)'" -ErrorAction SilentlyContinue -Verbose:$false
        Return $Package.PackageID
    }
}

$SiteServer = 's007.nedcar.nl'

# Determine current date and save month and year values
$Date = Get-Date
$Month = Get-Date -Format 'MM'
$Year = Get-Date -Format 'yyyy'

# Set Package values
$PackageId = $null
$DeploymentPackageName = "Updates $Month-$Year"
$Description = "Created by powershell script on $Date"
$SourcePath = "\\S008\updates$\Updates_"+$Month+'_'+$Year

# Create sourcepath if it does not exist
New-Item -ItemType directory -Path $SourcePath -ErrorAction SilentlyContinue

# Check if path exists
if(Test-PathExists $SourcePath) { 
    $Package = Create-DeploymentPackage -SiteServer $SiteServer -Name $DeploymentPackageName -Description $Description  -SourcePath $SourcePath
    if($Package) {
        $PackageId = $Package.PackageID
    } else {        
        $PackageId = Get-UpdateDeploymentPackage -SiteServer $SiteServer -Name $DeploymentPackageName      
    }
	Write-Host "PackageID applied to all ADR: $PackageId"
	# Set-AutoDeploymentRules-PackageID -SiteServer $SiteServer -PackageID $PackageId
} else {
	Write-Warning -Message "Cannot create package source location: $SourcePath"
}

# Distribute package content to Distribution group
$ModulePath = (($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) + '\ConfigurationManager.psd1'
Import-Module $ModulePath -Force
if ((Get-PSDrive $SiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) {
    New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
}
$SiteDrive = $SiteCode + ":"
Set-Location $SiteDrive

$DistributionGroupName = 'VDL Nedcar client distribution group'
Start-CMContentDistribution -DeploymentPackageName $DeploymentPackageName -DistributionPointGroupName $DistributionGroupName  | Out-Null

Set-Location C: