function Test-LdapFilter
{
        
    <#
        .Synopsis 
            Returns LDAP stats for an LDAP Query
        
        .Description
            Returns LDAP stats for an LDAP Query
            
        .Parameter LdapFilter
            Ldapfilter to test. Defaults to (objectclass=*).
            
        .Parameter Base
            OU or Container to start the search. Default is Domain.
        
        .Parameter Server
            Domain Controller to target the query against
            
        .Parameter PageSize
            Pagesize for the query. Default 1000
            
        .Parameter Properties
            Properties to return. Default is just DN.
        
        .Parameter Scope
            Scope of the query. Default is subtree.
            Valid Values
            - Base : Only Base level Query
            - OneLevel : Base level plus 1 level below
            - Subtree : All levels starting at base
            
        .Example
            Test-LDAPFilter "(ObjectClass=user)"
            Description
            -----------
            Get stats for specific filter returning only DN
            
        .Example
            Test-LDAPFilter "(ObjectClass=user)" -properties "sAMAccountName","lastLogon"
            Description
            -----------
            Get stats for specific filter returning sAMAccountName,lastLogon
            
        .Example
            Test-LDAPFilter "(ObjectClass=user)" -server myDC1
            Description
            -----------
            Get stats for specific filter using specific Server
            
        .Example
            Test-LDAPFilter "(ObjectClass=user)" -base "OU=MyUsers,DC=MY,DC=Domain"
            Description
            -----------
            Get stats for specific filter using specific base
            
            
        .OUTPUTS
            PSCustomObject
    
        .Notes
            NAME:      Test-LDAPFilter
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
    
        [alias("filter")]
        [parameter()]    
        [string]$LdapFilter = "(objectclass=*)",
        
        [parameter()]
        [string]$base,
        
        [parameter()]
        [string]$Server,
        
        [parameter()]
        [int]$pageSize = 1000,
        
        [parameter()]
        [string[]]$Properties = @("1.1"),
        
        [parameter()]
        [string]$Scope
        
    )
    function CreateStatsObject2008
    {
        Param($StatsArray)
        $DecodedArray = [System.DirectoryServices.Protocols.BerConverter]::Decode("{iiiiiiiiiaiaiiiiiiiiiiiiii}",$StatsArray) # Win2008
        $myStatsObject = New-Object System.Object
        $myStatsObject | Add-Member -Name "ThreadCount"     -Value $DecodedArray[1]  -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "CallTime"        -Value $DecodedArray[3]  -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "EntriesReturned" -Value $DecodedArray[5]  -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "EntriesVisited"  -Value $DecodedArray[7]  -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "Filter"          -Value $DecodedArray[9]  -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "Index"           -Value $DecodedArray[11] -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "PagesReferenced" -Value $DecodedArray[13] -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "PagesRead"       -Value $DecodedArray[15] -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "PagesPreread"    -Value $DecodedArray[17] -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "PagesDirtied"    -Value $DecodedArray[19] -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "PagesRedirtied"  -Value $DecodedArray[21] -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "LogRecordCount"  -Value $DecodedArray[23] -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "LogRecordBytes"  -Value $DecodedArray[25] -MemberType "NoteProperty"
        $myStatsObject
    }
    function CreateStatsObject2003
    {
        Param($StatsArray)
        $DecodedArray = [System.DirectoryServices.Protocols.BerConverter]::Decode("{iiiiiiiiiaia}",$StatsArray) # Win2003
        $myStatsObject = New-Object System.Object
        $myStatsObject | Add-Member -Name "ThreadCount"     -Value $DecodedArray[1]  -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "CallTime"        -Value $DecodedArray[3]  -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "EntriesReturned" -Value $DecodedArray[5]  -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "EntriesVisited"  -Value $DecodedArray[7]  -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "Filter"          -Value $DecodedArray[9]  -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "Index"           -Value $DecodedArray[11] -MemberType "NoteProperty"
        $myStatsObject
    }
    function CreateStatsObject2000
    {
        Param($StatsArray)
        $DecodedArray = [System.DirectoryServices.Protocols.BerConverter]::Decode("{iiiiiiii}",$StatsArray) # Win2000
        $myStatsObject = New-Object System.Object
        $myStatsObject | Add-Member -Name "ThreadCount"          -Value $DecodedArray[1]  -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "CoreTime"             -Value $DecodedArray[3]  -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "CallTime"             -Value $DecodedArray[5]  -MemberType "NoteProperty"
        $myStatsObject | Add-Member -Name "searchSubOperations"  -Value $DecodedArray[7]  -MemberType "NoteProperty"
        $myStatsObject
    }
    
    Write-Verbose " - Loading System.DirectoryServices.Protocols"
    [VOID][System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.Protocols") 
        
    [int]$pageCount = 0
    [int]$objcount = 0
    
    $rootDSE = [ADSI]"LDAP://rootDSE"
    if(!$base)
    {
        $base = $rootDSE.defaultNamingContext
    }
    
    if(!$Server)
    {      
        $Server = $rootDSE.dnsHostName
    }
    
    switch ($rootDSE.domainControllerFunctionality)
    {
        0 {$expression = 'CreateStatsObject2000 $stats'}
        2 {$expression = 'CreateStatsObject2003 $stats'}
        3 {$expression = 'CreateStatsObject2008 $stats'}
    }
    
    Write-Verbose " - Creating LDAP connection Object"
    $connection = New-Object System.DirectoryServices.Protocols.LdapConnection($Server)
    
    switch -exact ($Scope)
    {
        "base"       {$MyScope = [System.DirectoryServices.Protocols.SearchScope]"Base"}
        "onelevel"   {$MyScope = [System.DirectoryServices.Protocols.SearchScope]"OneLevel"}
        default      {$MyScope = [System.DirectoryServices.Protocols.SearchScope]"Subtree"}
    }
    
    
    Write-Verbose " - Using Server:  [$Server]"
    Write-Verbose " - Using Base:    [$base]"
    Write-Verbose " - Scope:         [$MyScope]"
    Write-Verbose " - Using Filter:  [$filter]"
    Write-Verbose " - Page Size:     [$PageSize]"
    Write-Verbose " - Returning:     [$props]"
    Write-Verbose " - Expression:    [$expression]"
    
    Write-Verbose " + Creating SearchRequest Object"
    $SearchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest($base,$Ldapfilter,$MyScope,$Properties
    )
    
    Write-Verbose "   - Creating System.DirectoryServices.Protocols.PageResultRequestControl Object"
    $PagedRequest  = New-Object System.DirectoryServices.Protocols.PageResultRequestControl($pageSize)
    
    Write-Verbose "   - Creating System.DirectoryServices.Protocols.SearchOptionsControl Object"
    $SearchOptions = New-Object System.DirectoryServices.Protocols.SearchOptionsControl([System.DirectoryServices.Protocols.SearchOption]::DomainScope)
    
    Write-Verbose "   - Creating System.DirectoryServices.Protocols.DirectoryControl Control for OID: [1.2.840.113556.1.4.970]"
    $oid = "1.2.840.113556.1.4.970"
    $StatsControl = New-Object System.DirectoryServices.Protocols.DirectoryControl($oid,$null,$false,$true)
    
    Write-Verbose "   - Adding Controls"
    [void]$SearchRequest.Controls.add($pagedRequest)
    [void]$SearchRequest.Controls.Add($searchOptions)
    [void]$SearchRequest.Controls.Add($StatsControl)
    
    $start = Get-Date
    
    while ($True)
    {
        # Increment the pageCount by 1
        $pageCount++
    
        # Cast the directory response into a SearchResponse object
        Write-Verbose " - Cast the directory response into a SearchResponse object"
        $searchResponse = $connection.SendRequest($searchRequest)
    
        # Display the retrieved page number and the number of directory entries in the retrieved page
        Write-Verbose (" - Page:{0} Contains {1} response entries" -f $pageCount,$searchResponse.entries.count)
    
        Write-Verbose " - Returning Stats for Page:$PageCount"
        $stats = $searchResponse.Controls[0].GetValue()
        $ResultStats = invoke-Expression $expression
        if($pageCount -eq 1)
        {
            $StatsFilter = $ResultStats.Filter
            $StatsIndex = $ResultStats.Index
            Write-Verbose "   + Setting Filter to [$StatsFilter]"
            Write-Verbose "   + Setting Index  to [$StatsIndex]"
        }
        
        # If Cookie Length is 0, there are no more pages to request"
        if ($searchResponse.Controls[1].Cookie.Length -eq 0)
        {
            "`nStatistics"
            "================================="
            "Elapsed Time: {0} (ms)" -f ((Get-Date).Subtract($start).TotalMilliseconds)
            "Returned {0} entries of {1} visited - ({2})`n" -f $ResultStats.EntriesReturned,$ResultStats.EntriesVisited,($ResultStats.EntriesReturned/$ResultStats.EntriesVisited).ToString('p')
            "Used Filter:"
            "- {0}`n" -f $StatsFilter
            "Used Indices:"
            "- {0}`n" -f $StatsIndex
            break
        }
    
        # Set the cookie of the pageRequest equal to the cookie of the pageResponse to request the next 
        # page of data in the send request and cast the directory control into a PageResultResponseControl object
        Write-Verbose " - Setting Cookie on SearchResponse to the PageReQuest"
        $pagedRequest.Cookie = $searchResponse.Controls[1].Cookie
    }
}
    
