function Test-ADReplication 
{
        
    <#
        .Synopsis 
            Test Active Directory Replication Convergance
            
        .Description
            Test Active Directory Replication Convergance
            
        .Parameter Target
            dnsname of host to orginate change 
            
        .Parameter ADObject
            OU/Container/Object to set wWWHomePage attribute
        
        .Parameter Site
            Site to Limit check on
        
        .Parameter Revert
            If Passed the wWWHomePage will be reverted back
        
        .Parameter Table
            Switch to return a table or not
            
        .Example
            Test-ADReplication
            Description
            -----------
            Starts AD replication Test
            
        .Outputs
            System.String
            
        .Link
            Get-Help
            
        .Notes
            NAME:      Test-ADReplication
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [Parameter()]
        [String]$Target = (([ADSI]"LDAP://rootDSE").dnshostname),
    
        [Parameter()]
        [String]$ADObject = ("cn=users," + ([ADSI]"").distinguishedname),
        
        [Parameter()]
        [String]$Site,
        
        [Parameter()]
        [Switch]$Revert,
    
        [Parameter()]
        [switch]$Table
    )
    function Ping-Server 
    {
    Param([string]$server)
    $pingresult = Get-WmiObject win32_pingstatus -f "address='$Server' and Timeout=1000"
    if($pingresult.statuscode -eq 0) {$true} else {$false}
    }
    
    Write-Verbose "[MAIN] :: Getting Current Domain"
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    
    if($site)
    {
        Write-Verbose "[MAIN] :: Getting Domain Controllers for Site [$Site]"
        $dclist = $domain.FindAllDomainControllers($Site)
    }
    else
    {
        Write-Verbose "[MAIN] :: Getting All Domain Controllers"
        $dclist = $domain.FindAllDomainControllers()
    }
    
    if($Table)
    {
        Write-Verbose "[MAIN] :: `$Table passed. Building Custom Object Array"
        $DCTable = @()
        $myobj = "" | select Name,Time
        $myobj.Name = ("$Target [SOURCE]").ToUpper()
        $myobj.Time = 0.00
        $DCTable += $myobj
    }
    
    $Timestamp = [datetime]::Now.ToFileTime().ToString()
    Write-Host "`n  Modifying wwwHomePage Attribute"
    Write-Host "  Object: [$ADObject]"
    Write-Host "  Target: [$Target]"
    Write-Host "  Value:  [$Timestamp]"
    
    Write-Verbose "[MAIN] :: `$MyObject = ([ADSI]`"LDAP://$Target/$ADObject`")"
    $MyObject = ([ADSI]"LDAP://$Target/$ADObject")
    
    Write-Verbose "[MAIN] :: Checking for existing wWWHomePage"
    if($MyObject.wWWHomePage)
    {
        $wwwHomePage = $MyObject.wWWHomePage
        Write-Verbose "[MAIN] :: wWWHomePage found with Value [$wwwHomePage]"
    }
    
    Write-Verbose "[MAIN] :: Setting wWWHomePage to $TimeStamp"
    $MyObject.wWWHomePage = $TimeStamp
    $MyObject.SetInfo()
    
    $dn = $MyObject.distinguishedname
    Write-Host "  Object  [$dn] Modified! `n"
    
    $start = Get-Date
    
    $i = 0
    
    Write-Host "  Found [$($dclist.count)] Domain Controllers"
    $cont = $true
    
    While($cont)
    {
        $i++
        $oldpos = $host.UI.RawUI.CursorPosition
        Write-Host "  =========== Check $i ===========" -fore white
        start-Sleep 1
        $replicated = $true
        foreach($dc in $dclist)
        {
            if($target -match $dc.Name){continue}
            if(ping-server $dc.Name)
            {
                $object = [ADSI]"LDAP://$($dc.Name)/$dn"
                if($object.wwwHomePage -eq $timeStamp)
                {
                    Write-Host "  - $($dc.Name.ToUpper()) Has Object description [$dn]" (" "*5) -fore Green
                    if($table -and !($dctable | ?{$_.Name -match $dc.Name}))
                    {
                        $myobj = "" | Select-Object Name,Time
                        $myobj.Name = ($dc.Name).ToUpper()
                        $myobj.Time = ("{0:n2}" -f ((Get-Date)-$start).TotalSeconds)
                        $dctable += $myobj
                    }
                }
                else{Write-Host "  ! $($dc.Name.ToUpper()) Missing Object [$dn]" -fore Red;$replicated  = $false}
            }
            else
            {
                Write-Host "  ! $($dc.Name.ToUpper()) Failed PING" -fore Red
                if($table -and !($dctable | ?{$_.Name -match $dc.Name}))
                {
                    $myobj = "" | Select-Object Name,Time
                    $myobj.Name = ($dc.Name).ToUpper()
                    $myobj.Time = "N/A"
                    $dctable += $myobj
                }
            }
        }
        if($replicated){$cont = $false}else{$host.UI.RawUI.CursorPosition = $oldpos}
    }
    
    $end = Get-Date
    $duration = "{0:n2}" -f ($end.Subtract($start).TotalSeconds)
    
    Write-Verbose "[MAIN] :: Checking for `$Revert"
    if($Revert)
    {
        Write-Verbose "[MAIN] :: `$Revert Switch passed"
        Write-Verbose "[MAIN] :: Getting Object to set wWWHomePage"
        Write-Verbose "[MAIN] :: `$MyObject = ([ADSI]`"LDAP://$Target/$ADObject`")"
        $MyObject = ([ADSI]"LDAP://$Target/$ADObject")
        if($wwwHomePage)
        {
            Write-Verbose "[MAIN] :: Setting Value to $wwwHomePage"
            $MyObject.wWWHomePage = $wwwHomePage
        }
        else
        {
            Write-Verbose "[MAIN] :: Clearing wWWHomePage"
            $MyObject.PutEx(1,"wWWHomePage",$null)
        }
        Write-Verbose "[MAIN] :: `$MyObject.SetInfo()"
        $MyObject.SetInfo()
    }
    Write-Host "`n    Took $duration Seconds `n" -fore Yellow
    
    
    if($table){$dctable | Sort-Object Time | Format-Table -auto}
}
    
