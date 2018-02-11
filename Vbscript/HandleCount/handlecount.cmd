	@echo off
:Start
	cd /d D:\Scripts\HandleCount
	cscript //NoLogo handlecount.vbs>handlecount.csv
	
	call C:\Scripts\Secdump\setsql.cmd
	call LogParser.exe file:handlecount.sql -i:CSV -o:SQL -server:%SQLSERVER% -database:%SQLDB% -driver:"SQL Server" -username:%SQLUID% -password:%SQLUIDPW%
:Cleanup