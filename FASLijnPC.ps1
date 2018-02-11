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
$ComputerList = $ComputerList | Where-Object { $_.AdsPath -match 'OU=FAS' } | Where-Object { $_.AdsPath -match 'OU=LijnPC' }

foreach($Computer in $ComputerList)
{
	$Computername = $($Computer.Name)
    Write-Host "Computer: $($Computername)  ADS:$($Computer.Adspath)"
    $Test = Test-ComputerAlive $Computername
    if($Test) {
        Write-Host "  .. computer is accessible."
        $ShortCut = "\\$Computername\c$\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\ALCM Client.lnk"
        if(Test-Path $ShortCut) {
            Write-Host "  .. shortcut is present."
            Remove-Item $ShortCut -Force | Out-Null
        } else {
            Write-Host "  ## Shortcut is removed."
        }

        $reg = Invoke-Command -ComputerName $computername -ScriptBlock {
			Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value "0"
		}
        
    } else {
        Write-Host " == computer is dead."
    }
}