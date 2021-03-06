function Add-Accelerator 
{
    <#
    .Synopsis
        Add a type accelerator to the current session
    .Description
        The Add-Accelerator function allows you to add a simple type accelerator (like [regex]) for a longer type (like
    [System.Text.RegularExpressions.Regex]).
    .Example
        Add-Accelerator list System.Collections.Generic.List``1
        $list = New-Object list[string]
        
        Creates an accelerator for the generic List[T] collection type, and then creates a list of strings.
    .Example
        Add-Accelerator "List T", GList System.Collections.Generic.List``1
        $list = New-Object "list t[string]"
        
        Creates two accelerators for the Generic List[T] collection type.
    .Parameter Accelerator
        The short form accelerator should be just the name you want to use (without square brackets).
    .Parameter Type
        The type you want the accelerator to accelerate (without square brackets)
    .Notes
        When specifying multiple values for a parameter, use commas to separate the values. 
        For example, "-Accelerator string, regex".
        
        PowerShell requires arguments that are "types" to NOT have the square bracket type notation, because of the way
    the parsing engine works.  You can either just type in the type as System.Int64, or you can put parentheses around it 
    to help the parser out: ([System.Int64])
    
        Also see the help for Get-Accelerator and Remove-Accelerator
    .Link
        http://huddledmasses.org/powershell-2-ctp3-custom-accelerators-finally/
      
#>
    [CmdletBinding()]
    PARAM(
        [Parameter(Position=0)]
        [Alias("Key")]
        [string[]]$Accelerator,
        
        [Parameter(Position=1)]
        [Alias("Value")]
        [type]$Type
    )
    
    process {
    
        # add a user-defined accelerator  
        foreach($a in $Accelerator) 
        { 
            $xlr8r::Add( $a, $Type) 
            trap [System.Management.Automation.MethodInvocationException] {
                if($xlr8r::get.keys -contains $a) {
                    Write-Error "Cannot add accelerator [$a] for [$($Type.FullName)]`n                  [$a] is already defined as [$($xlr8r::get[$a].FullName)]"
                    Continue;
                } 
                throw
            }
        }
        
    }
}
    
