function DownloadAndShowImage ($url) {
    $localfilename = "D:\chart.png"
    $webClient = new-object System.Net.WebClient
    $webClient.Headers.Add("user-agent", "PowerShell Badass Script v666")
    $Webclient.DownloadFile($url, $localfilename)
    Invoke-Item $localfilename
}

function simpleEncoding ($valueArray, $labelArray, $size, [switch] $chart3D) {
    $simpleEncoding = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
	
    if ($chart3D) {$chartType = "p3"} else {$chartType ="p"}
    $total = 0
    foreach ($value in $valueArray) {
        $total = $total + $value
    }
    for ($i = 0;$i -lt $valueArray.length;$i++) {
        $relativeValue = ($valueArray[$i] / $total)*62
        $relativeValue = [math]::round($relativeValue)
        $encodingValue = $simpleEncoding[$relativeValue]
        $chartData = $chartData + "" + $encodingValue
    }    
    $chartLabel = [string]::join("|",$labelArray)
    Write-Output "http://chart.apis.google.com/chart?cht=$chartType&chd=s:$chartdata&chs=$size&chl=$chartLabel"
}

function GetProcessArray() {
	$ListOfProcs = Get-Process | Sort-Object CPU -desc | Select-Object CPU, ProcessName -First 10
	$ListOfProcs | ForEach-Object {
		$ProcName = $ProcName + "," + $_.ProcessName
		$ProcUsage = $ProcUsage + "," + $_.CPU
	}
	Write-Output (($ProcName.trimStart(",")).split(","), ($ProcUsage.trimStart(",")).split(","))
}

$values = 100,11,40,9
$text = "Hans","Jane","Rose","Simon"
$url = simpleEncoding $values $text "320x150" -Chart3D
DownloadAndShowImage $url
