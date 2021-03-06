function Get-Domain
{
        
    <#
        .Synopsis 
            Returns the Local Domain.
            
        .Description
            Returns the Local Domain.
            
        .Parameter DomainController
            Domain Controller to get the forest from.
        
        .Parameter Credential
            PSCredentials to use to discover forest with.
            
        .Example
            Get-Domain
            Description
            -----------
            Returns the default domain
    
        .OUTPUTS
            System.DirectoryService.ActiveDirectory.Domain
            
        .INPUTS
            System.String
            
        .Link
            Get-Forest
        
        .Notes
            NAME:      Get-Domain
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    
    Param(
    
        [Parameter()]
        $DomainController,
        
        [Parameter()]
        [Management.Automation.PSCredential]$Credential
    
    )
	
    if(!$DomainController)
    {
        [DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        return
    }
    
    if($Creds)
    {
        $Context = new-object DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",
                                                                                $DomainController,
                                                                                $Creds.UserName,
                                                                                $Creds.GetNetworkCredential().Password)
    }
    else
    {
        $Context = new-object DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$DomainController)
    }
    
    [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
}
    
Get-Domain dc07