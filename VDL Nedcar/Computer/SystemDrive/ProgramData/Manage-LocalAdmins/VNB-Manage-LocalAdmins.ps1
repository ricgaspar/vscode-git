<# 
.SYNOPSIS 
    Local Administrator Management
 
.DESCRIPTION 
    Manage Local Administrators on VDL Nedcar workplace
     
.EXAMPLE 	
    .\VNB-Manage-LocalAdmins.ps1
	
.DEPENDENCIES
	Powershell 3
	Powershell VNB Library
	 
.NOTES 
    FileName:	VNB-Manage-LocalAdmins.ps1
    Author:		Marcel Jussen
    Contact:	m.jussen@vdlnedcar.nl
    Created: 	6-9-2016
    Updated: 	20-12-2016
    Version: 	1.0.1.3

    Changes:    Renewed component naming. Removed unneeded functions. 
				Added scheduled time from SQL.
				Added schedule check and re-scheduling functions.
				Store script version in SQL.
#>
Param (
	[parameter(Mandatory=$false, HelpMessage="Create verbose logging.")]
    [switch]$VerboseLogging = $False,
	
	[parameter(Mandatory=$false, HelpMessage="Installs the script and scheduled task (forced).")]
    [switch]$Install = $False
)

Begin {
	Clear
	Import-Module VNB_PSLib -Force
	
	$Global:ScriptRegPath = 'HKLM:\SOFTWARE\VDL Nedcar\VNB-Manage-LocalAdmins'
	if(!(Test-Path 'HKLM:\SOFTWARE\VDL Nedcar')) { New-Item -Path 'HKLM:\Software' -Name 'VDL Nedcar' –Force }
	if(!(Test-Path $Global:ScriptRegPath)) { New-Item -Path 'HKLM:\Software\VDL Nedcar' -Name 'VNB-Manage-LocalAdmins' –Force }
	
	$Global:ScriptVersion = '1.0.1.3'
	Set-ItemProperty -Path $Global:ScriptRegPath -Name ScriptVersion -Value $Global:ScriptVersion -ErrorAction SilentlyContinue		
	Set-ItemProperty -Path $Global:ScriptRegPath -Name Version -Value $Global:ScriptVersion -ErrorAction SilentlyContinue		
	
	Set-ItemProperty -Path $Global:ScriptRegPath -Name Switch-VerboseLogging -Value $VerboseLogging -ErrorAction SilentlyContinue		
	Set-ItemProperty -Path $Global:ScriptRegPath -Name Switch-Install -Value $Install -ErrorAction SilentlyContinue		
		
	# The path and name for the script as it is started
	$Global:ScriptName = $myInvocation.MyCommand.Name
	Set-ItemProperty -Path $Global:ScriptRegPath -Name ScriptName -Value $Global:ScriptName -ErrorAction SilentlyContinue
	$Global:ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition
	Set-ItemProperty -Path $Global:ScriptRegPath -Name ScriptPath -Value $Global:ScriptPath -ErrorAction SilentlyContinue
	
	# The path of the log file to maintain
	$Global:ScriptLogPath = $Env:ProgramData + '\VDL Nedcar\Manage-LocalAdmins'
	Set-ItemProperty -Path $Global:ScriptRegPath -Name ScriptLogPath -Value $Global:ScriptLogPath -ErrorAction SilentlyContinue
	
	# The path of the ULD connection file to use
	$Global:UDLFilename = Join-Path -Path $Global:ScriptPath -ChildPath 'VNB-Manage-LocalAdmins.udl'
	Set-ItemProperty -Path $Global:ScriptRegPath -Name UDLFilename -Value $Global:UDLFilename -ErrorAction SilentlyContinue
		
	# The path of the XML Scheduled Task definition file
	$Global:XMLFilename = Join-Path -Path $Global:ScriptPath -ChildPath 'VNB-Manage-LocalAdmins.xml'
	Set-ItemProperty -Path $Global:ScriptRegPath -Name XMLFilename -Value $Global:XMLFilename -ErrorAction SilentlyContinue
	
	# Use secdump UDL file which must be in the same path where this script was started.
	$CurrentUDL = Join-Path -Path $Global:ScriptPath -ChildPath 'VNB-Manage-LocalAdmins.udl'
	Set-ItemProperty -Path $Global:ScriptRegPath -Name UDLCurrent -Value $CurrentUDL -ErrorAction SilentlyContinue
	$Global:UDLConnection = Read-UDLConnectionString $CurrentUDL	
	Set-ItemProperty -Path $Global:ScriptRegPath -Name UDLConnection -Value $Global:UDLConnection -ErrorAction SilentlyContinue
		
}

