function Test-Host
{
        
    <#
        .Synopsis 
            Test a host for connectivity using either WMI ping or TCP port
            
        .Description
            Allows you to test a host for connectivity before further processing
            
        .Parameter Server
            Name of the Server to Process.
            
        .Parameter TCPPort
            TCP Port to connect to. (default 135)
            
        .Parameter Timeout
            Timeout for the TCP connection (default 1 sec)
            
        .Parameter Property
            Name of the Property that contains the value to test.
            
        .Example
            cat ServerFile.txt | Test-Host | Invoke-DoSomething
            Description
            -----------
            To test a list of hosts.
            
        .Example
            cat ServerFile.txt | Test-Host -tcp 80 | Invoke-DoSomething
            Description
            -----------
            To test a list of hosts against port 80.
            
        .Example
            Get-ADComputer | Test-Host -property dnsHostname | Invoke-DoSomething
            Description
            -----------
            To test the output of Get-ADComputer using the dnshostname property
            
            
        .OUTPUTS
            System.Object
            
        .INPUTS
            System.String
            
        .Link
            Test-Port
            
        NAME:      Test-Host
        AUTHOR:    YetiCentral\bshell
        Website:   www.bsonposh.com
        LASTEDIT:  02/04/2009 18:25:15
        #Requires -Version 2.0
    #>
    
    [CmdletBinding()]
    
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true,Mandatory=$True)]
        [Object]$ComputerName,
        [Parameter()]
        [int]$TCPPort,
        [Parameter()]
        [int]$timeout=3000,
        [Parameter()]
        [string]$property
        )
    Begin 
    {
    
        function PingServer 
        {
            Param($MyHost)
            $ErrorActionPreference = "SilentlyContinue"
            Write-Verbose " [PingServer] :: Pinging [$MyHost]"
            try
            {
                $pingresult = Get-WmiObject win32_pingstatus -f "address='$MyHost'"
                Write-Verbose " [PingServer] :: Ping returned $($pingresult.statuscode)"
                if($pingresult.statuscode -eq 0) {$true} else {$false}
            }
            catch
            {
                Write-Verbose " [PingServer] :: Ping Failed with Error: ${error[0]}"
                $false
            }
        }
    
    }
    
    Process 
    {
    
        Write-Verbose " [Test-Host] :: Begin Process"
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        Write-Verbose " [Test-Host] :: ComputerName   : $ComputerName"
        if($TCPPort)
        {
            Write-Verbose " [Test-Host] :: Timeout  : $timeout"
            Write-Verbose " [Test-Host] :: Port     : $TCPPort"
            if($property)
            {
                Write-Verbose " [Test-Host] :: Property : $Property"
                if(Test-Port $ComputerName.$property -tcp $TCPPort -timeout $timeout){$ComputerName}
            }
            else
            {
                if(Test-Port $ComputerName -tcp $TCPPort -timeout $timeout){$ComputerName} 
            }
        }
        else
        {
            if($property)
            {
                Write-Verbose " [Test-Host] :: Property : $Property"
                try
                {
                    if(PingServer $ComputerName.$property){$ComputerName} 
                }
                catch
                {
                    Write-Verbose " [Test-Host] :: $($ComputerName.$property) Failed Ping"
                }
            }
            else
            {
                Write-Verbose " [Test-Host] :: Simple Ping"
                try
                {
                    if(PingServer $ComputerName){$ComputerName}
                }
                catch
                {
                    Write-Verbose " [Test-Host] :: $ComputerName Failed Ping"
                }
            }
        }
        Write-Verbose " [Test-Host] :: End Process"
    
    }
}
    
