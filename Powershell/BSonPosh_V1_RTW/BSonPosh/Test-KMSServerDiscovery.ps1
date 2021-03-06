function Test-KMSServerDiscovery
{
    
    <#
        .Synopsis 
            Test KMS server discovery.
            
        .Description
            Test KMS server discovery.
            
        .Parameter DNSSuffix
            DNSSuffix to do discovery on.
            
        .Example
            Test-KMSServerDiscovery
            Description
            -----------
            Test KMS server discovery on local machine
            
        .OUTPUTS
            PSCustomObject (BSonPosh.KMS.DiscoveryResult)
            
        .INPUTS
            System.String
            
        .Link
            N/A
            
        .Notes
            NAME:      Test-KMSServerDiscovery
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param($DNSSuffix)
    
    Write-Verbose " [Test-KMSServerDiscovery] :: cmdlet started"
    Write-Verbose " [Test-KMSServerDiscovery] :: Getting dns primary suffix from registry"
    if(!$DNSSuffix)
    {
        $key = get-item -path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters
        $DNSSuffix = $key.GetValue("Domain")
    }
    Write-Verbose " [Test-KMSServerDiscovery] :: DNS Suffix = $DNSSuffix"
    $record = "_vlmcs._tcp.${DNSSuffix}"
    Write-Verbose " [Test-KMSServerDiscovery] :: SRV Record to query for = $record"
    $NameRegEx = "\s+svr hostname   = (?<HostName>.*)$"
    $PortRegEX = "\s+(port)\s+ = (?<Port>\d+)"
    try
    {
        Write-Verbose " [Test-KMSServerDiscovery] :: Running nslookup"    
        Write-Verbose " [Test-KMSServerDiscovery] :: Command - nslookup -type=srv $record 2>1 | select-string `"svr hostname`" -Context 4,0"
        $results = nslookup -type=srv $record 2>1 | select-string "svr hostname" -Context 4,0
        if($results)
        {
            Write-Verbose " [Test-KMSServerDiscovery] :: Found Entry: $Results"
        }
        else
        {
            Write-Verbose " [Test-KMSServerDiscovery] :: No Results found"
            return
        }
        Write-Verbose " [Test-KMSServerDiscovery] :: Creating Hash Table"    
        $myobj = @{}
        switch -regex ($results -split "\n")
        {
            $NameRegEx  {
                            Write-Verbose " [Test-KMSServerDiscovery] :: ComputerName = $($Matches.HostName)"    
                            $myobj.ComputerName = $Matches.HostName
                        }
            $PortRegEX  {
                            Write-Verbose " [Test-KMSServerDiscovery] :: IP = $($Matches.Port)"
                            $myobj.Port = $Matches.Port
                        }
            Default     {
                            Write-Verbose " [Test-KMSServerDiscovery] :: Processing line: $_"
                        }
        }
        Write-Verbose " [Test-KMSServerDiscovery] :: Creating Object"
        $obj = New-Object PSObject -Property $myobj
        $obj.PSTypeNames.Clear()
        $obj.PSTypeNames.Add('BSonPosh.KMS.DiscoveryResult')
        $obj
    }
    catch
    {
        Write-Verbose " [Test-KMSServerDiscovery] :: Error: $($Error[0])"
    }

}