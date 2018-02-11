# =========================================================
# Marcel Jussen
# 12-12-2017
#
# =========================================================
#Requires -version 4.0

# ---------------------------------------------------------
# Reload required modules
Import-Module VNB_PSLib -Force -ErrorAction Stop
Import-Module ExcelPSLib -Force -ErrorAction Stop

# ---------------------------------------------------------
# Ensures you only refer to variables that exist (great for typos) and
# enforces some other best-practice� coding rules.
Set-StrictMode -Version Latest

# ---------------------------------------------------------
# enforces all errors to become terminating unless you override with
# per-command -ErrorAction parameters or wrap in a try-catch block
$script:ErrorActionPreference = "Stop"

Function Get-GroupsPerShareReport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ExcelFilePath,

        [Parameter(Mandatory = $true)]
        [string]$DFSShare,

        [Parameter(Mandatory = $true)]
        [string]$SQLConnection
    )
    if (test-path($ExcelFilePath)) {
        Remove-Item -Path $ExcelFilePath -Force -ErrorAction Stop
    }
    $SQLError = $false

    Echo-Log "Creating Excel workbook: $ExcelFilePath"
    [OfficeOpenXml.ExcelPackage]$excel = New-OOXMLPackage -author "Marcel Jussen" -title "Domain group access to DFS share."
    [OfficeOpenXml.ExcelWorkbook]$book = $excel | Get-OOXMLWorkbook
    $excel | Add-OOXMLWorksheet -WorkSheetName 'Share'
    $sheet = $book | Select-OOXMLWorkSheet -WorkSheetNumber 1

    Echo-Log "Creating header."
    $StyleHeader = New-OOXMLStyleSheet -WorkBook $book -Name "HeaderStyle" -Bold -ForeGroundColor White -BackGroundColor Black -Size 14 -FillType Solid
    $CurDate = Get-Date -Format "dd-MM-yyyy"
    $sheet | Set-OOXMLRangeValue -row 1 -col 1 -value "DFS Sharename:" -StyleSheet $StyleHeader | Out-Null
    $sheet | Set-OOXMLRangeValue -row 1 -col 2 -value "$DFSShare" -StyleSheet $StyleHeader | Out-Null
    $sheet | Set-OOXMLRangeValue -row 2 -col 1 -value "Document created on:" | Out-Null
    $sheet | Set-OOXMLRangeValue -row 2 -col 2 -value "$CurDate" | Out-Null

    Echo-Log "Enumerating share owners."
    $intRow = 4
    $sheet | Set-OOXMLRangeValue -row $intRow -col 1 -value "Share owners:" | Out-Null
    Try {
        $query = "select distinct * from vw_VNB_P_DOMAIN_DFS_OWNERS where DFSShare = '$DFSShare'"
        $data = Query-SQL $query $SQLconn

        $data | Foreach-Object {
            $DFSShareOwner01 = $($_.DFSShareOwner01)
            $DFSShareOwner02 = $($_.DFSShareOwner02)
            $sheet | Set-OOXMLRangeValue -row $intRow -col 2 -value "$DFSShareOwner01" | Out-Null
            $intRow++
            $sheet | Set-OOXMLRangeValue -row $intRow -col 2 -value "$DFSShareOwner02" | Out-Null
            $intRow++
        }
        $intRow++
    }
    Catch {
        $data = $null
        $SQLError = $true
        Echo-Log "ERROR: A SQL error occured. No results could be retrieved."
        Echo-Log $query
    }

    # Create the table with group information
    Echo-Log "Enumerating group access list."
    $StyleTableTop = New-OOXMLStyleSheet -WorkBook $book -Name "TableTopStyle" -Bold -ForeGroundColor White -BackGroundColor LightBlue -Size 12 -FillType Solid
    $sheet | Set-OOXMLRangeValue -row $intRow -col 1 -value "DFS Sharename" -StyleSheet $StyleTableTop | Out-Null
    $sheet | Set-OOXMLRangeValue -row $intRow -col 2 -value "Security Principal Name" -StyleSheet $StyleTableTop | Out-Null
    $intRow++

    try {
        $query = "select distinct DFSShareTargetName, SecurityPrincipal from vw_VNB_P_DOMAIN_DFS_GROUPS_PER_SHARE where DFSShare = '$DFSShare'"
        $data = Query-SQL $query $SQLconn

        $data | Foreach-Object {
            $DFSShareTargetName = $($_.DFSShareTargetName)
            $SecurityPrincipal = $($_.SecurityPrincipal)
            $sheet | Set-OOXMLRangeValue -row $intRow -col 1 -value "$DFSShareTargetName" | Out-Null
            $sheet | Set-OOXMLRangeValue -row $intRow -col 2 -value "$SecurityPrincipal" | Out-Null
            $intRow++
        }
    }
    Catch {
        $data = $null
        $SQLError = $true
        Echo-Log "ERROR: A SQL error occured. No results could be retrieved."
        Echo-Log $query
    }

    Echo-Log "Save excel workbook to $ExcelFilePath"
    if ($SQLError -eq $False) {
        $excel | Save-OOXMLPackage -FileFullPath $ExcelFilePath -Dispose
    }
    else {
        Echo-Log "ERROR: The Excel workbook was not saved due to a SQL error."
    }
}
Function Get-UsersPerShareReport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ExcelFilePath,

        [Parameter(Mandatory = $true)]
        [string]$DFSShare,

        [Parameter(Mandatory = $true)]
        [string]$SQLConnection
    )
    if (test-path($ExcelFilePath)) {
        Remove-Item -Path $ExcelFilePath -Force -ErrorAction Stop
    }
    $SQLError = $false

    Echo-Log "Creating Excel workbook: $ExcelFilePath"
    [OfficeOpenXml.ExcelPackage]$excel = New-OOXMLPackage -author "Marcel Jussen" -title "Domain users access to DFS share"
    [OfficeOpenXml.ExcelWorkbook]$book = $excel | Get-OOXMLWorkbook
    $excel | Add-OOXMLWorksheet -WorkSheetName 'Share'
    $sheet = $book | Select-OOXMLWorkSheet -WorkSheetNumber 1

    Echo-Log "Creating header."
    $StyleHeader = New-OOXMLStyleSheet -WorkBook $book -Name "HeaderStyle" -Bold -ForeGroundColor White -BackGroundColor Black -Size 14 -FillType Solid
    $CurDate = Get-Date -Format "dd-MM-yyyy"
    $sheet | Set-OOXMLRangeValue -row 1 -col 1 -value "DFS Sharename:" -StyleSheet $StyleHeader | Out-Null
    $sheet | Set-OOXMLRangeValue -row 1 -col 2 -value "$DFSShare" -StyleSheet $StyleHeader | Out-Null
    $sheet | Set-OOXMLRangeValue -row 2 -col 1 -value "Document created on:" | Out-Null
    $sheet | Set-OOXMLRangeValue -row 2 -col 2 -value "$CurDate" | Out-Null

    Echo-Log "Enumerating share owners."
    try {
        $query = "select distinct * from vw_VNB_P_DOMAIN_DFS_OWNERS where DFSShare = '$DFSShare'"
        $data = Query-SQL $query $SQLconn
        $intRow = 4
        $sheet | Set-OOXMLRangeValue -row $intRow -col 1 -value "Share owners:" | Out-Null
        $data | Foreach-Object {
            $DFSShareOwner01 = $($_.DFSShareOwner01)
            $DFSShareOwner02 = $($_.DFSShareOwner02)
            $sheet | Set-OOXMLRangeValue -row $intRow -col 2 -value "$DFSShareOwner01" | Out-Null
            $intRow++
            $sheet | Set-OOXMLRangeValue -row $intRow -col 2 -value "$DFSShareOwner02" | Out-Null
            $intRow++
        }
        $intRow++
    }
    Catch {
        $data = $null
        $SQLError = $true
        Echo-Log "ERROR: A SQL error occured. No results could be retrieved."
        Echo-Log $query
    }

    # Create the table with group information
    Echo-Log "Enumerating user access list."
    $StyleTableTop = New-OOXMLStyleSheet -WorkBook $book -Name "TableTopStyle" -Bold -ForeGroundColor White -BackGroundColor LightBlue -Size 12 -FillType Solid
    $sheet | Set-OOXMLRangeValue -row $intRow -col 1 -value "User ID" -StyleSheet $StyleTableTop | Out-Null
    $sheet | Set-OOXMLRangeValue -row $intRow -col 2 -value "User Name" -StyleSheet $StyleTableTop | Out-Null
    $sheet | Set-OOXMLRangeValue -row $intRow -col 3 -value "User Function" -StyleSheet $StyleTableTop | Out-Null
    $sheet | Set-OOXMLRangeValue -row $intRow -col 4 -value "Department Nr" -StyleSheet $StyleTableTop | Out-Null
    $sheet | Set-OOXMLRangeValue -row $intRow -col 5 -value "Department Name" -StyleSheet $StyleTableTop | Out-Null
    $sheet | Set-OOXMLRangeValue -row $intRow -col 6 -value "Department Manager" -StyleSheet $StyleTableTop | Out-Null
    $sheet | Set-OOXMLRangeValue -row $intRow -col 7 -value "Department VP" -StyleSheet $StyleTableTop | Out-Null

    $intRow++
    try {
        $query = "select distinct Membername, Displayname, ISP_Function, ISP_DEPARTMENT_NR, ISP_DEPARTMENT_NAME, ISP_MANAGER, ISP_VP_COMPOUND_NAME from vw_VNB_P_DOMAIN_DFS_USERS_PER_SHARE where DFSShare = '$DFSShare'"
        $data = Query-SQL $query $SQLconn

        $data | Foreach-Object {
            $Membername = $($_.Membername)
            $Displayname = $($_.Displayname)
            $ISP_Function = $($_.ISP_Function)
            $ISP_DEPARTMENT_NR = $($_.ISP_DEPARTMENT_NR)
            $ISP_DEPARTMENT_NAME = $($_.ISP_DEPARTMENT_NAME)
            $ISP_MANAGER = $($_.ISP_MANAGER)
            $ISP_VP_COMPOUND_NAME = $($_.ISP_VP_COMPOUND_NAME)

            $sheet | Set-OOXMLRangeValue -row $intRow -col 1 -value "$Membername" | Out-Null
            $sheet | Set-OOXMLRangeValue -row $intRow -col 2 -value "$Displayname" | Out-Null
            $sheet | Set-OOXMLRangeValue -row $intRow -col 3 -value "$ISP_Function" | Out-Null
            $sheet | Set-OOXMLRangeValue -row $intRow -col 4 -value "$ISP_DEPARTMENT_NR" | Out-Null
            $sheet | Set-OOXMLRangeValue -row $intRow -col 5 -value "$ISP_DEPARTMENT_NAME" | Out-Null
            $sheet | Set-OOXMLRangeValue -row $intRow -col 6 -value "$ISP_MANAGER" | Out-Null
            $sheet | Set-OOXMLRangeValue -row $intRow -col 7 -value "$ISP_VP_COMPOUND_NAME" | Out-Null
            $intRow++
        }
    }
    Catch {
        $data = $null
        $SQLError = $true
        Echo-Log "ERROR: A SQL error occured. No results could be retrieved."
        Echo-Log $query
    }

    Echo-Log "Save excel workbook to $ExcelFilePath"
    if ($SQLError -eq $False) {
        $excel | Save-OOXMLPackage -FileFullPath $ExcelFilePath -Dispose
    }
    else {
        Echo-Log "ERROR: The Excel workbook was not saved due to a SQL error."
    }
}

