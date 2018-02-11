	@echo off
	cd /d "C:\Scripts\Powershell\Exchange 2010"
:Start
	set IISLOGS="\\vs090\c$\inetpub\logs\logfiles\W3SVC1"
	set LOGPARSER="C:\\Scripts\Utils\Logparser.exe"

	powershell ./ActiveSyncReport.ps1 -IISLogs %IISLOGS%  -LogparserExec %LOGPARSER% -ActiveSyncOutputFolder c:\EASReports -MinimumHits 1000 -HTMLReport HIT

	powershell ./ActiveSyncReport.ps1 -IISLogs %IISLOGS%  -LogparserExec %LOGPARSER% -ActiveSyncOutputFolder C:\EASReports -HTMLReport LIST

	powershell ./ActiveSyncReport.ps1 -IISLogs %IISLOGS%  -LogparserExec %LOGPARSER% -ActiveSyncOutputFolder C:\EASReports -Hourly -HTMLReport HOURLY

	powershell ./ActiveSyncReport.ps1 -IISLogs %IISLOGS%  -DevideID ApplDNQGKRB3DTD7 -LogparserExec %LOGPARSER% -ActiveSyncOutputFolder C:\EASReports -Hourly -HTMLReport ApplDNQGKRB3DTD7