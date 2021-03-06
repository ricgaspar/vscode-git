function Get-DCConnectionObject
{
        
    <#
        .Synopsis 
            Gets Active Directory Connection Objects for DCs that match the filter.
            
        .Description
            Gets Active Directory Connection Objects for DCs that match the filter.
            
        .Parameter Filter
            Regex filter for the DC(s) to get the connection Objects for.
            
        .Example
            Get-DCConnectionObject -filter "(Site1)|(site2)"
            Description
            -----------
            Gets the connection objects for DC(s) that match site1 or site2
    
        .OUTPUTS
            Object
            
        .INPUTS
            String
            
        .Link
            Get-DomainController
        
        .Notes    
            NAME:      Get-DCConnectionObject
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    Param($Filter = ".*")
    $Myforest = [DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
    $MyDCs = $Myforest.Domains | foreach-object{$_.DomainControllers} | ?{$_.name -match $Filter}
    $MyDCs | %{$_.InboundConnections}
    

}
    
Get-DCConnectionObject