#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# VDL Nedcar - Information Management
# Marcel Jussen
#
#
#
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#requires -version 2.0
# enforcing PowerShell version

[CmdletBinding()]
param
(
)

# enforces all errors to become terminating unless you override with 
# per-command -ErrorAction parameters or wrap in a try-catch block
$script:ErrorActionPreference = "Stop"

# Ensures you only refer to variables that exist (great for typos) and 
# enforces some other “best-practice” coding rules.
Set-StrictMode -Version Latest

# gets the absolute path of the folder containing the script that is running. 
$PSScriptRoot = $MyInvocation.MyCommand.Path | Split-Path

Function Get-SCCM-SiteCode {
	[CmdletBinding()]
    Param (
         [Parameter(Mandatory=$True,HelpMessage="Please Enter Primary Server Site Server")]
                $SiteServer         
         )	
	Try {        		
		# Enable terminating error with ErrorAction
		$providerLocation = gcim -ComputerName $siteServerName -Namespace root\sms SMS_ProviderLocation -filter "ProviderForLocalSite='True'" -ErrorAction Stop
		$providerLocation.SiteCode
    }
    Catch {	
		# Catch terminating error
		$ErrorMessage = $_.Exception.Message
    	$FailedItem = $_.Exception.ItemName
		Write-Host "ERROR $FailedItem $ErrorMessage"
    }
}

$siteServerName = 's007'
Get-SCCM-SiteCode -SiteServer $siteServerName
