SELECT COMPUTER_NAME() as Systemname, SYSTEM_DATE() as Poldatetime,ActiveTime,ClientType,ComputerName,Description,IdleTime,InstallDate,Name,ResourcesOpened,SessionType,Status,TransportName,UserName
INTO Sessions
FROM ServerSession.csv