# ---------------------------------------------------------
# Save all BDE information to a CSV file
# Marcel Jussen
# 6-11-2014
# ---------------------------------------------------------

# ---------------------------------------------------------
Import-Module VNB_PSLIb
# ---------------------------------------------------------

Function Create-CSV
{
  "Machine,CN,RecoveryPassword,CreationDate" | Out-File $output -Encoding ASCII
  
  # Get ALL computers from AD
  $comps = Get-ADComputer -Filter *

  # Get Computers from a specific OU
  # $comps = Get-ADComputer -Filter * -SearchBase ($ou + $searchbase)  

  ForEach ($comp In $comps)
  {
    $comp_dn = $comp.DistinguishedName
    $recovery_info = Get-ADObject -Filter 'ObjectClass -eq "msFVE-RecoveryInformation"' -SearchBase $comp_dn -Properties cn,msfve-recoverypassword,whencreated

    ForEach ($info In $recovery_info)
    {
      Try
      {	  	
        "$($comp.Name),$($info.cn),$($info.'msfve-recoverypassword'),$($info.whencreated)" | Out-File $output -Append -Encoding ASCII		
      }
      Catch
      {
        Write-Host "$($_.Exception.Message)" -foregroundcolor Red
      }
    }
  }
}

#----------------------------------------------------------
#STATIC VARIABLES
#----------------------------------------------------------
$script_parent     = Split-Path -Parent $MyInvocation.MyCommand.Definition
$output            = "\\s008\osd$\Bitlocker_Recovery\recovery_keys.csv"

$script:searchbase = ""
$script:ou         = "OU=Clients"

Try
{
  If (Test-Path $output) { $delete = Remove-Item $output -Force -ErrorAction Stop }
}
Catch
{
  Write-Host "$($_.Exception.Message)" -foregroundcolor Red
  Break
}

$base = $env:USERDNSDOMAIN.Split(".")
ForEach ($b In $base)
{
  $searchbase += ",DC=$($b)"
}

#----------------------------------------------------------
#LOAD AD MODULE
#----------------------------------------------------------
Try { Import-Module ActiveDirectory } Catch { Write-Host "[ERROR]`t $($_.Exception.Message)" }

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "SCCM-Save_BDE_to_CSV-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

If (Test-Path $output) { $delete = Remove-Item $output -Force -ErrorAction SilentlyContinue }

Create-CSV

$SCCM_Package_ID = "VNB00219"
$SCCM_Server = 's007.nedcar.nl'
$SCCM_SiteCode = 'VNB'
$DistributionPointGroup = "VDL Nedcar client distribution group"

if(Test-Path($output)) {
	Echo-Log "CVS creation was successfull."
	
	# Trigger SCCM site to update package
	Echo-Log "Trying to connect to Root\SMS\Site_$SCCM_SiteCode on $SCCM_Server"
	$DPGroupQuery = Get-WmiObject -ComputerName "$SCCM_Server" -Namespace "Root\SMS\Site_$SCCM_SiteCode" -Class SMS_DistributionPointGroup -Filter "Name='$DistributionPointGroup'" -ErrorAction SilentlyContinue
	if($DPGroupQuery) { 
		$name = $DPGroupQuery.Name
		Echo-Log "Successfully connected to Root\SMS\Site_$SCCM_SiteCode"
		Echo-Log "Forcing update of package ID $SCCM_Package_ID"
		$result = $DPGroupQuery.ReDistributePackage($SCCM_Package_ID)
		$val = $result.ReturnValue
		Echo-Log "Return value: $val"
	} else {
		Echo-Log "ERROR: Could not connect to WMI provider on $SCCM_Server"
	}
} else {
	Echo-Log "ERROR: CSV file was not created."
}

# We are done.
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

Close-LogSystem