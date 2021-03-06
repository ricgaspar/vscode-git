function TS 
{
        
    [CmdletBinding()]
    Param(
    
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true,Mandatory=$true)]
        [string]$ComputerName,
        
        [Parameter()]
        [int]$Timeout = 30,
        
        [parameter()]
        [switch]$admin,
        
        [parameter()]
        [switch]$wait
        
    )
    if($wait)
    {
        Wait-Port -ComputerName $ComputerName -TCPPort 3389 -Timeout $Timeout
    }
    
    if(Test-Host -ComputerName $ComputerName -TCPport 3389 -Timeout ($Timeout*1000))
    {
        if($Admin)
        {
            start mstsc -arg /v:$ComputerName,/admin
        }
        else
        {
            start mstsc /v:$ComputerName
        }
    }
    else
    {
        Write-Host "Unable to Connect"
    }
}
    
