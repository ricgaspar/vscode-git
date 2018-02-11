# ---------------------------------------------------------
# Marcel Jussen
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ---------------------------------------------------------
Import-Module VNB_PSLib -Force -ErrorAction Stop
# ---------------------------------------------------------

# ---------------------------------------------------------
Function Insert-Record {
	param (
		[ValidateNotNullOrEmpty()]
		[string]$Computername,
		[ValidateNotNullOrEmpty()]
		[string]$ObjectName,
		[ValidateNotNullOrEmpty()]
		$ObjectData,
		[ValidateNotNullOrEmpty()]
		[bool]$Erase

	)
	if($ObjectData) {
		# Create the table if needed
		$new = New-VNBObjectTable -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
		if($new) { Echo-Log "Table $ObjectName was created." }

		# Append record to table
		# $RecCount = $($ObjectData.count)
		# Echo-Log "Update table $ObjectName with $RecCount records."
		Send-VNBObject -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
	}
}

# ---------------------------------------------------------
Function Export-ScheduledTasks {
    # ---------------------------------------------------------
    #
    # ---------------------------------------------------------
    [cmdletbinding()]
    param(
        [Parameter(Position = 0, ValuefromPipeline = $true)]
        [string]
        $ComputerName = $Env:COMPUTERNAME
    )

    process {
        $TempCSV = $null
        $TempReport = $Env:TEMP + "\temp.csv"
        try {
            schtasks /QUERY /S $ComputerName /FO CSV /V > $TempReport
            $TempCsv = Import-Csv $TempReport
            Remove-Item $TempReport
        }
        catch {
            Write-Host "Error retrieving scheduled tasks from $Computername"
        }
        return $TempCSV
    }
}

# ---------------------------------------------------------
Function Export-Tasks {
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Computername = $env:COMPUTERNAME
    )
    Echo-Log "Collecting task scheduler info on $Computername"
    # Define erase of previous records of this computer
    $Erase = $True

    # Define name of SQL table
    $ObjectName = 'VNB_SYSINFO_TASKSCHEDULER'
    # Collect object data
    $ObjectData = Export-ScheduledTasks $Computername
    if ($ObjectData) {
        Insert-Record -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
    }
}

Function Get-Inventory {
	param (
		[Parameter(Mandatory=$false, ValueFromPipeline=$true, Position=0)]
		[string]$Computername = $env:COMPUTERNAME
	)

    Export-Tasks $Computername
}

Clear-Host

$Sysinfolog = "$env:SYSTEMDRIVE\Logboek\Secdump-SysInfo.log"
$Global:glb_EVENTLOGFile = $Sysinfolog
[void](Init-Log -LogFileName $Sysinfolog $False -alternate_location $True)
Echo-Log ("=" * 80)
Echo-Log "Start of script on computer $($env:COMPUTERNAME)"

# Create MSSQL connection
$Global:UDLConnection = Read-UDLConnectionString $glb_UDL

# Start inventory
$Coms = @('S050', 'S051', 'VS032', 'VS055', 'VS060', 'VS136', 'VS137', 'VS033', 'VS043', 'VS048', 'VS134')

ForEach($Computer in $Coms) {
    Get-Inventory -Computername $Computer
}

Echo-Log "End of script on computer $($env:COMPUTERNAME)"
Echo-Log ("=" * 80)
# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================