Import-Module VNB_PSLib -Force

$ADSearchFilter = '(objectCategory=Computer)'
$ObjectList = Search-AD -ADSearchFilter $ADSearchFilter
$ComputerList = @()
foreach ($objResult in $ObjectList) {
	$ObjItem = $objResult.Properties
	$ObjComputer = New-Object System.Object
	$ObjComputer | Add-Member -MemberType NoteProperty -Name Name -Value $($ObjItem.name) -Force
	$ObjComputer | Add-Member -MemberType NoteProperty -Name AdsPath -Value $($ObjItem.adspath) -Force
	$ComputerList += $ObjComputer			
}
$ComputerList = $ComputerList | sort @{ expression = { $_.Name }; Descending = $false }
$ComputerList = $ComputerList | Where-Object { $_.AdsPath -match 'OU=FAS' } | Where-Object { $_.AdsPath -match 'OU=Cascade_client' }

foreach($Computer in $ComputerList)
{
	$Computername = $($Computer.Name)
    Write-Host "Computer: $($Computername)  ADS:$($Computer.Adspath)"
    $Test = Test-ComputerAlive $Computername
    if($Test) {
        $reg = Invoke-Command -ComputerName $computername -ScriptBlock {
            c:\windows\system32\sc.exe stop nscp
			c:\windows\system32\sc.exe config nscp start= disabled
		}
        
    } else {
        Write-Host " == computer is dead."
    }
}