
echo off
cls
cd /d "C:\Scripts\Exchange\Mailbox size"
%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -command ".'C:\Program Files\Microsoft\Exchange Server\V14\bin\RemoteExchange.ps1';Connect-ExchangeServer -auto; "./exchange2010MailboxReportV1.ps1"


