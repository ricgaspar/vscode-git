function Remove-Accelerator 
{
    
    <#
        .Synopsis 
            Remove a type accelerator from the current session
        .Description
            The Remove-Accelerator function allows you to remove a simple type accelerator (like [regex]) from the current 
        session. You can pass one or more accelerators, and even wildcards, but you should be aware that you can remove even th
        e built-in accelerators.
            
        .Example
            Remove-Accelerator int
            Add-Accelerator int Int64
            
            Removes the "int" accelerator for Int32 and adds a new one for Int64. I can't recommend doing this, but it's pr
        etty cool that it works:
            
            So now, "$(([int]3.4).GetType().FullName)" would return "System.Int64"
        .Example
            Get-Accelerator System.Single | Remove-Accelerator
            
            Removes both of the default accelerators for System.Single: [float] and [single]
        .Example
            Get-Accelerator System.Single | Remove-Accelerator -WhatIf
            
            Demonstrates that Remove-Accelerator supports -Confirm and -Whatif. Will Print:
                What if: Removes the alias [float] for type [System.Single]
                What if: Removes the alias [single] for type [System.Single]
        .Parameter Accelerator
            The short form accelerator that you want to remove (Accept wildcard characters).
        .Notes
            When specifying multiple values for a parameter, use commas to separate the values. 
            For example, "-Accel string, regex".
            
            Also see the help for Add-Accelerator and Get-Accelerator
        .Link
            http://huddledmasses.org/powershell-2-ctp3-custom-accelerators-finally/
    #>
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    PARAM(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("Key")]
        [string[]]$Accelerator
    )
    Process 
    {
        
        foreach($a in $Accelerator) {
            foreach($key in $xlr8r::Get.Keys -like $a) { 
                if($PSCmdlet.ShouldProcess( "Removes the alias [$($Key)] for type [$($xlr8r::Get[$key].FullName)]",
                                            "Remove the alias [$($Key)] for type [$($xlr8r::Get[$key].FullName)]?",
                                            "Removing Type Accelerator" )) {
                    # remove a user-defined accelerator
                    $xlr8r::remove($key)   
                }
            }
        }
    
    }
}
    
