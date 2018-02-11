Import-Module -Name DellBIOSProvider
$password = 'kleinevogel'
$changed = $false
$DeepSleepCtrl = Get-ChildItem -Path DellSmbios:\PowerManagement\DeepSleepCtrl -ErrorAction SilentlyContinue
$val = $DeepSleepCtrl.CurrentValue
if($val) {
    if($val -eq 'Disabled') {        
    } else {
        Set-Item -path DellSmbios:\PowerManagement\DeepSleepCtrl -value 'Disabled' -Password $password
        $changed = $true
    }
    $DeepSleepCtrl = Get-ChildItem -Path DellSmbios:\PowerManagement\DeepSleepCtrl -ErrorAction SilentlyContinue
    $val = $DeepSleepCtrl.CurrentValue
    if($changed) { 
        Write-Output "The Deep Sleep Control feature was changed." 
    } else {
        Write-Output "The Deep Sleep Control feature was not changed." 
    }
    Write-Output "Deep Sleep Control is set to: $val"
}
else {
    Write-Host "WARNING: The Deep Sleep Control feature is not supported."
}

$changed = $false
$WakeOnLan = Get-ChildItem -Path DellSmbios:\PowerManagement\WakeOnLan  -ErrorAction SilentlyContinue
$val = $WakeOnLan.CurrentValue
if($val) {
    if($val -eq 'WLanOnly') {
    } else {
        Set-Item -path DellSmbios:\PowerManagement\WakeOnLan -value 'LanOnly' -Password $password
        $changed = $true
    }
    $WakeOnLan = Get-ChildItem -Path DellSmbios:\PowerManagement\WakeOnLan  -ErrorAction SilentlyContinue
    $val = $WakeOnLan.CurrentValue
    if($changed) { 
        Write-Output "The wake on LAN feature was changed." 
    } else {
        Write-Output "The wake on LAN feature was not changed." 
    }
    Write-Output "Wake on LAN feature is set to: $val"
}
else {
    Write-Host "WARNING: The Wake On LAN feature is not supported."
}