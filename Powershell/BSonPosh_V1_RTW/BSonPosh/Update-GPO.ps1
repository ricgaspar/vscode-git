function Update-GPO
{
        
    <#
        .Synopsis 
            Refreshes Group Policies settings.
            
        .Description
            Refreshes Group Policies settings.
            
        .Parameter ComputerName
            The Category to set the network(s) to. Valid Value: Public, Private, or Domain.
        
        .Parameter Target
            Specifies that only User or only Computer policy settings are refreshed. 
            By default,both User and Computer policy settings are refreshed.
    
        .Parameter Wait
            Sets the number of seconds to wait for policy processing to finish. 
            The default is 600 seconds. The value '0' means not to wait. The value '-1' means to wait indefinitely. 
            prompt returns, but policy processing continues.
            
        .Parameter Force
            Reapplies all policy settings. By default, only policy settings that have changed are applied.
    
        .Parameter Logoff
            Causes a logoff after the Group Policy settings have been refreshed. 
            This is required for those Group Policy client-side extensions that 
            do not process policy on a background refresh cycle but do process policy when a user logs on. 
            Examples include user-targeted Software Installation and Folder Redirection.
            This option has no effect if there are no extensions called that require a logoff.
            
        .Parameter Boot
            Causes a reboot after the Group Policy settings are refreshed. This is required for those
            Group Policy client-side extensions that do not process policy on a background refresh cycle
            but do process policy at computer startup. Examples include computer-targeted Software Installation. 
            This option has no effect if there are no extensions called that require a reboot.
    
        .Parameter Sync
            Causes the next foreground policy application to be done synchronously. 
            Foreground policy applications occur at computer boot and user logon.
            You can specify this for the user, computer or both using the -Target parameter.
            The -Force and -Wait parameters will be ignored if specified.
            
        .Example
            Update-GPO
            Description
            -----------
            Updates the local group policies.
        
        .Example
            Update-GPO -ComputerName MyServer1
            Description
            -----------
            Updates the group policies on MyServer1.
            
        .OUTPUTS
            PSCustomObject
            
        .Notes
            NAME:      Update-GPO
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            LASTEDIT:  11/09/2009 
            #Requires -Version 2.0
    #>
    
    [cmdletbinding()]
    Param(
    
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter()]
        [ValidateSet("User", "Computer")]
        [string]$Target,
        
        [Parameter()]
        [int]$Wait,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$Logoff,
        
        [Parameter()]
        [switch]$Boot,
        
        [Parameter()]
        [switch]$Sync
        
    )
    
    Begin 
    {
    
        Write-Verbose " [Update-GPO] :: Begin Start"
        function Get-ReturnCode($ReturnValue)
        {
            switch ($ReturnValue)
            {
                0 {"Successful Completion"}
                2 {"Access Denied"}
                3 {"Insufficient Privilege"}
                8 {"Unknown failure"}
                9 {"Path Not Found"}
                21 {"Invalid Parameter"}
                default {"Unknown"}
            }
        }
        $InvokeArguments = "gpupdate"
        if($Target)
        {
            $InvokeArguments += " /Target:$Target"
        }
        if($Wait)
        {
            $InvokeArguments += " /Wait:$Wait"
        }
        if($Force)
        {
            $InvokeArguments += " /Force"
        }
        if($Logoff)
        {
            $InvokeArguments += " /Logoff"
        }
        if($Boot)
        {
            $InvokeArguments += " /Boot"
        }
        if($Sync)
        {
            $InvokeArguments += " /Sync"
        }
        Write-Verbose " [Update-GPO] :: Command - $InvokeArguments"
        Write-Verbose " [Update-GPO] :: Begin End"
    
    }
    
    Process 
    {
    
        Write-Verbose " [Update-GPO] :: Process Start"
        $myobj = @{}
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        $myobj.ComputerName = $ComputerName
        if(Test-Host $ComputerName -TCPPort 135)
        {
            Write-Verbose " [Update-GPO] :: Calling Win32_Process::Create on $ComputerName"
            Write-Verbose " [Update-GPO] :: Command - $InvokeArguments"
            try 
            {
                $ReturnValue = Invoke-WmiMethod -Class Win32_Process -ComputerName $ComputerName -Name Create -ArgumentList $InvokeArguments
                Write-Verbose " [Update-GPO] :: Command Returned - $($ReturnValue.ReturnValue)"
                
                $ReturnValueToString = Get-ReturnCode $ReturnValue.ReturnValue
                Write-Verbose " [Update-GPO] :: Command Return String - $ReturnValueToString"
                $myobj.Result = $ReturnValueToString
                
                if($ReturnValue.ReturnValue -eq 0)
                {
                    $myobj.Success = $true
                }
                else
                {
                    $myobj.Success = $false
                }
            }
            catch
            {
                $myobj.Result = $Error[0]
                $myobj.Success = $false
            }
    
        }
        else
        {
            $myobj.Success = $false
            $myobj.Result = "Unable to Connect"
            Write-Host " Unable to Ping or Port 135 not open :: $ComputerName" -ForegroundColor Red
        }
        
        New-Object PSCustomObject -Property $myobj
        
        Write-Verbose " [Update-GPO] :: Process End"
    
    }
}
    
