function Ping-Subnet
{
    
    <#
        .Synopsis 
            Ping a subnet returning all alive hosts.
            
        .Description
            Ping a subnet returning all alive hosts.
                        
        .Parameter IP 
            IP of a host on the Network.
            
        .Parameter Network 
            Network Address.
        
        .Example
            Ping-Subnet -IP 192.168.1.0 -Netmask 255.255.255.0
            Description
            -----------
            Pings all host on 192.168.1.0 network using mask 255.255.255.0
            
        .Example
            Ping-Subnet -IP 192.168.1.0 -Netmask /24
            Description
            -----------
            Pings all host on 192.168.1.0 network using CIDR notation
            
        .OUTPUTS
            System.String
            
        .INPUTS
            System.String
            
        .Link
            Get-IPRange
            Invoke-Pingmonitor
            Get-NetworkAddress
            ConvertTo-BinaryIP 
            ConvertFrom-BinaryIP 
            ConvertTo-MaskLength 
            ConvertFrom-MaskLength 
            
        NAME:      Ping-Subnet
        AUTHOR:    Glenn Sizemore
        Website:   http://get-admin.com
        Version:   1
        #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$IP,
        
        [Alias("mask")]
        [Parameter(Mandatory=$True)]
        [string]$netmask
    )
    Begin 
    {
        $IPs = New-Object System.Collections.ArrayList
        $Jobs = New-Object System.Collections.ArrayList
        $max = 50  
    }
    
    Process 
    {
    
        #get every ip in scope
        Get-IPRange $IP $netmask | %{
            [void]$IPs.Add($_)
        }
        #loop untill we've pinged them all
        While ($IPs.count -gt 0 -or $jobs.count -gt 0) 
        {
            #if we have open spots kick off some more
            if ($jobs.count -le $max) 
            {
                # determin how many to kick off
                $addjobs = ($max - $jobs.count)
                foreach ($IP in ($IPS | Select -first $addjobs)) 
                {
                    #save the job id, and move on
                    [VOID]$Jobs.Add((gwmi -q "SELECT Address,StatusCode FROM Win32_Pingstatus WHERE Address = `'$IP`'" -asjob).Id)
                    #remove the IP from our pool
                    $IPs.Remove($IP)
                }
            }
            #we'll use this array to track what's comeback
            $Clean = @()
            
            foreach ($J in $jobs) 
            {
                # If this job is done get the results
                if ((Get-Job -id $j).JobStateInfo.state -eq 'Completed') 
                {
                    # if the ping was sucessfull return the IP Address
                    write-output (Receive-Job -id $j) | ?{$_.StatusCode -eq 0}| select -expand Address
                    # dispose of the job
                    remove-job -id $j
                    $clean += $j
                }
            }
            foreach ($c in $Clean) 
            {
                #remove the jobs that we just processed
                $jobs.remove($c)
            }
        }
    
    }
}
    
