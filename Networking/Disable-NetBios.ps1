pin$LogFolder = $env:ProgramData + '\VDL Nedcar\Logboek'
New-Item -Path $LogFolder -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
$LogFile = $LogFolder + '\Disable-NETBIOS-transcript.log'
Start-Transcript -Path $LogFile -Force -NoClobber
Write-Output "Disable NETBIOS on network adapters."
gcim Win32_NetworkAdapterConfiguration -Filter 'ipenabled = true' |
    Invoke-CimMethod -MethodName SetTcpipNetbios -Arguments @{ TcpipNetbiosOptions = 2 }
Write-Output "End of script."
Stop-Transcript