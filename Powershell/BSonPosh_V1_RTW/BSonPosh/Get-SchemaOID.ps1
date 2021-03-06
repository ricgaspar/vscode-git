function Get-SchemaOID 
{
    
    <#
        .Synopsis 
            Returns any Schema Class or Property by OID.
            
        .Description
            Returns any Schema Class or Property by OID.
            
        .Parameter OID
            OID you want to search for.
            
        .Example
            Get-SchemaOID $OID
            Description
            -----------
            Returnes the Schema Class or Property associated with the OID.
    
        .OUTPUTS
            Object
            
        .INPUTS
            System.String
            
        .Notes
            NAME:      Get-SchemaOID
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    Param([String]$OID)
    $Forest = [DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
    $Forest.Schema.FindAllClasses() | ?{$_.oid -eq $OID}
    $Forest.Schema.FindAllProperties() | ?{$_.oid -eq $OID}
}
    