Process {

# Functions

	Function Update-StatusRecord {
    #-----------------------------------
    # Send status record to database
    #-----------------------------------
		[Cmdletbinding()] 
		Param (   			
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
  			[string]$Component,
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
  			[string]$LogText,
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
  			[Int]$Severity
  		)		
		Process {
			$LogComponent = 'Update-StatusRecord'
			Try {
				$Query = "exec [VNB_MLA].[dbo].[sp_VNB_LOCALADMINS_UPDATESTATUSLOG] '$Env:COMPUTERNAME','$Component','$LogText',$Severity"
				$Results = Invoke-SQLQuery -query $Query -conn $Global:UDLConnection
			}
			Catch {
				$ErrorMessage = $_.Exception.Message
    			$FailedItem = $_.Exception.ItemName
				Write-LogEntry "ERROR: Item:[$FailedItem] Message:$ErrorMessage" -Severity 3 -Component $LogComponent				
			}
		}		
	}

    function Write-LogEntry {
    #-----------------------------------
    # Send status record to log file
    #-----------------------------------
        param(
            [parameter(Mandatory=$true, HelpMessage="Value added to the smsts.log file.")]
            [ValidateNotNullOrEmpty()]
            [string]$Value,
 
            [parameter(Mandatory=$true, HelpMessage="Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("1", "2", "3")]
            [string]$Severity,
			
			[parameter(Mandatory=$false, HelpMessage="Component")]
            [string]$Component = 'Write-LogEntry',
 
            [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
            [ValidateNotNullOrEmpty()]
            [string]$FileName = "VNB-Manage-LocalAdmins.log"
        )
		
        # Create log file location
		if(Test-Path $Global:ScriptLogPath) {
		} else {
			New-FolderStructure $Global:ScriptLogPath
		
		}
		
        $LogFilePath = Join-Path -Path $Global:ScriptLogPath -ChildPath $FileName
 
        # Construct time stamp for log entry
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))
 
        # Construct date for log entry
        $Date = (Get-Date -Format "MM-dd-yyyy")
 
        # Construct context for log entry
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)		
 
        # Construct final log entry
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""$Component"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
     
        # Add value to log file
		if($Severity -eq 1) { Write-Host $Value -ForegroundColor Blue }
		if($Severity -eq 2) { Write-Host $Value -ForegroundColor Yellow }
		if($Severity -eq 3) { Write-Host $Value -ForegroundColor Red }
		
        try {
            Add-Content -Value $LogText -Force -LiteralPath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Warning: Unable to append log entry to file."
        }

        # Truncate log for last 2000 lines
        (Get-Content $LogFilePath | Select -Last 2000) | Set-Content $LogFilePath
		
		Update-StatusRecord -Component $Component -LogText $Value -Severity $Severity
    }
	
	Function Invoke-Executable {
    #-----------------------------------
    # Execute command-line tool
    #-----------------------------------
        param(
            [parameter(Mandatory=$true, HelpMessage="Specify the name of the executable to be invoked including the extension")]
            [ValidateNotNullOrEmpty()]
            [string]$Name,
 
            [parameter(Mandatory=$false, HelpMessage="Specify arguments that will be passed to the executable")]
            [ValidateNotNull()]
            [string]$Arguments
        )
 
        if ([System.String]::IsNullOrEmpty($Arguments)) {
            try {
                $ReturnValue = Start-Process -FilePath $Name -NoNewWindow -Passthru -Wait -ErrorAction Stop
            }
            catch [System.Exception] {
                Write-Warning -Message $_.Exception.Message ; break
            }
        }
        else {
            try {
				Write-Host "Invoking $Name with arguments: $Arguments"
                $ReturnValue = Start-Process -FilePath $Name -ArgumentList $Arguments -NoNewWindow -Passthru -Wait -ErrorAction Stop
            }
            catch [System.Exception] {
                Write-Warning -Message $_.Exception.Message ; break
            }
        }
 
        # Return exit code from executable
        return $ReturnValue.ExitCode
    }
		
	Function Get-LocalAccount {
    #-----------------------------------
    # Translate computername to local account
    #-----------------------------------
		Param ( 
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
			[string]$AccountName 
		)
		if( $AccountName.Split('\')[0] -eq $ENV:COMPUTERNAME ) { 'True' } else { 'False' }
	}

	Function Collect-LocalAdmins {	
    #-----------------------------------
    # Retrieve members of local admin group
    #-----------------------------------
		[Cmdletbinding()] 
		Param ( 
  			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
  			[string]$SQLConn
  		)				
				
		Process {
			$LogComponent = 'Collect-LocalAdmins'
			$LocalComputerName = $Env:COMPUTERNAME
			Try {
				$Query = "Exec [VNB_MLA].[dbo].[sp_VNB_LOCALADMINS_REMOVE_SYSTEM] '$LocalComputerName'"
				$Results = Invoke-SQLQuery -query $Query -conn $Global:UDLConnection
			}
			Catch {				
				Write-Host "ERROR: An error occurred while logging status update to the SQL server." -ForegroundColor Red
			}
			Write-LogEntry "Collecting members from local group Administrators." -Severity 1 -Component $LogComponent
			$group = get-wmiobject win32_group -ComputerName $LocalComputerName -Filter "LocalAccount=True AND SID='S-1-5-32-544'"
  			$query = "GroupComponent = `"Win32_Group.Domain='$($group.domain)'`,Name='$($group.name)'`""
  			$list = Get-WmiObject win32_groupuser -ComputerName $LocalComputerName -Filter $query
  			$Admins = $list.PartComponent | % {$_.substring($_.lastindexof("Domain=") + 7).replace("`",Name=`"","\").Replace("`"","") }
    			
			$domname = $ENV:USERDOMAIN
			Foreach ($Admin in $Admins) {  
				$MDomain = (($Admin.Split('\'))[0])
				$MName = (($Admin.Split('\'))[1])
				$LocalAcc = Get-LocalAccount $Admin
				$Query = "Exec [VNB_MLA].[dbo].[sp_VNB_LOCALADMINS_INSERT_GROUPMEMBER] '$LocalComputerName','$domname','$LocalComputerName','Administrators','$MDomain','$MName','$Admin','$LocalAcc'"
				$Results = Invoke-SQLQuery -query $Query -conn $Global:UDLConnection
			}
  		}		
	}
	
	Function Add-LocalGroupMember {
    #-----------------------------------
    # Add member to local group
    #-----------------------------------
		[Cmdletbinding()] 
		Param (
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)] 
			[ValidateNotNullOrEmpty()]
  			$Action
		)
		Begin {
			$LogComponent = 'Add-LocalGroupMember'
			$Member = "$($Action.MemberDomain)\$($Action.MemberName)"
			$LocalGroup = "$Env:computername\$($Action.GroupName)"
			Write-LogEntry "Adding member $Member to local group $LocalGroup" -Severity 1 -Component $LogComponent			
		}
		Process {
			$MemberExists = Exist-MemberLocalGroup -Groupname $($Action.GroupName) -UserName $Member
			if(!$MemberExists) {
				Write-Host "Adding member to group."
				Try {
					$group = [ADSI]"WinNT://$Env:computername/$($Action.GroupName),group"
					$group.Add("WinNT://$($Action.MemberDomain)/$($Action.MemberName)")
				}
				Catch {					
					$ErrorMessage = $_.Exception.Message
    				$FailedItem = $_.Exception.ItemName
					Write-LogEntry "ERROR: Item:[$FailedItem] Message:$ErrorMessage" -Severity 3 -Component $LogComponent
				}
			
				# Check if account is a member of the local group
				$MemberExists = Exist-MemberLocalGroup -Groupname $($Action.GroupName) -UserName $Member
				
				if($MemberExists) { Write-LogEntry "$Member was successfully added to the group $LocalGroup" -Severity 1  -Component $LogComponent } 
				else { Write-LogEntry "ERROR: Adding $Member to the group $LocalGroup ended in error." -Severity 3 -Component $LogComponent}
			} else {
				Write-LogEntry "Warning: Account $($Member) is already a member of group $($Action.GroupName)" -Severity 2 -Component $LogComponent
			}
			
			return $MemberExists
		}
	}
	
	Function Remove-LocalGroupMember {
    #-----------------------------------
    # Remove member from local group
    #-----------------------------------
		[Cmdletbinding()] 
		Param (
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)] 
			[ValidateNotNullOrEmpty()]
  			$Action
		)
		Begin {
			$LogComponent = 'Remove-LocalGroupMember'
			$Member = $Action.MemberName
			$LocalGroup = "$Env:computername\$($Action.GroupName)"
			Write-LogEntry "Removing member $Member from the group $LocalGroup" -Severity 1 -Component $LogComponent
		}
		Process {
			$MemberExists = Exist-MemberLocalGroup -Groupname $($Action.GroupName) -UserName $Action.MemberName
			if($MemberExists) {
				Try {
					Write-Host "Removing member from group."
					$group = [ADSI]"WinNT://$Env:computername/$($Action.GroupName),group"
					$group.Remove("WinNT://$($Action.MemberDomain)/$($Action.MemberName)")
				}
				Catch {
					$ErrorMessage = $_.Exception.Message
    				$FailedItem = $_.Exception.ItemName
					Write-LogEntry "ERROR: Item:[$FailedItem] Message:$ErrorMessage" -Severity 3 -Component $LogComponent
				}
				$MemberExists = Exist-MemberLocalGroup -Groupname $($Action.GroupName) -UserName $Member
				
				if(!$MemberExists) { Write-LogEntry "The member $Member was successfully removed from the group $LocalGroup" -Severity 1 -Component $LogComponent }
				else { Write-LogEntry "ERROR: Removing the member $Member from the group $LocalGroup ended in error." -Severity 3  -Component $LogComponent }
			} else {
				Write-LogEntry "Warning: Account $($Member) is not a member of local group $($Action.GroupName)" -Severity 2 -Component $LogComponent
			}
			return $MemberExists
		}
	}
	
	Function Approve-Computer {
    #-----------------------------------
    # Register computer name in SQL 
    #-----------------------------------
		[Cmdletbinding()] 
		Param (
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
  			[string]$SQLConn
		)
		Process {			
			$LogComponent = 'Approve-Computer'
			$Query = "exec [dbo].[sp_VNB_LOCALADMINS_APPROVECOMPUTER] '$Env:COMPUTERNAME', '$($Global:ScriptVersion)'"
			Try { 								
				$Results = Invoke-SQLQuery -query $Query -conn $SQLConn
				ForEach ($Row in $Results) {
					Write-LogEntry "Computer approval state: $($Row.ApprovalStatus)" -Severity 1 -Component $LogComponent
				}
			}
			Catch {
				$ErrorMessage = $_.Exception.Message
    			$FailedItem = $_.Exception.ItemName
				Write-LogEntry "ERROR: Item:[$FailedItem] Message:$ErrorMessage" -Severity 3 -Component $LogComponent				
			}
		}
	}
	
	Function Get-ComputerScheduleTime {
    #-----------------------------------
    # Register computer name in SQL 
    #-----------------------------------
		[Cmdletbinding()] 
		Param (
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
  			[string]$SQLConn
		)
		Process {			
			$LogComponent = 'Get-ComputerScheduleTime'
			$Query = "exec [dbo].[sp_VNB_LOCALADMINS_SCHEDULED_TIME] $Env:COMPUTERNAME"
			Try { 								
				$Results = Invoke-SQLQuery -query $Query -conn $SQLConn
				ForEach($Row in $Results) { $ScheduledTime = $Row.ScheduleTime }
				return $ScheduledTime
			}
			Catch {
				$ErrorMessage = $_.Exception.Message
    			$FailedItem = $_.Exception.ItemName
				Write-LogEntry "ERROR: Item:[$FailedItem] Message:$ErrorMessage" -Severity 3 -Component $LogComponent				
			}
		}
	}
	
	Function Update-LocalAdmins {
    #-----------------------------------
    # Retrieve changes to local groups
    #-----------------------------------
		[Cmdletbinding()] 
		Param ( 
  			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
  			[string]$SQLConn
  		)
		
		Begin {					
			$LogComponent = 'Update-LocalAdmins'			
			Approve-Computer $SQLConn 
			Collect-LocalAdmins -SQLConn $SQLConn
		}
		Process {			
			$LogComponent = 'Update-LocalAdmins'
			$ActionCount = 0
			Try { 
                # See if there are mutation records available for this computer if it is approved.
				$Query = "exec [VNB_MLA].[dbo].[sp_VNB_LOCALADMINS_REQ_COMPUTERAPPROVED] '$ENV:COMPUTERNAME'"			
				$Results = Invoke-SQLQuery -query $Query -conn $SQLConn
				if($Results) {
					Write-LogEntry "Update local administrator group." -Severity 1 -Component $LogComponent
				}
				ForEach($Action in $Results) {
					$ActionCount++
					$ToDo = $Action.Mut				
					switch ($ToDo) { 
        				'ADD' {
							$result = Add-LocalGroupMember -Action $Action							
						}
						'REMOVE' {
							$result = Remove-LocalGroupMember -Action $Action							
						}
						default {
							Write-LogEntry "ERROR: The mutation action [$ToDo] is not recognised." -Severity 3 -Component $LogComponent
						}
					}		
				}
				if($ActionCount -eq 0) {
					Write-LogEntry "No mutations are received." -Severity 1 -Component $LogComponent		
				} else {
					# Renew the database when mutations have been processed.
					Collect-LocalAdmins -SQLConn $UDLConnection
				}
			}
			Catch {
				$ErrorMessage = $_.Exception.Message
    			$FailedItem = $_.Exception.ItemName
				Write-LogEntry "ERROR: Item:[$FailedItem] Message:$ErrorMessage" -Severity 3 -Component $LogComponent				
			}
		}
		
		End {
		}		
	}
	
	Function Create-ScheduledTaskByXML {
    #-----------------------------------
    # Create scheduled task with XML 
    #-----------------------------------
		[Cmdletbinding()]
		param (
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
			[string]$Taskname,
			
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
			$Xml,
			
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[string]$Taskusername = 'SYSTEM', 
			
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[string]$Taskuserpassword = ''
		)	
		Process {
		}
		Begin {
			$LogComponent = 'Create-ScheduledTaskByXML'
			Try {
				$RegPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
    			$lsaval = Get-ItemProperty -Path $RegPath -Name "disabledomaincreds"
    			if($lsaval.disabledomaincreds -ne 0) {	    
					Write-Host "Disable LSA credentials."
	    			Set-ItemProperty -Path $RegPath -Name disabledomaincreds -Value 0 -ErrorAction SilentlyContinue		
    			}
				
				try {
					# Stop any running task
					$temp = schtasks.exe /End /TN $Taskname
				}
				catch {
				}
				
				try {
					# Delete the current task
					$temp = schtasks.exe /Delete /TN $Taskname /F
				}
				catch {
				}

				$result = schtasks.exe /Create /TN "$Taskname" /XML "$Xml" /RU "$Taskusername" /RP "$Taskuserpassword"				
				
				if($lsaval.disabledomaincreds -ne 0) {
					Write-Host "Resetting LSA credentials"
     				Set-ItemProperty -Path $RegPath -Name disabledomaincreds -Value $lsaval.disabledomaincreds -ErrorAction SilentlyContinue		
    			}
			}
			Catch {
				$ErrorMessage = $_.Exception.Message
    			$FailedItem = $_.Exception.ItemName
				Write-LogEntry "ERROR: Item:[$FailedItem] Message:$ErrorMessage" -Severity 3 -Component $LogComponent				
			}
		}
		End {
		}
	}

	Function Test-ScheduledTask {
    #-----------------------------------
    # Check if scheduled task exists
    #-----------------------------------
		[Cmdletbinding()]
		Param (			 
			[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
			[string]$Taskname,
			
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[string]$Taskfolder = $null
		)	
		Begin {
			$LogComponent = 'Test-ScheduledTask'
			# If no taskfolder was defined, use the root folder
			if($Taskfolder -eq $null) { $Taskfolder = '\' }
			Try {
				$sch = New-Object -ComObject("Schedule.Service")
				$sch.connect($Env:COMPUTERNAME)
				$tasks = $sch.getfolder($Taskfolder).gettasks(0)
			}
			Catch {
				$ErrorMessage = $_.Exception.Message
    			$FailedItem = $_.Exception.ItemName
				Write-LogEntry "ERROR: Item:[$FailedItem] Message:$ErrorMessage" -Severity 3 -Component $LogComponent
			}
		}
		Process {
			foreach ($task in $tasks) {
				if($task.Name -match $taskname) { return $true }
			}
			return $false
		}
		End {
		}
	}	
	
	Function Set-TaskACL {
    #-----------------------------------
    # Apply ACL to scheduled task
    #-----------------------------------
		[Cmdletbinding()] 
		Param ( 
  			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)] 
			[ValidateNotNullOrEmpty()]
  			[string]$TaskSysName,
			
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
  			[string]$SQLConn
  		)
		
		Process {						
			$LogComponent = 'Set-TaskACL'
			$Icacls = 'icacls.exe'
			Write-Host "Securing ACL on $TaskSysName"
			Write-LogEntry "Securing ACL on $TaskSysName" -Severity 1 -Component $LogComponent
			Try {
				$result = Invoke-Executable -Name $Icacls -Arguments ($TaskSysName + ' /grant "NEDCAR\Domain Admins":F')
				$result = Invoke-Executable -Name $Icacls -Arguments ($TaskSysName + ' /grant "NT AUTHORITY\SYSTEM":F')
				$result = Invoke-Executable -Name $Icacls -Arguments ($TaskSysName + ' /remove "BUILTIN\Administrators"')
				$result = Invoke-Executable -Name $Icacls -Arguments ($TaskSysName + ' /inheritance:r')
				$result = Invoke-Executable -Name $Icacls -Arguments ($TaskSysName + ' /grant "NT AUTHORITY\LOCALSERVICE":R')
				$result = Invoke-Executable -Name $Icacls -Arguments ($TaskSysName + ' /grant "NT AUTHORITY\NETWORK SERVICE":R')
			}			
			Catch {
				$ErrorMessage = $_.Exception.Message
    			$FailedItem = $_.Exception.ItemName
				Write-LogEntry "ERROR: Item:[$FailedItem] Message:$ErrorMessage" -Severity 3 -Component $LogComponent
			}
		}
	}	
	
	Function Test-ScheduleToSQL {
	#-----------------------------------
    # Check if used schedule is still equal to the SQL schedule.
	# Returns true is SQL value and XML value are equal, false if they are not equal, false if the XML cannot be found.
    #-----------------------------------
		[Cmdletbinding()] 
		Param ( 
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
  			[string]$StartTime,
			
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
  			[string]$SavedTaskXMLPath
		)
		
		Begin {	
			$LogComponent = 'Check-Schedule'			
		}		
		Process {
			# Check value in saved schedule.xml file, if the file does not exist the return value is always false
			if(Test-Path $SavedTaskXMLPath) {
				# Read value StartBoundary
				$StartBoundary = Get-Content $SavedTaskXMLPath | ? { $_ -match 'StartBoundary' }
				$StartBoundary = ($StartBoundary.Trim())
				$StartBoundary = $StartBoundary.SubString(0, $StartBoundary.Length - ('</StartBoundary>').Length)
				$StartBoundary = $StartBoundary.SubString($StartBoundary.Length - 8)			
				$result = ($StartBoundary.CompareTo($StartTime) -eq 0)
			} else {
				$result = $false
			}
			return $result
		}		
		End {
		}
	}
	
	Function Install-Script {
    #-----------------------------------
    # Install script and scheduled task
    #-----------------------------------
		[Cmdletbinding()] 
		Param ( 
  			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)] 
			[ValidateNotNullOrEmpty()]
  			[string]$ScriptSourcePath,
			
			[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
			[ValidateNotNullOrEmpty()]
  			[string]$SQLConn
  		)
		
		Begin {	
			$LogComponent = 'Install-Script'
			# Locate the script next to where the log is created
			$SourceScriptPath = $ScriptSourcePath
			$DestinationScriptPath = Join-Path -Path $Global:ScriptLogPath -ChildPath $Global:ScriptName
			
			# Locate the UDL file next to where the log is created
			$UDLName = Split-Path $Global:UDLFilename -Leaf
			$SourceUDLFilePath = (Split-Path $ScriptSourcePath -Parent) + '\' + $UDLName
			$DestinationUDLPath = Join-Path -Path $Global:ScriptLogPath -ChildPath $UDLName			
			
			# Locate the XML Scheduled task definition file next to where the log is created
			$XMLName = 'VNB-Manage-LocalAdmins.xml'
			$SourceXMLFilePath = (Split-Path $ScriptSourcePath -Parent) + '\' + $XMLName
			$DestinationXMLPath = Join-Path -Path $Global:ScriptLogPath -ChildPath $XMLName
			
			# Accept command line switch to indicate forced installation.
			$ForcedReInstall = $Install
			if($Install) { Write-LogEntry "The script is forcefully (re)installed." -Severity 1 -Component $LogComponent }
		}
		
		Process {
		
			# Force the re-install if parts of the script are not found
			if(!$ForcedReInstall) { $ForcedReInstall = !(Test-Path $DestinationScriptPath  ) } 
			if(!$ForcedReInstall) { $ForcedReInstall = !(Test-Path $DestinationUDLPath ) } 
			if(!$ForcedReInstall) { $ForcedReInstall = !(Test-Path $DestinationXMLPath ) } 						
		
			# Check and remediate the script where it should be.
			if($ScriptSourcePath -ne $DestinationScriptPath) {
				Write-LogEntry "The script is executed from a different location than its designated location." -Severity 1 -Component $LogComponent 
				$ForcedReInstall = $true
			}
						
			if($ForcedReInstall) { 				
				Write-LogEntry "A renewal of the script sources and scheduled task is forced." -Severity 1 -Component $LogComponent 				
			}
			
			$CopyFiles = $False
			# If no forced renewal is needed, are source and destination the same CRC?
			if(!$ForcedReInstall -and ($ScriptSourcePath -ne $DestinationScriptPath)) {
				if(Test-Path $DestinationScriptPath) {
					if($VerboseLogging) {
						Write-LogEntry "The script is already found at its designated location." -Severity 1 -Component $LogComponent 						
					}
					$SourceCRC = Get-CRC32 $ScriptSourcePath
					$DestCRC = Get-CRC32 $DestinationScriptPath
					if($SourceCRC -eq $DestCRC) {
						if($VerboseLogging) {
							Write-LogEntry "The scripts are identical. No need to update the designated script location." -Severity 1 -Component $LogComponent 
						}
					} else {
						if($VerboseLogging) {
							Write-LogEntry "Source: $SourceCRC" -Severity 1 -Component $LogComponent 
							Write-LogEntry "Destination: $DestCRC" -Severity 1 -Component $LogComponent 
							Write-LogEntry "The scripts are not identical." -Severity 1 -Component $LogComponent 
						}
						$CopyFiles = $True
					}
				} else {
					Write-LogEntry "The script is not found at its designated location." -Severity 1 -Component $LogComponent 
					$CopyFiles = $True
				}
			}
			
			if($CopyFiles -or $ForcedReInstall) {
				if($ScriptSourcePath -ne $DestinationScriptPath) {
					Write-LogEntry "Installing the script." -Severity 1	-Component $LogComponent 
					# No need to create the folder structure as the log creation has handled that already
					Try {					
						Copy-Item $SourceScriptPath $DestinationScriptPath -Force
						Copy-Item $SourceUDLFilePath $DestinationUDLPath -Force
						Copy-Item $SourceXMLFilePath $DestinationXMLPath -Force
						Write-LogEntry "The script at its designated location was renewed." -Severity 1 -Component $LogComponent 
					}
					Catch {
						$ErrorMessage = $_.Exception.Message
    					$FailedItem = $_.Exception.ItemName
						Write-LogEntry "ERROR: Item:[$FailedItem] Message:$ErrorMessage" -Severity 3 -Component $LogComponent
					}
				}		
				
				# Secure ACL of script location
				$Icacls = 'icacls.exe'
				$ACLPath = """$Global:ScriptLogPath"""				
				$result = Invoke-Executable -Name $Icacls -Arguments ($ACLPath + ' /grant "NEDCAR\Domain Admins":F /T /Q')
				$result = Invoke-Executable -Name $Icacls -Arguments ($ACLPath + ' /grant "NT AUTHORITY\SYSTEM":F /T /Q')						
				$result = Invoke-Executable -Name $Icacls -Arguments ($ACLPath + ' /grant "NT AUTHORITY\LOCALSERVICE":R /T /Q')
				$result = Invoke-Executable -Name $Icacls -Arguments ($ACLPath + ' /grant "NT AUTHORITY\NETWORK SERVICE":R /T /Q')
				$result = Invoke-Executable -Name $Icacls -Arguments ($ACLPath + ' /inheritance:r /Q')
			}
			
			# Check and remediate the scheduled task			
			$TaskName = 'VNB-Manage-LocalAdmins'
			$TaskFolderPath = '\Microsoft\Windows'			
			$TaskXMLPath = $DestinationXMLPath
			
			$TaskXMLNewPath = Join-Path -Path $Global:ScriptPath -ChildPath 'schedule.xml'
			
			# Cannot reuse the folder name because of slashes
			$NewTaskname = 'Microsoft\Windows\' + $TaskName
			
			#----------------------------------------------------------------------
			# The script should execute every 2 hours but not all at the same time
			# We alter the resulting schedule.xml file with a start time choosen by SQL.
			# The source XML file must have a default start time of 00:00:00
			#----------------------------------------------------------------------				
								
			# Retrieve scheduled time from SQL 
			$StartTime = (Get-ComputerScheduleTime -SQLConn $SQLConn)			
			
			# validate a reinstall, check if the saved schedule is the same to SQL
			If (!$ForcedReInstall) { 
				If (Test-ScheduleToSQL -StartTime $StartTime -SavedTaskXMLPath $TaskXMLNewPath) {
					if($VerboseLogging) {
						Write-LogEntry "The saved scheduled time was equal to the SQL schedule." -Severity 1 -Component $LogComponent 
					}				
				} else {
					Write-LogEntry "The saved scheduled time and the SQL schedule time are different." -Severity 1 -Component $LogComponent 
					$ForcedReInstall = $true
				}
			}
				
			# validate a reinstall, does the schedule exist?
			If (!$ForcedReInstall) { 
				If (Test-ScheduledTask -Taskname $TaskName -Taskfolder $TaskFolderPath) {
					if($VerboseLogging) {
						Write-LogEntry "The scheduled task was found." -Severity 1 -Component $LogComponent 
					}				
				} else {
					Write-LogEntry "The scheduled task was not found." -Severity 1 -Component $LogComponent 
					$ForcedReInstall = $true
				}			
			}
			
			# Install the scheduled task when needed.
			If($ForcedReInstall) {
				Write-LogEntry "Installing the scheduled task." -Severity 1	-Component $LogComponent 
				Set-ItemProperty -Path $Global:ScriptRegPath -Name ScriptScheduleTaskXML -Value $TaskXMLNewPath -ErrorAction SilentlyContinue								

				# Replace the default time 00:00:00 with the start time
				(Get-Content $TaskXMLPath).replace('00:00:00', $StartTime) | Set-Content $TaskXMLNewPath
				
				Write-LogEntry "$StartTime" -Severity 1 -Component 'ScheduledTaskStartTime'
				Set-ItemProperty -Path $Global:ScriptRegPath -Name TaskStartTime -Value $StartTime -ErrorAction SilentlyContinue
				
				# Create task with XML definition
				Create-ScheduledTaskByXML -Taskname $NewTaskname -Xml $TaskXMLNewPath
				If (Test-ScheduledTask -Taskname $TaskName -Taskfolder $TaskFolderPath) {
					if($VerboseLogging) {
						Write-LogEntry "The scheduled task was successfully created." -Severity 1 -Component $LogComponent 
					}
					$TaskSysFolder = Join-Path -Path $Env:SystemRoot -ChildPath 'System32\Tasks'
					$TaskSysFolder = Join-Path -Path $TaskSysFolder -ChildPath $TaskFolderPath
					$TaskSysName = Join-Path -Path $TaskSysFolder -ChildPath $TaskName			
			
					Set-TaskACL -TaskSysname $TaskSysName -SQLConn $SQLConn
				} else {
					Write-LogEntry "ERROR: The scheduled task was not successfully created." -Severity 3 -Component $LogComponent 
				}
			}
		}		
	}

    #-----------------------------------
    # Start of script
    #-----------------------------------
	
	$ScriptSourceFilePath = Join-Path -Path $Global:ScriptPath -ChildPath $Global:ScriptName
	$ScriptIdentity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
	
	Set-ItemProperty -Path $Global:ScriptRegPath -Name ScriptCurrent -Value $ScriptSourceFilePath -ErrorAction SilentlyContinue
	Set-ItemProperty -Path $Global:ScriptRegPath -Name ScriptIdentity -Value $ScriptIdentity -ErrorAction SilentlyContinue

    Write-LogEntry "The script has started." -Severity 1 -Component 'Start-Script'
    Write-Host "Start script using $ScriptSourceFilePath by $ScriptIdentity"
    if($Verbose) { Write-LogEntry "Start script using $ScriptSourceFilePath by $Identity" -Severity 1 -Component 'Start-Script' }	
    Install-Script -ScriptSourcePath $ScriptSourceFilePath -SQLConn $Global:UDLConnection	

    if($Verbose) { Write-LogEntry "Update the local administrator group." -Severity 1 -Component 'Start-Script'}
    Update-LocalAdmins -SQLConn $Global:UDLConnection	

    #-----------------------------------
    # Done.
    #-----------------------------------
	
	Write-LogEntry "The script has ended." -Severity 1 -Component 'End-Script'
	Set-ItemProperty -Path $Global:ScriptRegPath -Name LastRunEndTime -Value (get-date -Format "yyyy-MM-dd HH:mm:ss") -ErrorAction SilentlyContinue
}