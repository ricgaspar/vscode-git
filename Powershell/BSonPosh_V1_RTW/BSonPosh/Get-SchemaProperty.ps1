function Get-SchemaProperty
{
    
    <#
        .Synopsis 
            Returns the Schema Property specified. 
            
        .Description
            Returns the Schema Property specified.
            
        .Parameter Property
            Property you want to return.
            
        .Parameter DomainController
            Domain Controller to search on.
            
        .Parameter Credential
            Credentials to use.
            
        .Example
            Get-SchemaProperty 
            Description
            -----------
            Returnes all the Schema Properties in the Schema.
            
        .Example
            Get-SchemaProperty -Property name
            Description
            -----------
            Returnes all the Schema Properties that match name.
            
        .Example
            Get-SchemaProperty -DomainController MyDC
            Description
            -----------
            Returnes all the Schema Properties in the Schema on DC 'MyDC'
    
        .OUTPUTS
            Object
            
        .INPUTS
            System.String
            
        .Notes
            NAME:      Get-SchemaProperty
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        
        [Parameter()]
        [String]$Property = ".*",
        
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
    
    $Forest.Schema.FindAllProperties() | ?{$_.Name -match "^$Property`$"}
}
    
