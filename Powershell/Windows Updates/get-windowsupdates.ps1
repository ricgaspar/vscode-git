Function Get-WindowsUpdates {
<#
	.SYNOPSIS
 	Gather all windows updates installed.
  
	.DESCRIPTION
	This function will get all currently installed updates on the local server.
	The particularity of this function is that it returns an Object which can be used in order to specefic filtering.  
  
	.EXAMPLE
  
	$updates = Get-WindowsUpdates
	$updates | select hotfixid  
#>
	[cmdletBinding()]
 	Param(  
 	)
 	Begin {  
 	}
 	Process{
 		$Psupdates = @()
 		$Session = New-Object -ComObject Microsoft.Update.Session
 		$Searcher = $Session.CreateUpdateSearcher() 
 		$HistoryCount = $Searcher.GetTotalHistoryCount()
 		if (!($HistoryCount)){
 			write-warning -Message "No updates found. Quiting."
 			break
 		}
		$Computername = $env:COMPUTERNAME
 		$AllUpdates = $Searcher.QueryHistory(0,$HistoryCount)
 		$i = 0
 		While ($i -ne $HistoryCount){
			$Update = @()
			
			$psOperation = $Allupdates.Item($i).Operation
 			$PsResultCode = $Allupdates.Item($i).ResultCode
 			$PsHResult = $Allupdates.Item($i).HResult
 			$PSDate = $Allupdates.Item($i).Date
 			$PsUpdateIdentity = $Allupdates.Item($i).UpdateIdentity
 			$PsTitle = $Allupdates.Item($i).Title
 			$PsDescription = $Allupdates.Item($i).Description
 			$PsUnmappedResultCode = $Allupdates.Item($i).UnmappedResultCode
 			$PsClientApplicationID = $Allupdates.Item($i).ClientApplicationID
 			$PsServerSelection = $Allupdates.Item($i).ServerSelection
 			$PsServiceID = $Allupdates.Item($i).ServiceID
 			$PsUninstallationSteps = $Allupdates.Item($i).UninstallationSteps
 			$PsUninstallationNotes = $Allupdates.Item($i).UninstallationNotes
 			$PsSupportUrl = $Allupdates.Item($i).SupportUrl
 			$PsCategories = $Allupdates.Item($i).Categories
 			$PsDate = $Allupdates.Item($i).date
 			$HotFixID = $PsTitle | Select-String -Pattern 'KB\d*' -AllMatches | % { $_.Matches } | % {$_.value}
 
 			$Properties = [Ordered]@{ "Computername"=$Computername;`
			    "HotFixID"=$HotFixID;`
 				"Operation"=$psOperation; ` 
 				"ResultCode" = $PsResultCode; `
 				"HResult" = $PsHResult; `
 				"Date" = $PSDate; `
 				"UpdateIdentity" = $PsUpdateIdentity; `
 				"Title" = $PsTitle; `
 				"Description" = $PsDescription ;`
 				"UnmappedResultCode" = $PsUnmappedResultCode; `
 				"ClientApplicationID" = $PsClientApplicationID; `
 				"ServerSelection" = $PsServerSelection; `
 				"ServiceID" = $PsServiceID ;
 				"UninstallationSteps" = $PsUninstallationSteps; `
 				"UninstallationNotes" = $PsUninstallationNotes; `
 				"SupportUrl" = $PsSupportUrl; `
 				"Categories" = $PsCategories;`
 			}
 			$Update = New-Object -TypeName PSObject -Property $Properties
  
 			$PSUpdates += $Update
 			$i++
 		}
  
 	}#EndProcess
	End{
 		Return $Psupdates
 	}
}

# Getting the update locally
# $updates = Get-WindowsUpdates
# $updates | select HotFixID,Date,Title

#Getting the updates from a remote computer 
$InstalledUpdates = Invoke-Command -ScriptBlock ${function:Get-WindowsUpdates} -ComputerName "vdlnc00998" -ErrorAction stop
$InStalledUpdates | Select Computername,HotFixID,Title