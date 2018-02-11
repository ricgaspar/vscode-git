#Create Collections and Membership Rules from Text Files
#Author: Mike Terrill
#Set path to collection directory

$collectionname = 'Deploy - Windows 7 Bitlocker - Hoger management'
#Add new collection based on the file name
# try {
#    New-CMDeviceCollection -Name $collectionname -LimitingCollectionName "All Systems"
#}
#catch {
#    "Error creating collection - collection may already exist: $collectionname"
#}
 
#Read list of computers from the text file
$filename = "C:\Scripts\SCCM\Collections\STATIC-Top-Management.txt"
$computers = Get-Content $filename
foreach($computer in $computers) {    
 
        $ResId = get-cmdevice -Name $computer
        $ResId
        Add-CMDeviceCollectionDirectMembershipRule  -CollectionName $collectionname -ResourceId $($ResId).ResourceID
 
 
}