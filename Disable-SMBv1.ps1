
# Configure SMB on the Server
# Disable SMB v1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters” SMB1 -Value 0 –Force
# Make sure to enable SMB v2
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters” SMB2 -Value 1 –Force

#
# Disable SMB v1 on the Client, change dependency of LanManWorkstation to use SMB v2
sc.exe config lanmanworkstation depend= bowser/mrxsmb20/nsi  
#
# Disable SMB v1 service on the Client
sc.exe config mrxsmb10 start= disabled 