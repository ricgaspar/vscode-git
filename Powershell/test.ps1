$path = 'C:\temp'
$k = invoke-webrequest https://sourceforge.net/projects/kdiff3/files/kdiff3/0.9.98/KDiff3-64bit-Setup_0.9.98-2.exe/download -UseBasicParsing
$dl = $k.links | where href -match downloads
$dluri = $dl.href.split("?")[0]
$filename = Split-Path $dluri -Leaf
$out = Join-Path $path -ChildPath $filename

Invoke-WebRequest -uri $dluri -OutFile $out -UseBasicParsing

get-item $out