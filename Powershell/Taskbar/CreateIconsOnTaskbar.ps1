$shell = New-Object -ComObject Shell.Application
$programsFolder = $shell.Namespace(23).Self.Path
$officeFolder = $shell.Namespace($programsFolder + "\Microsoft Office")
$excel = "Microsoft Excel 2010.lnk"
$word = "Microsoft Word 2010.lnk"
$powerpoint = "Microsoft PowerPoint 2010.lnk"
$office = @($word,$excel,$powerpoint)
foreach($_ in $office){
($officeFolder.ParseName($_).verbs() | ? {$_.Name -match "Tas&kbar"}).Doit()
}