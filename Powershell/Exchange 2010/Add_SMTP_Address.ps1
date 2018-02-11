# ----------------------------------------------------- 
function Release-Ref ($ref) { 
([System.Runtime.InteropServices.Marshal]::ReleaseComObject( 
[System.__ComObject]$ref) -gt 0) 
[System.GC]::Collect() 
[System.GC]::WaitForPendingFinalizers() 
} 
# ----------------------------------------------------- 

cls

$objExcel = new-object -comobject excel.application  
$objExcel.Visible = $True  
$objWorkbook = $objExcel.Workbooks.Open("C:\Scripts\Powershell\Exchange 2010\VDL_Mailbox_NedCar_adressen.xlsx") 
$objWorksheet = $objWorkbook.Worksheets.Item(1) 
 
$intRow = 2 
 
Do { 
    $Username = $objWorksheet.Cells.Item($intRow, 1).Value()
    $NedCarNL = $objWorksheet.Cells.Item($intRow, 4).Value()
	
	$MBox = Get-Mailbox -Identity $Username
	$Check = $MBox.EmailAddresses -contains $NedCarNL
	if($Check -eq $False) {
		Write-Host "Add SMTP address to " $Username $NedCarNL
		$t = Set-Mailbox -Identity $Username -EmailAddresses @{Add=$NedCarNL}		
	} else {
		Write-Host "Skipping " $Username
	}
		
    $intRow++ 	
} 
While ($objWorksheet.Cells.Item($intRow,1).Value() -ne $null) 

$objExcel.Quit() 
 
$a = Release-Ref($objWorksheet) 
$a = Release-Ref($objWorkbook) 
$a = Release-Ref($objExcel)