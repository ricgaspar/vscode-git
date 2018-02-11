function ConvertTo-Name
{
    param($sid)
    $ID = New-Object System.Security.Principal.SecurityIdentifier($sid)
    $User = $ID.Translate( [System.Security.Principal.NTAccount])
    $User.Value
}
    
