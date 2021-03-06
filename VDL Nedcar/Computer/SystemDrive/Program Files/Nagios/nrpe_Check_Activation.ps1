#------------------------------------------------------------------
# Check OS Activation status
#
# Author: Marcel Jussen
# (8-10-2014)
#
# Revised: 8-10-2014
#------------------------------------------------------------------

$VERSION = "1.00"

$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3

#------------------------------------------------------------------
Function OS_Ver {
	param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$DNSHostName = $Env:COMPUTERNAME
    )
    process {
		try {
			$OSVER = (gwmi Win32_OperatingSystem -ComputerName $DNSHostName).version	
			$Version = $null
			if($OSVER -ne $null) { $Version = $OSVER }
		} catch {
			$Version = $null
		}
		return $Version
	}	
}

function Get-ActivationStatus {
[CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$DNSHostName = $Env:COMPUTERNAME
    )
    process {
        try {
            $wpa = Get-WmiObject SoftwareLicensingProduct -ComputerName $DNSHostName `
            -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f'" `
            -ErrorAction Stop
        } catch {
            $status = New-Object ComponentModel.Win32Exception ($_.Exception.ErrorCode)
            $wpa = $null    
        }		
        $out = New-Object psobject -Property @{
            ComputerName = $DNSHostName;		
			Description = [string]::Empty;
			LicenseStatus = [string]::Empty;
            Status = [string]::Empty;
			GracePeriodRemaining = [decimal];
        }
        if ($wpa) {
            :outer foreach($item in $wpa) {
				$out.GracePeriodRemaining = [decimal]::Round($item.GracePeriodRemaining / 1440)
				$out.LicenseStatus = $item.LicenseStatus
				$out.Description = $item.Description
                switch ($item.LicenseStatus) {
                    0 {$out.Status = "Unlicensed"}
                    1 {$out.Status = "Licensed"; break outer}
                    2 {$out.Status = "Out-Of-Box Grace Period"; break outer}
                    3 {$out.Status = "Out-Of-Tolerance Grace Period"; break outer}
                    4 {$out.Status = "Non-Genuine Grace Period"; break outer}
                    5 {$out.Status = "Notification"; break outer}
                    6 {$out.Status = "Extended Grace"; break outer}
                    default {$out.Status = "Unknown value"}
                }
            }
        } else {$out.Status = $status.Message}
        return $out
    }
}

#------------------------------------------------------------------

$ScriptName = $myInvocation.MyCommand.Name
$logpath = "C:\Logboek\NAGIOS_" + $scriptName + ".log"
if(Test-Path $logpath) { Remove-Item $logpath -Force -ErrorAction SilentlyContinue }
Add-Content $logpath "Start script $ScriptName"

$ActivationStatus = Get-ActivationStatus
$Status = $ActivationStatus.Status
$ComputerName = $ActivationStatus.Computername
$GracePeriodRemaining = $ActivationStatus.GracePeriodRemaining
$Description = $ActivationStatus.Description

#Check OS
$OS = OS_Ver
if($OS) {
	$OSMain = $OS.Substring(0,1)
	$OS_Check = ($OSMain -eq '5')
} else {
	$OS = 'ERROR!'
	$OS_Check = $True
}

# Cannot show activation status for OS versions 5 and lower.
if($OS_Check) { 
	$msg = "Activation status is not applicable for OS version $OS" 
	Write-Host $msg
	Add-Content $logpath $msg
} else {
	$msg = "Activation status is '$Status' ($GracePeriodRemaining days remaining)" 
	Write-Host $msg
	Add-Content $logpath $msg
	$msg = "$Description, OS Version $OS" 
	Write-Host $msg
	Add-Content $logpath $msg		
}

#------------------------------------------------------------------
# create output result
switch ($ActivationStatus.LicenseStatus) {
	'0' { exit $returnStateCritical }
	'1' { exit $returnStateOK }   
	'2' { exit $returnStateWarning }
	'3' { exit $returnStateWarning }
    '4' { exit $returnStateWarning }
    '5' { exit $returnStateWarning }
    '6' { exit $returnStateWarning }
	default { exit $returnStateOK }   
}