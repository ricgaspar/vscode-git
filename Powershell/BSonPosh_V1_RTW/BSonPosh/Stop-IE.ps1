function Stop-IE
{
    
    [Cmdletbinding(SupportsShouldProcess=$true)]
    Param()
    ps iexplore -ea 0 | kill 

}
    
