#
# Marcel Jussen
# 26-3-2015
#

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

$SiteServerName = 's007'
$SiteCode = Get-SCCM-SiteCode -SiteServer $siteServerName

