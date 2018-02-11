# Define Interval
$AuditStartTime = (get-date) - (New-TimeSpan -Hours 5)
$AuditEndTime = (get-date)


# Get the events
$EventLogName = 'Security'
$EventLogID = 4624,4625
$Events = Get-WinEvent -FilterHashTable @{LogName=$EventLogName; Id=$EventLogID; StartTime=$AuditStartTime; EndTime=$AuditEndTime}

$Result= @()
ForEach($Event in $Events) {
    $eventXML = [xml]$Event.ToXml()
    $objEvents = New-Object System.Object
    # Iterate through each one of the XML message properties            
    For ($i=0; $i -lt $eventXML.Event.EventData.Data.Count; $i++) {            
        # Append these as object properties            
        $objEvents | Add-Member -MemberType NoteProperty -Name $eventXML.Event.EventData.Data[$i].name -Value $eventXML.Event.EventData.Data[$i].'#text'            
    }
    $Result += $objEvents
}
