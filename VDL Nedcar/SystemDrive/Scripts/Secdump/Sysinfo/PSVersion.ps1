# ---------------------------------------------------------
# Record Powershell version
# Marcel Jussen
# 20-04-2017
# ---------------------------------------------------------
#requires -version 2.0
$logfile = 'C:\Logboek\PSVersion.log'
$Version = $PSVersionTable
"Powershell version $($Version.PSVersion)" | Out-File $logfile
"Major=$($Version.PSVersion.Major)" | Out-File $logfile -Append -NoClobber
"Minor=$($Version.PSVersion.Minor)" | Out-File $logfile -Append -NoClobber
"Build=$($Version.PSVersion.Build)" | Out-File $logfile -Append -NoClobber
"Revision=$($Version.PSVersion.Revision)" | Out-File $logfile -Append -NoClobber
"PSRemotingProtocolVersion=$($Version.PSRemotingProtocolVersion)" | Out-File $logfile -Append -NoClobber
"CLRVersion=$($Version.CLRVersion)" | Out-File $logfile -Append -NoClobber
Write-Host "Powershell version $($Version.PSVersion)"