function Get-Accelerator
{
        
    <#
        .Synopsis
            Get one or more type accelerator definitions
        .Description
            The Get-Accelerator function allows you to look up the type accelerators (like [regex]) defined on your system 
        by their short form or by type
        .Example
            Get-Accelerator System.String
            
            Returns the KeyValue pair for the [System.String] accelerator(s)
        .Example
            Get-Accelerator ps*,wmi*
            
            Returns the KeyValue pairs for the matching accelerator definition(s)
        .Parameter Accelerator
            One or more short form accelerators to search for (Accept wildcard characters).
        .Parameter Type
            One or more types to search for.
        .Notes
            When specifying multiple values for a parameter, use commas to separate the values. 
            For example, "-Accelerator string, regex".
            
            Also see the help for Add-Accelerator and Remove-Accelerator
        .Link
            http://huddledmasses.org/powershell-2-ctp3-custom-accelerators-finally/
    #>
    
    [CmdletBinding(DefaultParameterSetName="ByType")]
    PARAM(
        [Parameter(Position=0, ParameterSetName="ByAccelerator", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("Key")]
        [string[]]$Accelerator,
        
        [Parameter(Position=0, ParameterSetName="ByType", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("Value")]
        [type[]]$Type
    )
    
    Process 
    {
    
        # add a user-defined accelerator  
        switch($PSCmdlet.ParameterSetName) {
            "ByAccelerator" { 
                $xlr8r::get.GetEnumerator() | % {
                    foreach($a in $Accelerator) {
                    if($_.Key -like $a) { $_ }
                    }
                }
                break
            }
            "ByType" { 
                if($Type -and $Type.Count) {
                    $xlr8r::get.GetEnumerator() | ? { $Type -contains $_.Value }
                }
                else {
                    $xlr8r::get.GetEnumerator() | %{ $_ }
                }
                break
            }
        }
        
    }
}
    
