function Get-DomainController
{
        
    <#
        .Synopsis 
            Returns a DomainController Object
        
        .Description
            Returns an object representation of a Domain Controller with various properties. By default it returns a single
        discovered Domain Controller.
        
        .Parameter Name
            Specifies the Name of the Domain Controller you want to get.
        
        .Parameter Filter
            A regular expression that allows you to filter the Domain Controllers to return. 
        
        .Parameter Site
            If Specified it will only return Domain Controllers from that Site
        
        .Parameter Domain
            Domain to return all Domain Controllers from.
        
        .Parameter Forest
            Forest to return all Domain Controllers from.
        
        .Parameter Target
            Source Domain Controller to use for Discovery. Valid with Filter, Domain, and Forest Parameters
        
        .Example
            Get-DomainController MyDC.domain.com
            Description
            -----------
            Get a Single Domain Controller
        
        .Example
            Get-DomainController -filter "MyDC(dc|gc)"
            Description
            -----------
            Get all Domain Controllers in the current domain that match a specific regular expression
            
        .Example
            Get-DomainController -site MySiteName
            Description
            -----------
            Get all the Domain Controllers for specified Site
            
        .Example
            Get-DomainController -domain child.domain.com
            Description
            -----------
            Get all the Domain Controllers for specified Domain
            
        .Example
            Get-DomainController -forest domain.com
            Description
            -----------
            Get all the Domain Controllers for specified Forest
        
        .Example
            Get-DomainController -domain child.domain.com -target ChildDC.child.domain.com
            Description
            -----------
            Get Domain Controllers using a specific Target
            
        .OUTPUTS
            System.DirectoryServices.ActiveDirectory.DomainController
        
        .INPUTS
            String
        
        .Link
            Get-GlobalCatalog
            Get-Domain
            Get-Forest
        
        .Notes
            NAME:      Get-DomainController
            AUTHOR:    Brandon Shell (aka BSonPosh)
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName="DCName")]
    
    Param(
        [alias("ComputerName")]
        [Parameter(ValueFromPipeline=$true,ParameterSetName="DCName",Position=0)]
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
        function Get-DCByName
        {
            [CmdletBinding()]
            Param($ServerName,$PSCreds)
            Write-Verbose " [Get-DCByName] :: Called"
            if($ServerName)
            {
                Write-Verbose " [Get-DCByName] :: Getting Domain Controller by ServerName"
                Write-Verbose " [Get-DCByName] :: Getting DirectoryContext for Server: $ServerName"
                $Context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$ServerName)
                Write-Verbose " [Get-DCByName] :: DirectoryContext: $Context"
                Write-Verbose " [Get-DCByName] :: Getting Domain Controller using GetDomainController(`$Context)"
                $MyDC = [System.DirectoryServices.ActiveDirectory.DomainController]::GetDomainController($Context)
            }
            else
            {
                Write-Verbose " [Get-DCByName] :: No Server Specified. Getting Current Domain"
                Write-Verbose " [Get-DCByName] :: Getting Domain - [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()"
                $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
                Write-Verbose " [Get-DCByName] :: Domain = $Domain"
                Write-Verbose " [Get-DCByName] :: Getting Random Domain Controller - `$Domain.FindDomainController()"
                $MyDC = $Domain.FindDomainController()
            }
            Write-Verbose " [Get-DCByName] :: Found DC: $MyDC"
            Write-Verbose " [Get-DCByName] :: Getting DSA GUID for DC"
            $MyDSAGUID = Get-DSAGUID $MyDC
            Write-Verbose " [Get-DCByName] :: Adding DSA [$MyDSAGUID] GUID to DC Object"
            $MyDC | Add-Member -name "DSAGUID" -MemberType NoteProperty -Value $MyDSAGUID -PassThru
        }
        function Get-DCByFilter
        {
            [CmdletBinding()]
            Param($Filter,$ServerName,$PSCreds)
            Write-Verbose " [Get-DCByFilter] :: Called"
            if($ServerName)
            {
                Write-Verbose " [Get-DCByFilter] :: Getting Domain by ServerName"
                Write-Verbose " [Get-DCByFilter] :: Getting DirectoryContext for Server: $ServerName"
                $Context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$ServerName)
                Write-Verbose " [Get-DCByFilter] :: DirectoryContext: $Context"
                Write-Verbose " [Get-DCByFilter] :: Getting Domain Controller using GetDomain(`$Context)"
                $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
                Write-Verbose " [Get-DCByFilter] :: Domain = $Domain"
            }
            else
            {
                Write-Verbose " [Get-DCByFilter] :: No Server Specified. Discovering DC"
                Write-Verbose " [Get-DCByFilter] :: Getting Domain - [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()"
                $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
                Write-Verbose " [Get-DCByFilter] :: Domain = $Domain"
            }
            Write-Verbose " [Get-DCByFilter] :: Getting Domain Controllers that match the filter - `$Domain.DomainControllers | ?{`$_.NAME -match `$Filter}"
            $DomainControllers = $Domain.DomainControllers | ?{$_.NAME -match $Filter}
            Write-Verbose " [Get-DCByFilter] :: Found [$($DomainControllers.count)] Domain Controllers"
            foreach($MyDC in $DomainControllers)
            {
                Write-Verbose " [Get-DCByFilter] :: Found DC: $MyDC"
                Write-Verbose " [Get-DCByFilter] :: Getting DSA GUID for DC"
                $MyDSAGUID = Get-DSAGUID $MyDC
                Write-Verbose " [Get-DCByFilter] :: Adding DSA [$MyDSAGUID] GUID to DC Object"
                $MyDC | Add-Member -name "DSAGUID" -MemberType NoteProperty -Value $MyDSAGUID -PassThru
            }
        }
        function Get-DCBySite
        {
            [CmdletBinding()]
            Param($SiteName,$ServerName,$PSCreds)
            Write-Verbose " [Get-DCBySite] :: Called"
            if($ServerName)
            {
                Write-Verbose " [Get-DCBySite] :: Getting Domain by ServerName"
                Write-Verbose " [Get-DCBySite] :: Getting DirectoryContext for Server: $ServerName"
                $Context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$ServerName)
                Write-Verbose " [Get-DCBySite] :: DirectoryContext: $Context"
                Write-Verbose " [Get-DCBySite] :: Getting Domain Controller using GetDomain(`$Context)"
                $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
                Write-Verbose " [Get-DCBySite] :: Domain = $Domain"
            }
            else
            {
                Write-Verbose " [Get-DCBySite] :: No Server Specified. Discovering DC"
                Write-Verbose " [Get-DCBySite] :: Getting Domain - [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()"
                $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
                Write-Verbose " [Get-DCBySite] :: Domain = $Domain"
            }
            
            Write-Verbose " [Get-DCBySite] :: Getting Domain Controllers in Site [$SiteName] - `$Domain.FindAllDomainControllers(`$SiteName)"
            $DomainControllers = $Domain.FindAllDomainControllers($SiteName)
            Write-Verbose " [Get-DCBySite] :: Found [$($DomainControllers.count)] Domain Controllers"
            foreach($MyDC in $DomainControllers)
            {
                Write-Verbose " [Get-DCBySite] :: Found DC: $MyDC"
                Write-Verbose " [Get-DCBySite] :: Getting DSA GUID for DC"
                $MyDSAGUID = Get-DSAGUID $MyDC
                Write-Verbose " [Get-DCBySite] :: Adding DSA [$MyDSAGUID] GUID to DC Object"
                $MyDC | Add-Member -name "DSAGUID" -MemberType NoteProperty -Value $MyDSAGUID -PassThru
            }
        }
        function Get-DCByDomain
        {
            [CmdletBinding()]
            Param($DomainName,$ServerName,$PSCreds)
            Write-Verbose " [Get-DCByDomain] :: Called"
            if($ServerName)
            {
                Write-Verbose " [Get-DCByDomain] :: Getting Domain by ServerName"
                Write-Verbose " [Get-DCByDomain] :: Getting DirectoryContext for Server: $ServerName"
                $Context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$ServerName)
                Write-Verbose " [Get-DCByDomain] :: DirectoryContext: $Context"
                Write-Verbose " [Get-DCByDomain] :: Getting Domain using GetDomain(`$Context)"
                $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
            }
            else
            {
                Write-Verbose " [Get-DCByDomain] :: Getting DirectoryContext for Domain: $DomainName"
                $Context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$DomainName)
                Write-Verbose " [Get-DCByDomain] :: DirectoryContext: $Context"
                Write-Verbose " [Get-DCByDomain] :: Getting Domain using GetDomain(`$Context)"
                $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
            }
            Write-Verbose " [Get-DCByDomain] :: Domain = $Domain"
            Write-Verbose " [Get-DCByDomain] :: Getting Domain Controllers in Domain [$DomainName] - `$Domain.FindAllDomainControllers()"
            $DomainControllers = $Domain.FindAllDomainControllers()
            Write-Verbose " [Get-DCByDomain] :: Found [$($DomainControllers.count)] Domain Controllers"
            foreach($MyDC in $DomainControllers)
            {
                Write-Verbose " [Get-DCByDomain] :: Found DC: $MyDC"
                Write-Verbose " [Get-DCByDomain] :: Getting DSA GUID for DC"
                $MyDSAGUID = Get-DSAGUID $MyDC
                Write-Verbose " [Get-DCByDomain] :: Adding DSA [$MyDSAGUID] GUID to DC Object"
                $MyDC | Add-Member -name "DSAGUID" -MemberType NoteProperty -Value $MyDSAGUID -PassThru
            }
        }
        function Get-DCByForest
        {
            [CmdletBinding()]
            Param($ForestName,$ServerName,$PSCreds)
            Write-Verbose " [Get-DCByForest] :: Called"
            if($ServerName)
            {
                Write-Verbose " [Get-DCByForest] :: Getting Forest by ServerName"
                Write-Verbose " [Get-DCByForest] :: Getting DirectoryContext for Server: $ServerName"
                $Context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$ServerName)
                Write-Verbose " [Get-DCByForest] :: DirectoryContext: $Context"
                Write-Verbose " [Get-DCByForest] :: Getting Forest using GetForest(`$Context)"
                $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($Context)
            }
            else
            {
                Write-Verbose " [Get-DCByForest] :: Getting DirectoryContext for Forest: $ForestName"
                $Context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("Forest",$ForestName)
                Write-Verbose " [Get-DCByForest] :: DirectoryContext: $Context"
                Write-Verbose " [Get-DCByForest] :: Getting Forest using GetForest(`$Context)"
                $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($Context)
            }
            Write-Verbose " [Get-DCByForest] :: Forest = $Forest"
            Write-Verbose " [Get-DCByForest] :: Getting Domain Controllers in Forest [$ForestName] - `$Forest.Domains | %{`$_.FindAllDomainControllers()}"
            $DomainControllers = $Forest.Domains | %{$_.FindAllDomainControllers()}
            Write-Verbose " [Get-DCByForest] :: Found [$($DomainControllers.count)] Domain Controllers"
            foreach($MyDC in $DomainControllers)
            {
                Write-Verbose " [Get-DCByForest] :: Found DC: $MyDC"
                Write-Verbose " [Get-DCByForest] :: Getting DSA GUID for DC"
                $MyDSAGUID = Get-DSAGUID $MyDC
                Write-Verbose " [Get-DCByForest] :: Adding DSA [$MyDSAGUID] GUID to DC Object"
                $MyDC | Add-Member -name "DSAGUID" -MemberType NoteProperty -Value $MyDSAGUID -PassThru
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
            "Filter"    {if($Target){Get-DCByFilter -Filter $Filter -ServerName $Target}else{Get-DCByFilter -Filter $Filter}}
            "Site"      {if($Target){Get-DCBySite   -Site $Site     -ServerName $Target}else{Get-DCBySite -Site $Site}}
            "Domain"    {if($Target){Get-DCByDomain -Domain $Domain -ServerName $Target}else{Get-DCByDomain -Domain $Domain}}
            "Forest"    {if($Target){Get-DCByForest -Forest $Forest -ServerName $Target}else{Get-DCByForest -Forest $Forest}}
        }
        
        Write-Verbose " [Begin] :: End BeginBlock"
        Write-Verbose ""
    
    }
    
    Process 
    {
        Write-Verbose ""
        Write-Verbose " [PROCESS] :: Start ProcessBlock"
        if($pscmdlet.ParameterSetName -eq "DCName")
        {
            if($name)
            {
                Get-DCbyName -ServerName $name
            }
            else
            {
                Get-DCbyName
            }
        }
        Write-Verbose " [PROCESS] :: End ProcessBlock"
        Write-Verbose ""
    }
}
    
