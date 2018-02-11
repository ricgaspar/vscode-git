$collectionname = 'Deploy - Factory - ALCM shortcut cleanup'

#Read list of computers from the text file
$filename = "C:\Scripts\SCCM\Collections\computers.txt"
$computers = Get-Content $filename
foreach($computer in $computers) {    
        $ResId = get-cmdevice -Name $computer
        $ResId
        Add-CMDeviceCollectionDirectMembershipRule  -CollectionName $collectionname -ResourceId $($ResId).ResourceID
}