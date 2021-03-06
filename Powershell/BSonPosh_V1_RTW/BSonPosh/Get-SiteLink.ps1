function Get-SiteLink
{
        
    <#
        .Synopsis 
            Gets site link objects
            
        .Description
            Gets site link objects from the forest.
            
        .Parameter Filter
            Returns all the sitelinks that match the filter (RegEx)
        
        .Parameter Name
            [Switch] :: Only returns the Name
            
        .Parameter Raw
            [Switch] :: Returns only Name,Cost,Options,SiteList
            
        .Parameter Full
            [Switch] :: Returns a System.DirectoryService.DirectoryEntry Object with all properties.
            
        .Example
            Get-SiteLink
            Description
            -----------
            Returns all the site links in the forest
            
        .Example
            Get-SiteLink -filter "NYC"
            Description
            -----------
            Returns all the site links in the forest with a name that matches 'NYC'
    
        .Example
            Get-SiteLink -filter "NYC" -raw -full
            Description
            -----------
            Returns a DirectoryEntry for all the site links in the forest with a name that matches 'NYC'
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Notes
            NAME:      Get-SiteLink
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        
        [Parameter()]
        $Filter=".*",
        
        [Parameter()]
        [Switch]$Name,
        
        [Parameter()]
        [Switch]$RAW,
    
        [Parameter()]
        [Switch]$Full
    )
    
    $Forest = Get-Forest
    $Sites = $forest.Sites
    $SiteLinks = $Sites | %{$_.SiteLinks} | select -Unique | ?{$_.name -match $filter}
    
    if($Raw)
    {
        if($FULL)
        {
            $SiteLInks | %{$_.GetDirectoryEntry()} 
        }
        else
        {
            $SiteLInks | %{$_.GetDirectoryEntry()} | Select Name,Cost,Options,SiteList
        }
    }
    else
    {
        if($Name)
        {
            $SiteLInks | %{$_.Name}
        }
        else
        {
            $SiteLInks | Select Name,Cost,DataCompressionEnabled,NotificationEnabled,Sites
        }
    }
}
    
