function pig 
{
    param($ComputerName)
    $arguments = "/T:0C","/k ping -t $ComputerName -l 2400 -4"
    $Cmd = "cmd.exe"
    Microsoft.PowerShell.Management\Start-Process $cmd -ArgumentList $arguments
}
    
