# ---------------------------------------------------------
Import-Module VNB_PSLib


Function Get-PackageList {
    [Cmdletbinding()]    
    Param (    	
        [Parameter()]
        [string]
        $SiteServer        
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

        $ModulePath = (($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) + '\ConfigurationManager.psd1'
        Import-Module $ModulePath -Force
        if ((Get-PSDrive $SiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) {
            New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
        }
        $SiteDrive = $SiteCode + ":"
        Set-Location $SiteDrive

        $Packages = Get-CMPackage | Select-Object Name,PackageID,Manufacturer,Version,PkgSourcePath,SourceDate,LastRefreshTime

        Set-Location C:        
        return $Packages
    }

}

Function Get-ApplicationList {
    [Cmdletbinding()]    
    Param (    	
        [Parameter()]
        [string]
        $SQLServer
    )

$Query = 'SELECT DISTINCT app.DisplayName, dt.DisplayName AS DeploymentTypeName,v_ContentInfo.ContentSource, v_ContentInfo.SourceSize
    FROM  dbo.fn_ListDeploymentTypeCIs(1033) AS dt INNER JOIN
    dbo.fn_ListLatestApplicationCIs(1033) AS app ON dt.AppModelName = app.ModelName LEFT OUTER JOIN
    v_ContentInfo ON dt.ContentId = v_ContentInfo.Content_UniqueID
    WHERE (dt.IsLatest = 1) and not(ContentSource is NUll)
    order by ContentSource'

}

Function Get-Folders-ByArray {
    [Cmdletbinding()]    
    Param (    	
        [Parameter()]
        [array]
        $FolderArray
    )

    if($FolderArray) {
        $Folders = @()
        foreach($FolderPath in $FolderArray) {            
            if([IO.Directory]::Exists($FolderPath)) {
                Write-Host $Folderpath
                $Folders += Get-FoldersByAge -FolderPath $FolderPath
            }
        }
    }

}

$SiteServer = 's007.nedcar.nl'

# $Packages = Get-PackageList -SiteServer $SiteServer
# foreach($Pkg in $Packages) {
    
# }

$SourceFolders = @('\\s007.nedcar.nl\sources$','\\s007.nedcar.nl\SMS_VNB','\\s008.nedcar.nl\OSD$')
Get-Folders-ByArray $SourceFolders