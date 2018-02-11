
Function Append-Log {
    [CmdletBinding()]
	param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [system.string]
        $Message
	)	
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	Write-Host "[$logtime]: $message"
	Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

Function Start-Executable {
# ---------------------------------------------------------
# Execute a command line program
# This functions sets variable $LASTEXITCODE which contains the exit code of the executed program.
# ---------------------------------------------------------
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[system.string] 
		$FilePath,
	
		[parameter(Mandatory=$True)]
		[String[]]
		$ArgumentList
	)
	  		
	Process {
  	    $command = "& `"$FilePath`" $ArgumentList 2>&1"
        #Execute the command and put the output in an array.
        $console_output_array = invoke-expression $command
		$console_output_string = ''
        for ($i=0; $i -lt $console_output_array.length; $i++) {
            $str = $console_output_array[$i]
            # Skip empty returns
            if($str.Length -lt 0) {
                [string]$i + "=<" + $console_output_array[$i] + ">"
            }
        }
		
		try {
        	#create a single string by joining together the array
        	$console_output_string = [string]::join("`r`n",$console_output_array)
			
			#cleanup string from unwanted characters
        	$console_output_string = $console_output_string -replace '[^\p{L}\p{Nd}/(/}=/_]', ''
		}
		catch {
		}        
        
        return $console_output_string
	}
}

$SCRIPTLOG = "C:\Windows\Patchlog\_CLIENTREPAIR_.log"
$PSScriptName = $myInvocation.MyCommand.Name
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
if(Test-Path $SCRIPTLOG) { Remove-Item $SCRIPTLOG -Force -ErrorAction SilentlyContinue }
Append-Log "Started script $PSScriptName from $PSScriptRoot"
Append-Log "Log file: $SCRIPTLOG"

$ccmsetup = 'C:\Windows\ccmsetup\ccmsetup.exe '
$uninstall = '/uninstall'

$install = '/mp:s007.nedcar.nl SMSSITECODE=VNB FSP=s008.nedcar.nl SMSCACHESIZE=10240 CCMENABLELOGGING=TRUE CCMLOGMAXHISTORY=2'

Append-Log "Start uninstalling CCM agent."
$temp = Start-Executable -FilePath $ccmsetup -ArgumentList $uninstall

Append-Log "Waiting 10 minutes to complete."
Start-Sleep -s (60 * 10)

Remove-Item -Path 'C:\CCM' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'C:\Windows\CCM' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'C:\Windows\ccmcache' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'D:\ccmcache' -Recurse -Force -ErrorAction SilentlyContinue

Append-Log "Start installing CCM agent."
$temp = Start-Executable -FilePath $ccmsetup -ArgumentList $install

Append-Log "Done re-installing CCM agent."

