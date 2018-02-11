$Date = Get-Date -uformat "%d-%m-%Y"
$file = "C:\scripts\exchange\activesync\ActiveSyncdevice-$date.csv"

new-item $file -type file -force -value "User;DeviceType;DeviceModel;DeviceID;DeviceUserAgent;LastSyncTime;deviceos`r`n"


$devices = Get-ActiveSyncDeviceStatistics | Get-ActiveSyncDeviceStatistics

ForEach($device in $devices){
   $Model = $Device.DeviceModel
   $Type = $Device.DeviceType
   $id = $Device.DeviceID
   $LastSyncTime = $Device.LastSuccessSync
   $UserAgent = $Device.DeviceUserAgent
   $deviceOS = $device.deviceOS
   
   $identity = $device.identity|out-string
   $identity = $identity.split("/")[-2]

   Add-Content -Path $file "$identity;$Type;$Model;$id;$UserAgent;$LastSyncTime;$deviceos"
}