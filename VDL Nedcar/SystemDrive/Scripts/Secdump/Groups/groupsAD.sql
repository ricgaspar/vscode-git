Select cn as groupname,description,distinguishedName,groupType,objectSid,system_time() as poldatetime
INTO groupsAD 
from groupsAD.csv