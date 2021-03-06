<#
.SYNOPSIS
    VNB Library - Generic functions

.CREATED_BY
	Marcel Jussen

.CHANGE_DATE
	4-06-2017
 
.DESCRIPTION
    Generic functions not applicable to other modules.
#>
#Requires -version 3.0

Function Test-ComputerAlive {
# ---------------------------------------------------------
# Ping the specified system to check if it is
# switched on.
# ---------------------------------------------------------	
	[CmdletBinding()]
	param (
		[Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
		[Alias("Name","SystemName")]
		[System.String]
		$Computername			
	)
	
	begin { 
		$IsAlive = $null
    } # begin end
    
    process { 
        try {
			$WmiFilter = "Address='" + $Computername + "'"
			$WmiObject = Get-WmiObject -Class Win32_PingStatus -Filter $WmiFilter
			$StatusCode = $WmiObject.StatusCode
			$IsAlive = ($StatusCode -eq 0)			
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
			$IsAlive
        } # finally end
    } # process end
     
    end {
    } # end end		
}
Set-Alias -Name 'IsComputerAlive' -Value 'Test-ComputerAlive'

Function Get-ComputerComment {
# ---------------------------------------------------------
# Get The computer description that is currently stored
# in the computers registry.
# ---------------------------------------------------------
	[CmdletBinding()]
	param ( 
		[parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[system.string]
		$Computername
	)	
	
	Process {
		try {
			if(Test-ComputerAlive $Computername) {
				$Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey( "LocalMachine", $Computername )
				if ( $Registry -eq $Null ) { return $null }	
				$RegKey= $Registry.OpenSubKey( "SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" )	
				if ( $RegKey -eq $Null ) { return $null	}
				[system.string]$Description = $RegKey.GetValue("srvcomment")
				if ( $Description -eq $Null ) {	$Description = "" }
				return $Description
			} else {
				return $null
			}
		}
		catch {
			return $null
		}
	}
}

Function Set-ComputerComment {
# ---------------------------------------------------------
# Set the computer description stored
# in the computers registry.
# ---------------------------------------------------------
	[CmdletBinding()]
	param ( 
		[parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[system.string] 
		$Computername, 
		
		[parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[system.string]
		$Description 
	)	
	
	Process {
		try {
			if(Test-ComputerAlive $Computername) {
				$Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey( "LocalMachine", $Computername )		
				if ( $Registry -eq $Null ) { return $Null }
				$RegPermCheck = [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree 
				$RegKeyRights = [System.Security.AccessControl.RegistryRights]::SetValue
				$RegKey = $Registry.OpenSubKey( "SYSTEM\CurrentControlSet\Services\lanmanserver\parameters", $RegPermCheck, $RegKeyRights )
				if ( $RegKey -eq $Null ) { return $Null }
				$RegKey.SetValue("srvcomment", $Description )
			}
		}
		catch {
			return $null
		}
	}
}

Function Sync-ComputerComment {
# ---------------------------------------------------------
# Check the comment for the specified computer stored in
# it's local registry and compare it with the description
# stored in the active directory.
# If the values are different the local computer comment
# will be overwritten with the AD description.
# ---------------------------------------------------------
	[CmdletBinding()]
	param ( 
		[parameter(Mandatory=$False)]
		[system.string]
		$Computername = $Env:COMPUTERNAME
	)	
	Begin {
		$NtComment = Get-ComputerComment $Computername	
		$AdComment = Get-ComputerAdDescription $Computername		
	}
	Process {
		try {
			if( $NtComment -cne $AdComment ) { Set-ComputerComment $Computername $AdComment }
		}
		catch {
			throw
		}
	}
}

function Get-WirelessSignalInfo {
# --------------------------------------------------------- 
# Returns wireless network information
# ---------------------------------------------------------
	[CmdletBinding(SupportsShouldProcess=$TRUE)]
	param(
  		[parameter(Mandatory=$TRUE,ValueFromPipeline=$TRUE)]
    	[String[]] $ComputerName
	)
	
	begin {
		try {
    		$wlan = invoke-command -computername $ComputerName { (netsh wlan show interfaces) } -ErrorAction SilentlyContinue
  		}		
  		catch [System.Management.Automation.PSArgumentException] {
    		throw $_
  		}		

		$wireless = $wlan -Match '^\s+State'
		if($wireless) {
			$properties = @{ 
				'Name' = [string]($wlan -Match '^\s+Name' -Replace '^\s+Name\s+:\s+','');
            	'Description' = [string]($wlan -Match '^\s+Description' -Replace '^\s+Description\s+:\s+','');
            	'Physical address' = [string]($wlan -Match '^\s+Physical address' -Replace '^\s+Physical address\s+:\s+','');
				'State' = [string]($wlan -Match '^\s+State' -Replace '^\s+State\s+:\s+','');
				'SSID' = [string]($wlan -Match '^\s+SSID' -Replace '^\s+SSID\s+:\s+','');
				'BSSID' = [string]($wlan -Match '^\s+BSSID' -Replace '^\s+BSSID\s+:\s+','');
				'Network type' = [string]($wlan -Match '^\s+Network type' -Replace '^\s+Network type\s+:\s+','');
				'Radio type' = [string]($wlan -Match '^\s+Radio type' -Replace '^\s+Radio type\s+:\s+','');
				'Authentication' = [string]($wlan -Match '^\s+Authentication' -Replace '^\s+Authentication\s+:\s+','');
				'Cipher' = [string]($wlan -Match '^\s+Cipher' -Replace '^\s+Cipher\s+:\s+','');
				'Connection mode' = [string]($wlan -Match '^\s+Connection mode' -Replace '^\s+Connection mode\s+:\s+','');
				'Channel' = [string]($wlan -Match '^\s+Channel' -Replace '^\s+Channel\s+:\s+','');
				'Signal' = [string]($wlan -Match '^\s+Signal' -Replace '^\s+Signal\s+:\s+','');
				'Profile' = [string]($wlan -Match '^\s+Profile' -Replace '^\s+Profile\s+:\s+','')
			}
		} else {
			$properties = @{
				'State' = 'No wireless connection found.';
				'Description' = 'No wireless connection found.';
				'SSID' = $null;
				'BSSID' = $null;
				'Profile' = $null
			}
		}
				
		$object = New-Object –TypeName PSObject –Prop $properties
		$object		
	}	
}

function Get-OSInstallDate {
# --------------------------------------------------------- 
# Return the OS installation date
# ---------------------------------------------------------
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$False)]
		[system.string]
		$Computername = $env:COMPUTERNAME
	)
	begin {
		$retval = $null
	}
	process {
		try {
			$retval = ([WMI]'').ConvertToDateTime((Get-WmiObject -Computer $Computername Win32_OperatingSystem).InstallDate)
		} # try end
		catch { 
            throw 
        } # catch end
		return $retval
	}
}

Function Get-InstalledApplications {
# --------------------------------------------------------- 
# Return the list of installed applications
# ---------------------------------------------------------
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$False)]
		[system.string]
		$computername = $env:COMPUTERNAME
	)
 
 	Begin {
 		$array = $null
    	#Define the variable to hold the location of Currently Installed Programs
    	$UninstallKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
	}

	Process {
    	#Create an instance of the Registry Object and open the HKLM base key
    	$reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computername)     
    	$regkey=$reg.OpenSubKey($UninstallKey) 
		if($regkey) {
    		$subkeys=$regkey.GetSubKeyNames() 
			$array = @()    	
			#Open each Subkey and use GetValue Method to return the required values for each
    		foreach($key in $subkeys){
        		$thisKey=$UninstallKey+"\\"+$key 
        	
				$thisSubKey=$reg.OpenSubKey($thisKey) 
        		$obj = New-Object PSObject
        		$obj | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $computername
        		$obj | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $($thisSubKey.GetValue("DisplayName"))
        		$obj | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value $($thisSubKey.GetValue("DisplayVersion"))
        		$obj | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value $($thisSubKey.GetValue("InstallLocation"))
        		$obj | Add-Member -MemberType NoteProperty -Name "Publisher" -Value $($thisSubKey.GetValue("Publisher"))
        		$array += $obj
			}
    	} 
	
		#Define the variable to hold the location of Currently Installed Programs
    	$UninstallKey="SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall" 

    	#Create an instance of the Registry Object and open the HKLM base key
    	$reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computername)     
    	$regkey=$reg.OpenSubKey($UninstallKey) 
		if($regkey) {
    		$subkeys = $regkey.GetSubKeyNames() 
			if($array -eq $null) { $array = @() }
			#Open each Subkey and use GetValue Method to return the required values for each
    		foreach($key in $subkeys){
        		$thisKey = $UninstallKey+"\\"+$key         	
				$thisSubKey = $reg.OpenSubKey($thisKey) 
        		$obj = New-Object PSObject
        		$obj | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $computername
        		$obj | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $($thisSubKey.GetValue("DisplayName"))
        		$obj | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value $($thisSubKey.GetValue("DisplayVersion"))
        		$obj | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value $($thisSubKey.GetValue("InstallLocation"))
        		$obj | Add-Member -MemberType NoteProperty -Name "Publisher" -Value $($thisSubKey.GetValue("Publisher"))
        		$array += $obj			
			}
    	} 
		return $array
	}
}

