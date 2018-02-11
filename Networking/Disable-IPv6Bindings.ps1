$LogFolder = $env:ProgramData + '\VDL Nedcar\Logboek'
New-Item -Path $LogFolder -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
$LogFile = $LogFolder + '\Disable-IPv6-transcript.log'
Start-Transcript -Path $LogFile -Force -NoClobber
Write-Output "Disable IPv6 bindings on network adapters."
$adapters = Get-NetAdapterBinding | Where-Object { $_.ComponentID -eq 'ms_tcpip6'} | Select-Object -ExpandProperty Name
if ($adapters)
{
    Write-Output "Adapters with IPv6 bindings found."
    ForEach ($adap in $Adapters)
    {
        Write-Output "Disable IPv6 on adapter: '$($adap)'"
        Disable-NetAdapterBinding -ComponentID ms_tcpip6 -Name $adap -Verbose
    }
}
else
{
    Write-Output "No adapters with IPv6 bindings found."
}
Write-Output "End of script."
Stop-Transcript