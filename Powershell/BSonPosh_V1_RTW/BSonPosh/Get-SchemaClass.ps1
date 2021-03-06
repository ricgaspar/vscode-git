function Get-SchemaClass
{
        
    <#
        .Synopsis 
            Returns the Schema Class specified. 
            
        .Description
            Returns the Schema Class specified.
            
        .Parameter Class
            Class you want to return.
            
        .Parameter DomainController
            Domain Controller to search on.
            
        .Parameter Credential
            Credentials to use.
            
        .Example
            Get-SchemaClass 
            Description
            -----------
            Returnes all the Schema Classes in the Schema.
            
        .Example
            Get-SchemaClass -Class User
            Description
            -----------
            Returnes all the Schema Classes that match User.
            
        .Example
            Get-SchemaClass -DomainController MyDC
            Description
            -----------
            Returnes all the Schema Classes in the Schema on DC 'MyDC'
    
        .OUTPUTS
            Object
            
        .INPUTS
            System.String
            
        .Notes
            NAME:      Get-SchemaClass
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        
        [Parameter()]
        [String]$Class = ".*",
        
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
    
    $Forest.Schema.FindAllClasses() | ?{$_.Name -match "^$Class`$"}
}
    
