##############################################################################################################
# 
# Name        : DisablePowerSavingForWLAN.ps1
# Author      : Ingmar Verheij - http://www.ingmarverheij.com
# Version     : 1.0, 1 may 2014
#               - Initial release
#
# Description : Prevents Windows from saving power by disabling the WiFi adapter
# 
# Dependencies : (none)
#
# Usage        : The script runs without parameter but requires elevated privileges, this is enforced by the script.
#                
#                
##############################################################################################################



# ------------------------------ Functions --------------------------------------
function Use-RunAs {    
    # Check if script is running as Adminstrator and if not use RunAs 
    # Use Check Switch to check if admin 
    # http://gallery.technet.microsoft.com/scriptcenter/63fd1c0d-da57-4fb4-9645-ea52fc4f1dfb
    
    param([Switch]$Check) 
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") 
    if ($Check) { return $IsAdmin }     
    if ($MyInvocation.ScriptName -ne "") 
    {  
        if (-not $IsAdmin)  
        {  
            try 
            {  
                $arg = "-file `"$($MyInvocation.ScriptName)`"" 
                Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction 'stop'  
            } 
            catch 
            { 
                Write-Warning "Error - Failed to restart script with runas"  
                break               
            } 
            exit # Quit this session of powershell 
        }  
    }  
    else  
    {  
        Write-Warning "Error - Script must be saved as a .ps1 file first"  
        break  
    }  
}
# -------------------------------------------------------------------------------


# Ensure the script runs with elevated priviliges
Use-RunAs
# -


# Start log transcript
Start-Transcript -Path ($MyInvocation.MyCommand.Definition -replace 'ps1','log') -Append | out-null
# -


#Inform user
Write-Host -ForegroundColor White "Iterating through network adapters"
$intNICid=0; do
{
	#Read network adapter properties
	$objNICproperties = (Get-ItemProperty -Path ("HKLM:\SYSTEM\CurrentControlSet\Control\Class\{0}\{1}" -f "{4D36E972-E325-11CE-BFC1-08002BE10318}", ( "{0:D4}" -f $intNICid)) -ErrorAction SilentlyContinue)
	
	#Determine if the Network adapter index exists 
	If ($objNICproperties)
	{
		#Filter network adapters
		# * only Ethernet adapters (ifType = ieee80211(71) - http://www.iana.org/assignments/ianaiftype-mib/ianaiftype-mib)
		# * root devices are exclude (for instance "WAN Miniport*")
		# * software defined network adapters are excluded (for instance "RAS Async Adapter")
		If (($objNICproperties."*ifType" -eq 71) -and 
		    ($objNICproperties.DeviceInstanceID -notlike "ROOT\*") -and
			($objNICproperties.DeviceInstanceID -notlike "SW\*")
			)
		{

			#Read hardware properties
			$objHardwareProperties = (Get-ItemProperty -Path ("HKLM:\SYSTEM\CurrentControlSet\Enum\{0}" -f $objNICproperties.DeviceInstanceID) -ErrorAction SilentlyContinue)
			If ($objHardwareProperties.FriendlyName)
			{ $strNICDisplayName = $objHardwareProperties.FriendlyName }
			else 
			{ $strNICDisplayName = $objNICproperties.DriverDesc }
			
			#Read Network properties
			$objNetworkProperties = (Get-ItemProperty -Path ("HKLM:\SYSTEM\CurrentControlSet\Control\Network\{0}\{1}\Connection" -f "{4D36E972-E325-11CE-BFC1-08002BE10318}", $objNICproperties.NetCfgInstanceId) -ErrorAction SilentlyContinue)
		      
            #Inform user
			Write-Host -NoNewline -ForegroundColor White "   ID     : "; Write-Host -ForegroundColor Yellow ( "{0:D4}" -f $intNICid)
			Write-Host -NoNewline -ForegroundColor White "   Network: "; Write-Host $objNetworkProperties.Name
            Write-Host -NoNewline -ForegroundColor White "   NIC    : "; Write-Host $strNICDisplayName
            Write-Host -ForegroundColor White "   Actions:"

            #Disable power saving
            Set-ItemProperty -Path ("HKLM:\SYSTEM\CurrentControlSet\Control\Class\{0}\{1}" -f "{4D36E972-E325-11CE-BFC1-08002BE10318}", ( "{0:D4}" -f $intNICid)) -Name "PnPCapabilities" -Value "24" -Type DWord
            Write-Host -ForegroundColor Green ("   - Power saving disabled")
            Write-Host ""
		}
	} 
	
	#Next NIC ID
	$intNICid+=1
} while ($intNICid -lt 255)


# Request the user to reboot the machine
Write-Host -NoNewLine -ForegroundColor White "Please "
Write-Host -NoNewLine -ForegroundColor Yellow "reboot"
Write-Host -ForegroundColor White " the machine for the changes to take effect."

# Stop writing to log file
Stop-Transcript | out-null