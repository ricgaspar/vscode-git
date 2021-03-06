function Invoke-WhoAmI
{
    
    <#
        .Synopsis 
            Gets the Identity for the local user.
            
        .Description
            Gets the Identity for the local user.
            
        
        .Example
            Invoke-WHOAmI
            Description
            -----------
            Returns PSCustomObject for the local user
    
        .OUTPUTS
            PSCustomObject
            
        .Link
            ConvertTo-Name
            
        .Notes
            NAME:      Invoke-WHOAmI
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    $myobj = @{} # "" | Select User,Groups,RawObject
    $Self = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myobj.User = ConvertTo-Name $self.User
    $myobj.Groups = $Self.Groups | %{ConvertTo-Name $_.Value}
    $myobj.RawObject = $self
    
    $obj = New-Object PSObject -Property $myobj
    $obj.PSTypeNames.Clear()
    $obj.PSTypeNames.Add('BSonPosh.WhoAMI')
    $obj

}
    
