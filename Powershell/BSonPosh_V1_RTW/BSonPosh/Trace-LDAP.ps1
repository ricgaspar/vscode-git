function Trace-LDAP
{
    
    Param($file = ".\ldap.etl",
          $flag = "x1FFFDFF3",
          $guid = "LDAP",
          $SessionName = "mytrace",
          $exe,
          [switch]$start,
          [switch]$ADSI,
          [switch]$LDAP
    )
    if(Test-Path $pwd\tracelog.exe)
    {
        $tracelog = "$pwd\tracelog.exe"
    }
    elseif(get-command tracelog.exe)
    {
        $tracelog = "tracelog.exe"
    }
    else
    {
        throw "Missing tracelog.exe"
        return 1
    }
    
    switch -exact ($guid)
    {
        "LDAP"  {$myguid = "`#099614a5-5dd7-4788-8bc9-e29f43db28fc"}
        "ADSI"  {$myguid = "`#7288c9f8-d63c-4932-a345-89d6b060174d"}
        Default {$myguid = $_}
    }

    Write-Host

    if($start)
    {
        Write-Host " Action: Start" -fore Yellow
        Write-Host " GUID:   $GUID" -fore Yellow
        Write-Host " File:   $file" -fore Yellow
        Write-Host " Flag:   $flag" -fore Yellow
        if($exe){Write-Host " Exe:    $exe" -fore Yellow}
        
    }
    else
    {
        Write-Host " State: Disabled" -fore Red
    }

    Write-Host

    if(!(test-Path "HKLM:\System\CurrentControlSet\Services\ldap\tracing\$exe") -and $exe)
    {
        new-Item -path "HKLM:\System\CurrentControlSet\Services\ldap\tracing" -name $exe | out-Null
    }

    if($start)
    {
        $cmd = "$tracelog -start '$SessionName' -f $file -flag $flag -guid $myguid"
    }
    else
    {
        $cmd = "$tracelog -stop $SessionName"
    }

    Write-Host
    Write-Host "==========================" -fore White -back black
    write-Host "Running Command:" -fore White
    Write-Host " ==> $cmd" -fore Yellow
    invoke-Expression $cmd 
    Write-Host "==========================" -fore White -back black
    Write-Host


}
    
