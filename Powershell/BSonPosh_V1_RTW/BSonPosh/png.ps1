function png
{
    param($ComputerName)
    $arguments = "/T:0C","/k ping -t $ComputerName -4"
    $Cmd = "cmd.exe"
    Microsoft.PowerShell.Management\Start-Process $cmd -ArgumentList $arguments
}
    
