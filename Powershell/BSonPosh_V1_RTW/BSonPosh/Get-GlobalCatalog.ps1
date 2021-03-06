function Get-GlobalCatalog
{
        
    <#
        .Synopsis 
            Returns a Global Catalog Object
        
        .Description
            Returns an object representation of a Global Catalog with various properties. By default it returns a single di
        scovered Global Catalog.
        
        .Parameter Name
            Specifies the Name of the Global Catalog Server you want to get.
        
        .Parameter Filter
            A regular expression that allows you to filter the Global Catalog Servers to return. 
        
        .Parameter Site
            If Specified it will only return Global Catalog Servers from that Site
        
        .Parameter Domain
            Domain to return all Global Catalog Servers from.
        
        .Parameter Forest
            Forest to return all Global Catalog Servers from.
        
        .Parameter Target
            Source Global Catalog to use for Discovery. Valid with Filter, Domain, and Forest Parameters
        
        .Example
            Get-GlobalCatalog MyGC.domain.com
            Description
            -----------
            Get a Single Global Catalog Server
            
        .Example
            Get-GlobalCatalog -filter "MyGC(dc|gc)"
            Description
            -----------
            Get all Global Catalog Servers in the current domain that match a specific regular expression
            
        .Example
            Get-GlobalCatalog -site MySiteName
            Description
            -----------
            Get all the Global Catalog Servers for specified Site
        
        .Example
            Get-GlobalCatalog -domain child.domain.com
            Description
            -----------
            Get all the Global Catalog Servers in specified Domain
            
        .Example
            Get-GlobalCatalog -forest domain.com
            Description
            -----------
            Get all the Global Catalog Servers in specified Forest
        
        .Example
            Get-GlobalCatalog -domain child.domain.com -target ChildDC.child.domain.com
            Description
            -----------
            Get Global Catalogs using a specific Target
        
        .OUTPUTS
            System.DirectoryServices.ActiveDirectory.GlobalCatalog
        
        .INPUTS
            String
        
        .Link
            Get-DomainController
            Get-Domain
            Get-Forest
        
            NAME:      Get-GlobalCatalog
            AUTHOR:    Brandon Shell (aka BSonPosh)
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
        
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName="GCName")]
    
    Param(
        [alias("ComputerName")]
        [Parameter(ValueFromPipeline=$true,ParameterSetName="GCName",Position=0)]
        [string]$Name,
        [Parameter(ParameterSetName="Filter",Position=0)]
        [string]$Filter,
        [Parameter(ParameterSetName="Site",Position=0)]
        [string]$Site,
        [Parameter(ParameterSetName="Domain",Position=0)]
        [string]$Domain,
        [Parameter(ParameterSetName="Forest",Position=0)]
        [string]$Forest,
        [Parameter()]
        [string]$Target
    )
    
    Begin 
    {
        function Get-GCByName
        {
            [CmdletBinding()]
            Param($ServerName,$PSCreds)
            Write-Verbose " [Get-GCByName] :: Called"
            if($ServerName)
            {
                Write-Verbose " [Get-GCByName] :: Getting Global Catalog by ServerName"
                Write-Verbose " [Get-GCByName] :: Getting DirectoryContext for Server: $ServerName"
                $Context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$ServerName)
                Write-Verbose " [Get-GCByName] :: DirectoryContext: $Context"
                Write-Verbose " [Get-GCByName] :: Getting Global Catalog using GetGlobalCatalog(`$Context)"
                $MyGC = [System.DirectoryServices.ActiveDirectory.GlobalCatalog]::GetGlobalCatalog($Context)
            }
            else
            {
                Write-Verbose " [Get-GCByName] :: No Server Specified. Discovering DC"
                Write-Verbose " [Get-GCByName] :: Getting Domain - [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()"
                $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
                Write-Verbose " [Get-GCByName] :: Forest = $Forest"
                Write-Verbose " [Get-GCByName] :: Getting Random Global Catalog - `$Forest.FindDomainController()"
                $MyGC = $Forest.FindGlobalCatalog()
            }
            Write-Verbose " [Get-GCByName] :: Found DC: $MyGC"
            Write-Verbose " [Get-GCByName] :: Getting DSA GUID for DC"
            $MyDSAGUID = Get-DSAGUID $MyGC
            Write-Verbose " [Get-GCByName] :: Adding DSA [$MyDSAGUID] GUID to DC Object"
            $MyGC | Add-Member -name "DSAGUID" -MemberType NoteProperty -Value $MyDSAGUID -PassThru
        }
        function Get-GCByFilter
        {
            [CmdletBinding()]
            Param($Filter,$ServerName,$PSCreds)
            Write-Verbose " [Get-GCByFilter] :: Called"
            if($ServerName)
            {
                Write-Verbose " [Get-GCByFilter] :: Getting Forest by ServerName"
                Write-Verbose " [Get-GCByFilter] :: Getting DirectoryContext for Server: $ServerName"
                $Context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$ServerName)
                Write-Verbose " [Get-GCByFilter] :: DirectoryContext: $Context"
                Write-Verbose " [Get-GCByFilter] :: Getting Global Catalog using GetForest(`$Context)"
                $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($Context)
            }
            else
            {
                Write-Verbose " [Get-GCByFilter] :: No Server Specified. Getting Current Forest"
                Write-Verbose " [Get-GCByFilter] :: Getting Domain - [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()"
                $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            }
            Write-Verbose " [Get-GCByDomain] :: Forest = $Forest"
            Write-Verbose " [Get-GCByFilter] :: Getting Global Catalogs that match the filter - `$Forest.GlobalCatalogs| ?{`$_.NAME -match `$Filter}"
            $GlobalCatalogs = $Forest.GlobalCatalogs | ?{$_.NAME -match $Filter}
            Write-Verbose " [Get-GCByFilter] :: Found [$($GlobalCatalogs.count)] Global Catalogs"
            foreach($MyGC in $GlobalCatalogs)
            {
                Write-Verbose " [Get-GCByFilter] :: Found GC: $MyGC"
                Write-Verbose " [Get-GCByFilter] :: Getting DSA GUID for GC"
                $MyDSAGUID = Get-DSAGUID $MyGC
                Write-Verbose " [Get-GCByFilter] :: Adding DSA [$MyDSAGUID] GUID to DC Object"
                $MyGC | Add-Member -name "DSAGUID" -MemberType NoteProperty -Value $MyDSAGUID -PassThru
            }
        }
        function Get-GCBySite
        {
            [CmdletBinding()]
            Param($SiteName,$ServerName,$PSCreds)
            Write-Verbose " [Get-GCBySite] :: Called"
            if($ServerName)
            {
                Write-Verbose " [Get-GCBySite] :: Getting Forest by ServerName"
                Write-Verbose " [Get-GCBySite] :: Getting DirectoryContext for Server: $ServerName"
                $Context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$ServerName)
                Write-Verbose " [Get-GCBySite] :: DirectoryContext: $Context"
                Write-Verbose " [Get-GCBySite] :: Getting Global Catalog using GetForest(`$Context)"
                $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($Context)
            }
            else
            {
                Write-Verbose " [Get-GCBySite] :: No Server Specified. Getting Current Forest"
                Write-Verbose " [Get-GCBySite] :: Getting Domain - [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()"
                $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            }
            Write-Verbose " [Get-GCByDomain] :: Forest = $Forest"
            Write-Verbose " [Get-GCBySite] :: Getting Global Catalogs in Site [$SiteName] - `$Forest.FindAllGlobalCatalogs(`$SiteName)"
            $GlobalCatalogs = $Forest.FindAllGlobalCatalogs($SiteName)
            Write-Verbose " [Get-GCBySite] :: Found [$($GlobalCatalogs.count)] Global Catalogs"
            foreach($MyGC in $GlobalCatalogs)
            {
                Write-Verbose " [Get-GCBySite] :: Found GC: $MyGC"
                Write-Verbose " [Get-GCBySite] :: Getting DSA GUID for GC"
                $MyDSAGUID = Get-DSAGUID $MyGC
                Write-Verbose " [Get-GCBySite] :: Adding DSA [$MyDSAGUID] GUID to GC Object"
                $MyGC | Add-Member -name "DSAGUID" -MemberType NoteProperty -Value $MyDSAGUID -PassThru
            }
        }
        function Get-GCByDomain
        {
            [CmdletBinding()]
            Param($DomainName,$ServerName,$PSCreds)
            Write-Verbose " [Get-GCByDomain] :: Called"
            if($ServerName)
            {
                Write-Verbose " [Get-GCByDomain] :: Getting Forest by ServerName"
                Write-Verbose " [Get-GCByDomain] :: Getting DirectoryContext for Server: $ServerName"
                $Context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$ServerName)
                Write-Verbose " [Get-GCByDomain] :: DirectoryContext: $Context"
                Write-Verbose " [Get-GCByDomain] :: Getting Global Catalog using GetForest(`$Context)"
                $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($Context)
            }
            else
            {
                Write-Verbose " [Get-GCByDomain] :: No Server Specified. Getting Current Forest"
                Write-Verbose " [Get-GCByDomain] :: Getting Forest - [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()"
                $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            }
            
            Write-Verbose " [Get-GCByDomain] :: Getting Global Catalogs in Domain [$DomainName] - `$Forest.FindAllGlobalCatalogs() | where{`$_.Domain.ToString() -eq `$DomainName}"
            $GlobalCatalogs = $Forest.FindAllGlobalCatalogs() | where{$_.Domain.ToString() -eq $DomainName}
            Write-Verbose " [Get-GCByDomain] :: Found [$($DomainControllers.count)] Global Catalogs"
            foreach($MyGC in $GlobalCatalogs)
            {
                Write-Verbose " [Get-GCByDomain] :: Found GC: $MyGC"
                Write-Verbose " [Get-GCByDomain] :: Getting DSA GUID for GC"
                $MyDSAGUID = Get-DSAGUID $MyGC
                Write-Verbose " [Get-GCByDomain] :: Adding DSA [$MyDSAGUID] GUID to GC Object"
                $MyGC | Add-Member -name "DSAGUID" -MemberType NoteProperty -Value $MyDSAGUID -PassThru
            }
        }
        function Get-GCByForest
        {
            [CmdletBinding()]
            Param($ForestName,$ServerName,$PSCreds)
            Write-Verbose " [Get-GCByForest] :: Called"
            if($ServerName)
            {
                Write-Verbose " [Get-GCByForest] :: Getting Forest by ServerName"
                Write-Verbose " [Get-GCByForest] :: Getting DirectoryContext for Server: $ServerName"
                $Context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$ServerName)
                Write-Verbose " [Get-GCByForest] :: DirectoryContext: $Context"
                Write-Verbose " [Get-GCByForest] :: Getting Global Catalog using GetForest(`$Context)"
                $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($Context)
            }
            else
            {
                Write-Verbose " [Get-GCByForest] :: No Server Specified. Getting Current Forest"
                Write-Verbose " [Get-GCByForest] :: Getting Domain - [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()"
                $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            }
            Write-Verbose " [Get-GCByForest] :: Getting Global Catalogs in Domain [$DomainName] - `$Forest.FindAllGlobalCatalogs()"
            $GlobalCatalogs = $Forest.FindAllGlobalCatalogs() 
            Write-Verbose " [Get-GCByForest] :: Found [$($DomainControllers.count)] Global Catalogs"
            foreach($MyGC in $GlobalCatalogs)
            {
                Write-Verbose " [Get-GCByForest] :: Found DC: $MyGC"
                Write-Verbose " [Get-GCByForest] :: Getting DSA GUID for DC"
                $MyDSAGUID = Get-DSAGUID $MyGC
                Write-Verbose " [Get-GCByForest] :: Adding DSA [$MyDSAGUID] GUID to DC Object"
                $MyGC | Add-Member -name "DSAGUID" -MemberType NoteProperty -Value $MyDSAGUID -PassThru
            }
        }
        function Get-DSAGUID
        {
            [cmdletbinding()]
            Param($DCObject)
            Write-Verbose " [Get-DSAGUID] :: Getting DSA Object for $DCObject"
            $DSA = $DCObject.GetDirectoryEntry().Children | where-object {$_.distinguishedName -match "CN=NTDS Settings,.*"}
            Write-Verbose " [Get-DSAGUID] :: DSA Object found: $($DSA.distinguishedName)"
            Write-Verbose " [Get-DSAGUID] :: Converting ObjectGUID to Friendly GUID"
            $GUID = new-object System.Guid($DSA.ObjectGUID)
            Write-Verbose " [Get-DSAGUID] :: ObjectGUID: $($GUID.GUID)"
            $GUID.ToString()
        }
    
        Write-Verbose ""
        Write-Verbose " [Begin] :: Start BeginBlock"
        Write-Verbose " [Begin] :: Parameters Passed"
        Write-Verbose " [Begin] ::    `$Name       : $Name"
        Write-Verbose " [Begin] ::    `$Filter     : $Filter"
        Write-Verbose " [Begin] ::    `$Site       : $Site"
        Write-Verbose " [Begin] ::    `$Domain     : $Domain"
        Write-Verbose " [Begin] ::    `$Forest     : $Forest"
        Write-Verbose " [Begin] ::    `$Target     : $Target"
        
        switch ($pscmdlet.ParameterSetName)
        {
            "Filter"    {if($Target){Get-GCByFilter -Filter $Filter -ServerName $Target}else{Get-GCByFilter -Filter $Filter}}
            "Site"      {if($Target){Get-GCBySite   -Site $Site     -ServerName $Target}else{Get-GCBySite -Site $Site}}
            "Domain"    {if($Target){Get-GCByDomain -Domain $Domain -ServerName $Target}else{Get-GCByDomain -Domain $Domain}}
            "Forest"    {if($Target){Get-GCByForest -Forest $Forest -ServerName $Target}else{Get-GCByForest -Forest $Forest}}
        }
        
        Write-Verbose " [Begin] :: End BeginBlock"
        Write-Verbose ""
    
    }
    
    Process 
    {
        Write-Verbose " [PROCESS] :: Start ProcessBlock"
        if($pscmdlet.ParameterSetName -eq "GCName")
        {
            if($name)
            {
                Get-GCByName -ServerName $name
            }
            else
            {
                Get-GCByName
            }
        }
        Write-Verbose " [PROCESS] :: End ProcessBlock"
        Write-Verbose "" 
    }
}
    
Get-GlobalCatalog