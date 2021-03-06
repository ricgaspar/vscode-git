# =========================================================
#
# Marcel Jussen
# 24-4-2015
#
# =========================================================
#-requires 3.0

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

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

Function Save_Collection_Info {
	param (
		[string]$ObjectName,
		[string]$NameMatch,
		[bool]$Erase
	)
	
	$Computername = $env:COMPUTERNAME
	$SiteServerName = 's007'
	$SiteCode = Get-SCCM-SiteCode -SiteServer $siteServerName
	
	Echo-Log "Gathering data from collections matching $NameMatch"
	
	$ObjectData = Get-WmiObject SMS_Collection -Namespace "root\SMS\site_$SiteCode" -ComputerName $SiteServerName | `
		Where-Object {$_.name -Match $NameMatch} | `
		select CollectionID, Name, CurrentStatus, Comment, LastRefreshTime, LocalMemberCount

	if($ObjectData) {								
		$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
		Echo-Log "Send data to database."
		Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase		 		
	} else {
		Echo-Log "No data found."
	}
}

#=============================================================================
# Convert powershell Object to Array for Excel
#=============================================================================
function ConvertTo-MultiArray {
 <#
    .Notes
        NAME: ConvertTo-MultiArray
        AUTHOR: Tome Tanasovski
        Website: http://powertoe.wordpress.com
        Twitter: http://twitter.com/toenuff
        Version: 1.2
    .Synopsis
        Converts a collection of PowerShell objects into a multi-dimensional array

    .Description
        Converts a collection of PowerShell objects into a multi-dimensional array.  The first row of the array contains the property names.  Each additional row contains the values for each object.

        This cmdlet was created to act as an intermediary to importing PowerShell objects into a range of cells in Exchange.  By using a multi-dimensional array you can greatly speed up the process of adding data to Excel through the Excel COM objects.

    .Parameter InputObject
        Specifies the objects to export into the multi dimensional array.  Enter a variable that contains the objects or type a command or expression that gets the objects. You can also pipe objects to ConvertTo-MultiArray.

    .Inputs
        System.Management.Automation.PSObject
        You can pipe any .NET Framework object to ConvertTo-MultiArray

    .Outputs
        [ref]
        The cmdlet will return a reference to the multi-dimensional array.  To access the array itself you will need to use the Value property of the reference

    .Example
        $arrayref = get-process |Convertto-MultiArray

    .Example
        $dir = Get-ChildItem c:\
        $arrayref = Convertto-MultiArray -InputObject $dir

    .Example
        $range.value2 = (ConvertTo-MultiArray (get-process)).value

    .LINK
        http://powertoe.wordpress.com

#>
    param(
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        [PSObject[]]$InputObject
    )
    BEGIN {
        $objects = @()
        [ref]$array = [ref]$null
    }
    Process {
        $objects += $InputObject
    }
    END {
        $properties = $objects[0].psobject.properties |%{$_.name}
        $array.Value = New-Object 'object[,]' ($objects.Count+1),$properties.count
        # i = row and j = column
        $j = 0
        $properties |%{
            $array.Value[0,$j] = $_.tostring()
            $j++
        }
        $i = 1
        $objects |% {
            $item = $_
            $j = 0
            $properties | % {
                if ($item.($_) -eq $null) {
                    $array.value[$i,$j] = ""
                }
                else {
                    $array.value[$i,$j] = $item.($_).tostring()
                }
                $j++
            }
            $i++
        }
        $array
    }
}

#=============================================================================
# Export pipe in Excel file
#=============================================================================
function Export-Excel {
	[cmdletBinding()]
    Param(
		[Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        [PSObject[]]$InputObject
	)
	
	begin {
            $header=$null
            $row=1
            $xl=New-Object -ComObject Excel.Application
            $wb=$xl.WorkBooks.add(1)
            $ws=$wb.WorkSheets.item(1)
			
			#Connect to first worksheet to rename and make active
			$serverInfoSheet = $ws
			$serverInfoSheet.Name = 'Collection_Data'
			# $serverInfoSheet.Activate() | Out-Null
            $xl.Visible=$false
            $xl.DisplayAlerts = $false
            $xl.ScreenUpdating = $False
            $objects = @()

            }
	process {
		$objects += $InputObject
	}
	
	end {
            $array4XL = ($objects | ConvertTo-MultiArray).value

            $starta = [int][char]'a' - 1
            if ($array4XL.GetLength(1) -gt 26) {
                $col = [char]([int][math]::Floor($array4XL.GetLength(1)/26) + $starta) + [char](($array4XL.GetLength(1)%26) + $Starta)
            } else {
                $col = [char]($array4XL.GetLength(1) + $starta)
            }
            $ws.Range("a1","$col$($array4XL.GetLength(0))").value2=$array4XL	

            $wb.SaveAs("D:\Windows7-Ent2Prof-Rapport.xlsx")
            $xl.Quit()
            Remove-Variable xl
	}
}

# ---------------------------------------------------------
# Start script
cls
$ScriptName = $myInvocation.MyCommand.Name
$ScriptPath = split-path -parent $myInvocation.MyCommand.Path

$GlobLog = Init-Log $ScriptName
Echo-Log ("="*60)
Echo-Log "Started script: $ScriptName"

$Computername = $env:COMPUTERNAME
$Erase = $false

$UDLFile = $glb_UDL
if((Test-Path $UDLFile)) {
	$UDLConnection = Read-UDLConnectionString $UDLFile
	
	Save_Collection_Info -Objectname 'SCCM_OS_BASE_ALL_VDLNC' -NameMatch "Base - All VDL Nedcar" -Erase $Erase
	Save_Collection_Info -Objectname 'SCCM_OS_BASE_FACTORY' -NameMatch "Base - Factory" -Erase $Erase
	Save_Collection_Info -Objectname 'SCCM_OS_BASE_OFFICE' -NameMatch "Base - Nedcar Office" -Erase $Erase
	Save_Collection_Info -Objectname 'SCCM_OS_WINDOWS7' -NameMatch "OS - Windows 7" -Erase $Erase		

	$connection = New-UDLSQLconnection $UDLConnection
	$query = "select name, convert(varchar, Date, 105) as Date, LocalMemberCount from vw_SCCM_Win7Ent2Pro_Rapportage"
	$table = Invoke-SQLQuery -query $query -conn $connection
	
	Export-Excel $table	
}

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)