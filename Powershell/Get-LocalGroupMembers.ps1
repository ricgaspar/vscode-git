$Computername = 'S031'

$LGroups = Get-WmiObject -Class 'Win32_Group' -ComputerName $Computername | Select-Object Name,Description,Path
ForEach($LocalGroup in $LGroups) {
    $GroupObj = "" | Select-Object Name, Description, Path
    $GroupObj.Name = $($LocalGroup.Name)
    $GroupObj.Description = $($LocalGroup.Description)
    $GroupObj.Path = $($LocalGroup.Path)

}

$GroupMembers = Get-WmiObject -Class 'Win32_GroupUser' -ComputerName $Computername | Select-Object GroupComponent, PartComponent
ForEach ($Member in $GroupMembers) {
    $GroupComponent = $Member.GroupComponent
    $GroupDet = $GroupComponent -split ','
    $LocalGroupName = (($GroupDet[1] -split '=')[1]) -replace '"', ''

    $PartComponent = $Member.PartComponent
    if ($PartComponent -notmatch 'Win32_SystemAccount') {
        $PartDet = $PartComponent -split ','
        $PartDomain = (($PartDet[0] -split '=')[1]) -replace '"', ''
        $PartName = (($PartDet[1] -split '=')[1]) -replace '"', ''

        If ($PartDomain -eq $Computername) { $PartDomain = 'NEDCAR/' + $PartDomain}
        $Member = 'WinNT://' + $PartDomain + '/' + $PartName
        write-Host "LocalGroupName = $LocalgroupName | Trusteename: $Member"

        $MbrObj = "" | Select-Object LocalGroupName, Trusteename
        $MbrObj.LocalGroupName = $localgroupname
        $MbrObj.Trusteename = $Member
    }
}
