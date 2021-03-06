function Get-WindowsUpdate
{
        
    <#
        .Synopsis  
            Invokes Windows Update on local machine.
            
        .Description
            Invokes Windows Update on local machine.
            
        .Parameter Download
            [Switch] :: Download only
            
        .Parameter Install
            [Switch] :: Install
            
        .Parameter FullDetail
            [Switch] :: Provide Full Detail
            
        .Parameter Confirm
            [Switch] :: Prompt for Confirmation
                
        .Example
            Get-WindowsUpdate
            Description
            -----------
            Gets all the Windows updates for the local machine
            
        .Example
            Get-WindowsUpdate -download
            Description
            -----------
            Downloads all the Windows updates for the local machine
            
        .Example
            Get-WindowsUpdate -Install
            Description
            -----------
            Installs all the Windows updates for the local machine
            
        .Example
            Get-WindowsUpdate -Confirm
            Description
            -----------
            Gets all the Windows updates for the local machine prompting before installing.
            
        .OUTPUTS
            $null
            
        .INPUTS
            $null
            
        .Notes
            NAME:      Get-WindowsUpdate
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [Parameter()]
        [switch]$download,
        [Parameter()]
        [Switch]$install,
        [Parameter()]
        [switch]$FullDetail,
        [Parameter()]
        [switch]$confirm
    )
    
    function Get-WIAStatusValue($value)
    {
    switch -exact ($value)
        {
            0   {"NotStarted"}
            1   {"InProgress"}
            2   {"Succeeded"}
            3   {"SucceededWithErrors"}
            4   {"Failed"}
            5   {"Aborted"}
        
        } 
    } 
    
    Write-Host " - Creating WU COM object"
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher() 
    
    Write-Host " - Searching for Updates"
    $SearchResult = $UpdateSearcher.Search("IsAssigned=1 and IsHidden=0 and IsInstalled=0")
    if($Download -or $Install -or $Confirm)
    {
        Write-Host " - Found [$($SearchResult.Updates.count)] Updates to Download."
        
        # Get Total Download size    
        $Total = ($SearchResult.Updates | measure-Object -sum MaxDownloadSize).Sum    
        $Current = 0
        
        Write-Host (" - Total of {0:n2} MB to Download." -f ($Total/1mb))   
        Write-Host      
        foreach($Update in $SearchResult.Updates)    
        {        
            write-progress $Update.Title "Total Progress->" -percentcomplete ($Current/$Total*100)        
            $Size = "{0:n2}MB" -f ($Update.MaxDownloadSize/1mb)        
            if($Confirm)        
            {            
                $caption = "Get-WindowsUpdate: $($Update.Title) [$Size]"            
                $message = "Download/Install Update?"            
                $yes = new-Object System.Management.Automation.Host.ChoiceDescription "&Yes;"            
                $no = new-Object System.Management.Automation.Host.ChoiceDescription "&No;"            
                $choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no)            
                $answer = $host.ui.PromptForChoice($caption,$message,$choices,0)            
                if($answer -eq 1){$Current += $Update.MaxDownloadSize;continue}        
            }         
            
            # Check for Eula and Accept in needed        
            if ( $Update.EulaAccepted -eq 0 ) { $Update.AcceptEula() }        
            
            # Add Update to Collection         
            $UpdatesCollection = New-Object -ComObject Microsoft.Update.UpdateColl        
            $UpdatesCollection.Add($Update) | out-null
                
            # Download        
            Write-Host " + Downloading Update $($Update.Title) [$Size]"        
            $UpdatesDownloader = $UpdateSession.CreateUpdateDownloader()        
            $UpdatesDownloader.Updates = $UpdatesCollection        
            $DownloadResult = $UpdatesDownloader.Download()        
            $Message = "   - Download {0}" -f (Get-WIAStatusValue $DownloadResult.ResultCode)        
            Write-Host $message            
            
            # Install        
            if($install)        
            {            
                Write-Host "   - Installing Update"            
                $UpdatesInstaller = $UpdateSession.CreateUpdateInstaller()            
                $UpdatesInstaller.Updates = $UpdatesCollection            
                $InstallResult = $UpdatesInstaller.Install()            
                $Message = "   - Install {0}" -f (Get-WIAStatusValue $DownloadResult.ResultCode)            
                Write-Host $message            
                Write-Host        
            }        
            $Current += $Update.MaxDownloadSize    
        }
    }
    else
    {    
        Write-Host " - Found [$($SearchResult.Updates.count)] Updates."    
        Write-Host (" - Total of {0:n2} MB to Download." -f ($Total/1mb))    
        Write-Host    
        if($FullDetail)    
        {        
            $SearchResult.Updates       
        }    
        else    
        {        
            $SearchResult.Updates | %{$_.Title}    
        }
    }
}
    
