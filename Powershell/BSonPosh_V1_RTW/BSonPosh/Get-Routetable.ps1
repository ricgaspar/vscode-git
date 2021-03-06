function Get-Routetable
{
    
    <#
        .Synopsis 
            Gets the route table for specified host.
            
        .Description
            Gets the route table for specified host.
            
        .Parameter ComputerName
            Name of the Computer to get the route table from (Default is localhost.)
            
        .Example
            Get-RouteTable
            Description
            -----------
            Gets route table from local machine
    
        .Example
            Get-RouteTable -ComputerName MyServer
            Description
            -----------
            Gets route table from MyServer
            
        .Example
            $Servers | Get-RouteTable
            Description
            -----------
            Gets route table for each machine in the pipeline
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Link
            N/A
            
        .Notes
            NAME:      Get-RouteTable
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
    )
    process 
    {
    
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host $ComputerName -TCPPort 135)
        {
            $Routes = Get-WMIObject Win32_IP4RouteTable -ComputerName $ComputerName -Property Name,Mask,NextHop,Metric1,Type
            foreach($Route in $Routes)
            {
                $myobj = @{}
                $myobj.ComputerName = $ComputerName
                $myobj.Name = $Route.Name
                $myobj.NetworkMask = $Route.mask
                $myobj.Gateway = if($Route.NextHop -eq "0.0.0.0"){"On-Link"}else{$Route.NextHop}
                $myobj.Metric = $Route.Metric1
                
                $obj = New-Object PSObject -Property $myobj
                $obj.PSTypeNames.Clear()
                $obj.PSTypeNames.Add('BSonPosh.RouteTable')
                $obj
            }
        }
        else
        {
            Write-Host " Host [$ComputerName] Failed Connectivity Test " -ForegroundColor Red
        }
    
    }
}
    