# ---------------------------------------------------------
Clear-Host

$Sysinfolog = "$env:SYSTEMDRIVE\Logboek\Get-ShareAccessReports.log"
$Global:glb_EVENTLOGFile = $Sysinfolog
[void](Init-Log -LogFileName $Sysinfolog $False -alternate_location $True)
Echo-Log ("=" * 80)
Echo-Log "Start of script on computer $($env:COMPUTERNAME)"

# Create MSSQL connection
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
Echo-Log "Current script directory: $($ScriptDir)"
$UDLFile = $ScriptDir + '\secdump-sharereports.udl'
$Global:UDLConnection = Read-UDLConnectionString $UDLFile

$SQLconn = New-UDLSQLconnection -UDLConnection $Global:UDLConnection
$query = "select dfs.DFSShare, dfs.DFSShareTargetServer, dfs.DFSShareTargetName, dfso.DFSShareOwner01, dfso.DFSShareOwner02 from vw_VNB_P_DOMAIN_DFS dfs left join vw_VNB_P_DOMAIN_DFS_OWNERS dfso on dfso.DFSShare = dfs.DFSShare order by DFSShareTargetServer,DFSShareTargetName"
# $query = "select dfs.DFSShare, dfs.DFSShareTargetServer, dfs.DFSShareTargetName, dfso.DFSShareOwner01, dfso.DFSShareOwner02 from vw_VNB_P_DOMAIN_DFS dfs left join vw_VNB_P_DOMAIN_DFS_OWNERS dfso on dfso.DFSShare = dfs.DFSShare where dfs.DFSShare='\\NEDCAR\Office\IM' order by DFSShareTargetServer,DFSShareTargetName"
$data = Query-SQL $query $SQLconn

ForEach ($rec in $data) {
    $DFSShare = $($rec.DFSShare)
    $DFSShareTargetName = $($rec.DFSShareTargetName)
    Echo-Log "Create reports for share: $($DFSShare)"

    $ReportPath = 'C:\Temp\' + $DFSShareTargetName
    New-Item -Path $ReportPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

    $ExcelFilePath = $ReportPath + '\Share-DomainGroup-AccessList.xlsx'
    Get-GroupsPerShareReport -ExcelFilePath $ExcelFilePath -DFSShare $DFSShare -SQLConnection $SQLconn
    $ExcelFilePath = $ReportPath + '\Share-DomainUsers-AccessList.xlsx'
    Get-UsersPerShareReport -ExcelFilePath $ExcelFilePath -DFSShare $DFSShare -SQLConnection $SQLconn
}

Echo-Log "End of script on computer $($env:COMPUTERNAME)"
Echo-Log ("=" * 80)
# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================