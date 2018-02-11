
Import-Module ActiveDirectory -Force -ErrorAction Stop
Import-Module VNB_PSLib -Force -ErrorAction Stop

$SourceGroupName = 'IM System Engineers'
$SourceDN = Get-ADGroupDN -Groupname $SourceGroupName
$SourceDN = $SourceDN.Replace('LDAP://','')
Write-Host $SourceDN

$DestinationGroupName = 'IM-System-Engineers'
$DestinationDN = Get-ADGroupDN -Groupname $DestinationGroupName
$DestinationDN = $DestinationDN.Replace('LDAP://', '')
Write-Output $DestinationDN

$Target = Get-ADGroupMember -Identity $SourceDN -Recursive
foreach ($Person in $Target) {
    Add-ADGroupMember -Identity $DestinationDN -Members $Person.distinguishedname
}