New-NetLbfoTeam -Name "Trunk TEAM" -TeamMembers Trunk-1,Trunk-2 –TeamingMode SwitchIndependent
Add-NetLbfoTeamNic  -Team "Trunk TEAM"  -vLanID  88 -Name "Backup VLAN"
Add-NetLbfoTeamNic  -Team "Trunk TEAM"  -vLanID  51 -Name "Deployment VLAN"
Add-NetLbfoTeamNic  -Team "Trunk TEAM"  -vLanID  113 -Name "FAS VLAN"
Add-NetLbfoTeamNic  -Team "Trunk TEAM"  -vLanID  114 -Name "Paintshop VLAN"
Add-NetLbfoTeamNic  -Team "Trunk TEAM"  -vLanID  115 -Name "Bodyshop VLAN"