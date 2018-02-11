Import-Module VNB_PSLib -Force -ErrorAction Stop

# -----------------------------------------------------
function Release-Ref ($ref) {
([System.Runtime.InteropServices.Marshal]::ReleaseComObject(
[System.__ComObject]$ref) -gt 0)
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
}
# -----------------------------------------------------

# ---------------------------------------------------------
# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
# ---------------------------------------------------------
# Open SQL Connection (connection name is script name)
$conn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
if ($conn.state -eq "Closed") { exit }

$objExcel = new-object -comobject excel.application
$objExcel.Visible = $True
$objWorkbook = $objExcel.Workbooks.Open("C:\TempTools\Cadportal_Users (December 2017) with access to BMW-Prisma (QX-number) .xlsx")
$objWorksheet = $objWorkbook.Worksheets.Item(1)

$intRow = 2

$query = "delete from VNB_DOMAIN_USERS_CADPORTAL_IMPORT"
$data = Query-SQL $query $conn

Do {
    $ISP_USERID = $objWorksheet.Cells.Item($intRow, 2).Value()
    $Username = $objWorksheet.Cells.Item($intRow, 3).Value()

    $query = "insert into VNB_DOMAIN_USERS_CADPORTAL_IMPORT" +
    "(ISP_USERID, Username)" +
    " VALUES ('" + $ISP_USERID + "','" + $Username + "'" + ")"
    $data = Query-SQL $query $conn

    $intRow++
}
While ($objWorksheet.Cells.Item($intRow, 2).Value() -ne $null)

Remove-SQLconnection $conn

$objExcel.Quit()

$a = Release-Ref($objWorksheet)
$a = Release-Ref($objWorkbook)
$a = Release-Ref($objExcel)