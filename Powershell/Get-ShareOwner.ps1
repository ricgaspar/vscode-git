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
    if ($ObjectData) {
        # Create the table if needed
        $new = New-VNBObjectTable -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
        if ($new) { Echo-Log "Table $ObjectName was created." }

        # Append record to table
        # $RecCount = $($ObjectData.count)
        # Echo-Log "Update table $ObjectName with $RecCount records."
        Send-VNBObject -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
    }
}

Clear-Host

$Computername = $env:COMPUTERNAME
$ObjectName = 'VNB_DOMAIN_DFS_SHAREOWNERS'
$Erase = $True

# Create MSSQL connection
$Global:UDLConnection = Read-UDLConnectionString $glb_UDL

# $SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
$SQLconn = New-UDLSQLconnection $Global:UDLConnection
$query = "select distinct DFSShare,DFSShareTarget,DFSShareTargetServer,DFSSHareTargetName from vw_VNB_P_DOMAIN_DFS"
$data = Query-SQL $query $SQLconn

if ($data -ne $null) {
    $cntr = 0
    ForEach ($rec in $data) {
        $cntr++
        $DFSShareTarget = $rec.DFSShareTarget
        $DFSSHare = $rec.DFSShare

        Write-Output "$($DFSShare) $DFSShareTarget"

        $ExcelPath = $DFSShare + '\' + 'Share.xls'
        IF (Test-Path -Path $ExcelPath) {
            Write-Output " -> Excel file found."

            $xl = New-Object -COM "Excel.Application"
            $xl.Visible = $true
            $wb = $xl.Workbooks.Open($ExcelPath)
            $ws = $wb.Sheets.Item(1)

            $DFSOwner01 = $ws.Cells.Item(4, 2).Text
            $DFSOwner02 = $ws.Cells.Item(4, 3).Text

            $wb.Close($False)
            $xl.Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($xl)

            $object = "" | Select-Object DFSShare, DFSShareOwner01, DFSShareOwner02
            $object.DFSShare = $DFSShare
            $object.DFSShareOwner01 = $DFSOwner01
            $object.DFSShareOwner02 = $DFSOwner02

            $ObjectData = $object
            Insert-Record -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
            $Erase = $False
        }
        else {
            Write-Output " -> ** ERROR ** Excel file not found. $ExcelPath"

            $object = "" | Select-Object DFSShare, DFSShareOwner01, DFSShareOwner02
            $object.DFSShare = $DFSShare
            $object.DFSShareOwner01 = 'Unknown. Share.xls not found.'
            $object.DFSShareOwner02 = 'Unknown. Share.xls not found.'

            $ObjectData = $object
            Insert-Record -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
            $Erase = $False
        }
    }
}