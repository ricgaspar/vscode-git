function Invoke-uac
{
    
    <#
        .Synopsis 
            Creates an elevated shell. 
            
        .Description
            Creates an elevated shell.
            
        .Parameter NoProfile
            Avoids loading profile information
            
        .Example
            Invoke-UAC
            Description
            -----------
            Creates a new shell with elevation
    
        .Notes
            NAME:      Invoke-UAC
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    Param([switch]$noProfile)
    $shell = new-Object -com shell.application
    $myPath = $pwd
    $argString = [string]::join(" ",$args)
    if($argString){
    if($noProfile){$command = "-noprofile "}
        $command += "-noexit -command `"& {`prompt ;cd $myPath;`$host.UI.RawUI.CursorPosition = `$PromptCursorPosition;
    Write-Host `"$argString`" ; invoke-expression '$argString'}`" "
    }
    else
    {
    if($noProfile){$command = "-noprofile "}
        $command += "-noexit -command `"& {cd $myPath}"
    }
    $shell.ShellExecute("powershell.exe",$command,$PWD,"runas")
}
    
