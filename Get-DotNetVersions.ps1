Import-Module DotNetVersionLister -Force

Get-DotNetVersion -ComputerName s030 | Format-Table -auto