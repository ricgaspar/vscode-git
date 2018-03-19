Import-Module InFlux -Force -ErrorAction Stop

$WebResponse = Invoke-WebRequest 'http://reports.nedcar.nl/alcreports/ALCFA_R_FAS/ALCFA_R_FAS.JSON'
$Stats = $WebResponse.Content
$Stats = $Stats -replace "`n", ""
$Stats = $Stats -replace '{',''
$Stats = $Stats -replace '}',''
$Stats = $Stats -replace [Char]9,''
$Stats = $Stats.Trim()
$Stats = $Stats -replace '"', ''
$Stats = $Stats -replace ': ', '='
$StatsArray = $Stats -split ','

$Tags = @{}
$Tags.Add('REPORT', 'ALCFA_R_FAS')

$Metrics = @{}
ForEach ($StatVal in $StatsArray) {
    $arr = ($StatVal -split '=')
    $key = $arr[0]
    $value = $arr[1]
    $Metrics.add($key, $value)
}
Write-Influx -Measure ALCFA_R_FAS -Tags $Tags -Metrics $Metrics -Database testdb -Server http://VDLNC01800.nedcar.nl:8086 -Verbose
