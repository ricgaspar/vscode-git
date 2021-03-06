function Get-Schema
{
    <#
        .Synopsis 
            Returns the Schema.
            
        .Description
            Returns the Schema.
        
        .Parameter DomainController
            Domain Controller to search on.
            
        .Parameter Credential
            Credentials to use.
            
        .Example
            Get-Schema 
            Description
            -----------
            Returnes the Schema.
            
        .Example
            Get-Schema -DomainController MyDC
            Description
            -----------
            Returnes the Schema on DC 'MyDC'
            
        .OUTPUTS
            Object
            
        .INPUTS
            System.String
            
        .Notes
            NAME:      Get-Schema
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    Param(
    
        [Parameter()]
        [String]$DomainController,
        
        [Parameter()]
        [Management.Automation.PSCredential]$Credential
    
    )
    if($DomainController -and !$Credential)
    {
        $Forest = Get-Forest -DNSName $DomainController
    }
    elseif($DomainController -and $Credential)
    {
        $Forest = Get-Forest -DNSName $DomainController -Credential $Credential
    }
    else
    {
        $Forest = Get-Forest
    }
    $Forest.Schema
}
    
