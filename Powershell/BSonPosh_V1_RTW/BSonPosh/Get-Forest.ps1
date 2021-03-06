function Get-Forest
{
        
    <#
        .Synopsis 
            Returns the Local Forest.
            
        .Description
            Returns the Local Forest.
            
        .Parameter DomainController
            Domain Controller to get the forest from.
        
        .Parameter Credential
            PSCredentials to use to discover forest with.
            
        .Example
            Get-Forest
            Description
            -----------
            Returns the default forest
    
        .OUTPUTS
            System.DirectoryService.ActiveDirectory.Forest
            
        .INPUTS
            System.String
            
        .Link
            Get-Domain
        
        .Notes
            NAME:      Get-Forest
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
        [DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
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
    [DirectoryServices.ActiveDirectory.Forest]::GetForest($Context)
}
    
