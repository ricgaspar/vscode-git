$users = Get-ADGroupMember -Identity 'NEDCAR\IQBS_Controlling_Gebruikers'
$users.count