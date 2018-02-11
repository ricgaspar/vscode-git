$gm=New-Object -com FSRM.FSRMGlobalStoreManager

$s=[xml]$gm.GetStoreData("Settings", "ReportSettings")

$s.Save("fsrm-reports-backup.xml")

$s.root.MaxQuotas="10000"

$gm.SetStoreData("Settings", "ReportSettings",$s.get_InnerXml())