function Get-HBAInfo {
# --------------------------------------------------------- 
# Get host bus adapter information
# ---------------------------------------------------------
	[CmdletBinding()] 
	Param ( 
		[Parameter(Mandatory=$false, ValueFromPipeline=$true, Position=0)] 
		$computername = $env:COMPUTERNAME
	) 
	
	Begin { 
		$Namespace = "root\WMI" 
	} 
	
	Process { 		
		try {
			$port = Get-WmiObject -Class MSFC_FibrePortHBAAttributes -Namespace $Namespace @PSBoundParameters -ErrorAction SilentlyContinue
			$hbas = Get-WmiObject -Class MSFC_FCAdapterHBAAttributes -Namespace $Namespace @PSBoundParameters -ErrorAction SilentlyContinue
			if($hbas) {
				$hbaProp = $hbas | Get-Member -MemberType Property, AliasProperty | Select -ExpandProperty name | ? {$_ -notlike "__*"} 
		
				ForEach($hba in $hbas) { 
					Add-Member -MemberType NoteProperty -InputObject $hba -Name FabricName -Value ( ($port |? { $_.instancename -eq $hba.instancename}).attributes | ` 
						Select ` @{Name='Fabric Name';Expression={(($_.fabricname | % {"{0:x2}" -f $_}) -join ":").ToUpper()}}, ` 
						@{Name='Port WWN';Expression={(($_.PortWWN | % {"{0:x2}" -f $_}) -join ":").ToUpper()}} ) -passThru 
				}
			}
		} 
		catch {
		}
	} 
}

function Get-MPIOSupportedDevices {
# --------------------------------------------------------- 
# Returns MPIO device information
# ---------------------------------------------------------
	[CmdletBinding()] 
	Param ( 
		[Parameter(Mandatory=$false, ValueFromPipeline=$true, Position=0)] 
		$computername = $env:COMPUTERNAME
	) 
	
	Begin { 
		$Namespace = "root\WMI" 
	} 
	
	Process { 		
		try {	
			if ( (Get-HBAInfo $computername) ) {
				$MPIOSupportedDevices = Get-WmiObject -Class MSDSM_SUPPORTED_DEVICES_LIST -Namespace $Namespace @PSBoundParameters -ErrorAction SilentlyContinue
				$MPIOSupportedDevices.DeviceId
			}
		}
		catch {		
		}
	}
}

Function Start-Executable {
# ---------------------------------------------------------
# Execute a command line program
# This functions sets variable $LASTEXITCODE which contains the exit code of the executed program.
# ---------------------------------------------------------
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[system.string] 
		$FilePath,
	
		[parameter(Mandatory=$True)]
		[String[]]
		$ArgumentList
	)
	
  	Begin {
  		$OFS = " "
	}
	
	Process {
  		$process = New-Object System.Diagnostics.Process
  		$process.StartInfo.FileName = $FilePath
  		$process.StartInfo.Arguments = $ArgumentList
  		$process.StartInfo.UseShellExecute = $false
  		$process.StartInfo.RedirectStandardOutput = $true
  		if ( $process.Start() ) {
    		$output = $process.StandardOutput.ReadToEnd() -replace "\r\n$",""
    		if ( $output ) {
      			if ( $output.Contains("`r`n") ) { $output -split "`r`n" }
      			elseif ( $output.Contains("`n") ) { $output -split "`n" }
			} else {
				$output
      		}
		}
		
    	$process.WaitForExit()
    		& "$Env:SystemRoot\system32\cmd.exe" `
      		/c exit $process.ExitCode
	}	
}

Function Set-Wallpaper {
# ---------------------------------------------------------
# Set-Wallpaper "C:\Users\Joel\Pictures\Wallpaper\Dual Monitor\mandolux-tiger.jpg" "Tile"
# ---------------------------------------------------------
	[CmdletBinding()]
	Param(
   		[Parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
		[Alias("FullName")]
		[string]
		$Path
	,
   		[Parameter(Position=1, Mandatory=$false)]
   		[String][ValidateSet("Tile", "Center", "Stretch", "NoChange")]
   		$Style = "NoChange"
	)

	BEGIN {
		try {
   			$WP = [Wallpaper.Setter]
		} catch {
   			$WP = add-type @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Wallpaper
{
   public enum Style : int
   {
       Tile, Center, Stretch, NoChange
   }

   public class Setter {
      public const int SetDesktopWallpaper = 20;
      public const int UpdateIniFile = 0x01;
      public const int SendWinIniChange = 0x02;

      [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
      private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
      
      public static void SetWallpaper ( string path, Wallpaper.Style style ) {
        RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
         switch( style )
         {
            case Style.Stretch :
               key.SetValue(@"WallpaperStyle", "2") ; 
               key.SetValue(@"TileWallpaper", "0") ;
               break;
            case Style.Center :
               key.SetValue(@"WallpaperStyle", "1") ; 
               key.SetValue(@"TileWallpaper", "0") ; 
               break;
            case Style.Tile :
               key.SetValue(@"WallpaperStyle", "1") ; 
               key.SetValue(@"TileWallpaper", "1") ;
               break;
            case Style.NoChange :
               break;
         }
         key.Close();
         SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
      }
   }
}
"@ -Passthru
		}
	}
	PROCESS {
	## you may consider $path_as_path = [IO.Path]::GetFullPath( $Path ) instead of $(Convert-Path $Path) 
   		$WP::SetWallpaper( (Convert-Path $Path), $Style )
	}
}

Function Get-UpTime {
# ---------------------------------------------------------
# Returns system uptime
#
# Usage syntax: 
# For local computer where script is being run: Get-Uptime
# For remote computer: Get-Uptime -ComputerName "systemx"
# For list of remote computers: Get-Uptime -ComputerList "c:\temp\computerlist.txt" 
# ---------------------------------------------------------
	[CmdletBinding()]
	param  (     
		[Parameter(Position=0,ValuefromPipeline=$true)]
		[system.string]
		[alias("cn","Computername")]
		$computer,     
		
		[Parameter(Position=1,ValuefromPipeline=$false)]
		[system.string]
		$computerlist
	)   
	
	begin {
		If (-not ($computer -or $computerlist)) { $computers = $Env:COMPUTERNAME }   
		If ($computer) { $computers = $computer	}   
		If ($computerlist) { $computers = Get-Content $computerlist	} 
	}
	
	process {	
		try {
			$Info = @{}   
			foreach ($computer in $computers) {     
				$wmi = Get-WmiObject -ComputerName $computer -Query "SELECT LastBootUpTime FROM Win32_OperatingSystem" -ErrorAction SilentlyContinue
				$now = Get-Date    
				$boottime = $wmi.ConvertToDateTime($wmi.LastBootUpTime)     
				$uptime = $now - $boottime    
				$d =$uptime.days     
				$h =$uptime.hours     
				$m =$uptime.Minutes     
				$s = $uptime.Seconds     
				$Info.$computer = "$d Days $h Hours $m Min $s Sec"
			}
			
		} #try end
		
		catch {
 
            throw
 
        } # catch end
		
		finally {
			# return results
			($Info.GetEnumerator() | ForEach-Object { New-Object PSObject -Property @{ Systemname = $_.Key; Uptime = $_.Value; Last_Reboot = $boottime } | Select-Object -Property Systemname, Uptime, Last_Reboot })
		}		
	} # process end
}
Set-Alias -Name 'Get-ComputerUptime' -Value 'Get-UpTime'

function Test-OSIs64Bit {
# ---------------------------------------------------------
# Tests if the current operating system is 64-bit.
# ---------------------------------------------------------
	Set-StrictMode -Version 'Latest'
    return ([Environment]::Is64BitOperatingSystem)
}

function Test-OSIs32Bit {
# ---------------------------------------------------------
# Tests if the current operating system is 32-bit.
# ---------------------------------------------------------
    Set-StrictMode -Version 'Latest'
    return -not (Test-OSIs64Bit)
}

Function Get-SQLVersionInfo {
# ---------------------------------------------------------
# Returns MS SQL Server information installed on a machine
# ---------------------------------------------------------
<#
    .SYNOPSIS
        Checks remote registry for SQL Server Edition and Version.

    .DESCRIPTION
        Checks remote registry for SQL Server Edition and Version.

    .PARAMETER  ComputerName
        The remote computer your boss is asking about.

    .EXAMPLE
        PS C:\> Get-SQLVersionInfo -ComputerName mymssqlsvr 

    .EXAMPLE
        PS C:\> $list = cat .\sqlsvrs.txt
        PS C:\> $list | % { Get-SQLVersionInfo $_ | select ServerName,Edition }    

#>
	[CmdletBinding()]
	param(
    	# a computer name
    	[Parameter(Position=0, Mandatory=$true)]
    	[ValidateNotNullOrEmpty()]
    	[System.String]
    	$ComputerName
	)

	# create an empty psobject (hashtable)
	$SqlVer = New-Object PSObject
	$SqlVer | Add-Member -MemberType NoteProperty -Name ServerName -Value $ComputerName	

	# Test to see if the remote is up
	if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {    
    	$type = [Microsoft.Win32.RegistryHive]::LocalMachine    
    	$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $ComputerName)

		$InstanceKey = "SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
		$InstanceKeySysWow = "SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\Instance Names\SQL"
    	$SysWow = $False
    	$SqlKey = $regKey.OpenSubKey($InstanceKey)
		# If the usual key does not work try the syswow key
		if($SqlKey -eq $null) {
			$SqlKey = $regKey.OpenSubKey($InstanceKeySysWow)
			$SysWow = $True
		}	
		if( $SqlKey ) {
			$Instances = $SqlKey.GetValueNames()
    		# parse each value in the reg_multi InstalledInstances 
    		Foreach($instance in $Instances) {
        		$instName = $SqlKey.GetValue("$instance") # read the instance name
				$SubKey = "SOFTWARE\Microsoft\Microsoft SQL Server\$instName\Setup"
				if($SysWow) { 
					$SubKey = "SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\$instName\Setup" 
				}
        		$instKey = $regKey.OpenSubkey($SubKey) # sub in instance name
        		# add stuff to the psobj
				$SqlVer | Add-Member -MemberType NoteProperty -Name Instance -Value $instName -Force # read Ed value
				$SqlVer | Add-Member -MemberType NoteProperty -Name Version -Value $instKey.GetValue("Version") -Force # read Ver value
        		$SqlVer | Add-Member -MemberType NoteProperty -Name Edition -Value $instKey.GetValue("Edition") -Force # read Ed value				        		
        		# return an object, useful for many things        	
				$SqlVer     		
			}
		} else {		
			$InstanceKey = "SOFTWARE\Microsoft\Microsoft SQL Server"
			$InstanceKeySysWow = "SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server"
    		$SysWow = $False
    		$SqlKey = $regKey.OpenSubKey($InstanceKey)
			# If the usual key does not work try the syswow key
			if($SqlKey -eq $null) {
				$SqlKey = $regKey.OpenSubKey($InstanceKeySysWow)
				$SysWow = $True
			}	
			if( $SqlKey ) {				
				$SqlVer | Add-Member -MemberType NoteProperty -Name Instance -Value "MS SQL tools found. No SQL instance found."-Force # read Ed value
				$SqlVer | Add-Member -MemberType NoteProperty -Name Version -Value "" -Force # read Ver value
				$SqlVer | Add-Member -MemberType NoteProperty -Name Edition -Value "" -Force # read Ed value			        	
        		# return an object, useful for many things        	
				$SqlVer
			} else {
				$SqlVer | Add-Member -MemberType NoteProperty -Name Instance -Value "No SQL found."-Force # read Ed value
				$SqlVer | Add-Member -MemberType NoteProperty -Name Version -Value "" -Force # read Ver value
				$SqlVer | Add-Member -MemberType NoteProperty -Name Edition -Value "" -Force # read Ed value			        	
        		# return an object, useful for many things        	
				$SqlVer
			}
		}
	} else {		
		$SqlVer | Add-Member -MemberType NoteProperty -Name Instance -Value "Cannot connect to computer" -Force # read Ed value
    	$SqlVer | Add-Member -MemberType NoteProperty -Name Version -Value "" -Force # read Ed value
		$SqlVer | Add-Member -MemberType NoteProperty -Name Edition -Value "" -Force # read Ed value
    	# return an object, useful for many things
    	$SqlVer	
	}	
}

# --------------------------------------------------------- 
# Export aliases
# --------------------------------------------------------- 
export-modulemember -alias * -function *