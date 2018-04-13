
function Set-MSMQQueueRights {
	param (
		[string]$QueueName,
		[string]$ComputerName = ".",
		[string]$Trustee,
		$AccessRights,
		$AccessControl
	)
	
	$script = {
        param(
			[string]$qName,
			[string]$qTrustee, 
			$qRights,
			$qControl
		)
	
		[Void]([Reflection.Assembly]::LoadWithPartialName('System.Messaging'))
		$msmq = [System.Messaging.MessageQueue]
    	if($msmq::Exists($qName)) {
			$qObject = New-Object System.Messaging.MessageQueue $qName
			$qObject.SetPermissions($qTrustee, $qRights, $qControl)
		}
	}	
	Invoke-Command -ComputerName $ComputerName -ScriptBlock $script -ArgumentList $QueueName, $Trustee, $AccessRights, $AccessControl
}

function Create-MSMQMessageQueue {
    param (
		[string]$QueueName,
		[string]$ComputerName = ".",
		[string]$Trustee,
		$AccessRights,
		$AccessControl
	)

    $script = {
        param(
			[string]$qName,
			[string]$qTrustee, 
			$qRights,
			$qControl
		)

        [Void]([Reflection.Assembly]::LoadWithPartialName('System.Messaging'))
        $msmq = [System.Messaging.MessageQueue]
        if($msmq::Exists($qName)) {            
        } else {            
			# Create private transactional queue			
            $qObject = $msmq::Create($qName, $true)     
			
			# Enable Journal			
			$qObject.UseJournalQueue = $TRUE
						
			# Set queue security
			if($qTrustee) {
				$qObject.SetPermissions($qTrustee, $qRights, $qControl)
			} 
        }
    }
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $script -ArgumentList $QueueName, $Trustee, $AccessRights, $AccessControl
}

function Delete-MSMQMessageQueue {
    param(
		[string]$QueueName,
		[string]$ComputerName = "."
	)

    $script = {
        param($qName)
        [void]([Reflection.Assembly]::LoadWithPartialName('System.Messaging'))
        $msmq = [System.Messaging.MessageQueue]		        
        if($msmq::Exists($qName)) {
			$qObject = $msmq::Delete($qName)             
        } else {
            echo "'$qName' doesn't exist."
        }
    }
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $script -ArgumentList $QueueName
}

function Write-MSMQMessageTransactional {
	param(
		[string]$QueueName,
		[string]$ComputerName = ".",
		[string]$Message,
		[string]$Label
	)
	
	$script = {
		param (
			$qName, 
			$qMessage, 
			$qLabel
		)
		[void]([Reflection.Assembly]::LoadWithPartialName('System.Messaging'))
    	$queue = new-object System.Messaging.MessageQueue $qName
     	$utf8 = new-object System.Text.UTF8Encoding

     	$tran = new-object System.Messaging.MessageQueueTransaction
     	$tran.Begin()
     	$msgBytes = $utf8.GetBytes($qMessage)
     	$msgStream = new-object System.IO.MemoryStream
     	$msgStream.Write($msgBytes, 0, $msgBytes.Length)

		$msg = new-object System.Messaging.Message
		$msg.BodyStream = $msgStream   
		if ($qLabel -ne $null) {
			$msg.Label = $qLabel
		}
     	$queue.Send($msg, $tran)
		$tran.Commit()     	
	}
	
	Invoke-Command -ComputerName $ComputerName -ScriptBlock $script -ArgumentList $QueueName, $Message, $Label
}

function Read-MSMQMessagesFromQueue {
	param (
		[string]$QueueName,
		[string]$ComputerName = "."
	)
	
	$script = {
		param (
			$qName
		)		
		[Void]([Reflection.Assembly]::LoadWithPartialName('System.Messaging'))
		$queue = New-Object System.Messaging.MessageQueue $qName	
		$msgs = $queue.GetAllMessages()		
		$utf8  = new-object System.Text.UTF8Encoding
		foreach ($msg in $msgs) {      		
      		$utf8.GetString($msg.BodyStream.ToArray())
  		}
		
		$msgs
	}	
	Invoke-Command -ComputerName $ComputerName -ScriptBlock $script -ArgumentList $QueueName
}

Function Purge-MSMQMessagesFromQueue {
	param (
		[string]$QueueName,
		[string]$ComputerName = "."
	)	
	$script = {
		param (
			$qName
		)	
		[Void]([Reflection.Assembly]::LoadWithPartialName('System.Messaging'))
		$queue = New-Object System.Messaging.MessageQueue $qName
		$queue.Purge() 		
	}
	Invoke-Command -ComputerName $ComputerName -ScriptBlock $script -ArgumentList $QueueName
}

#-------------------------
#Test the above functions 
#-------------------------
cls
[Void]([Reflection.Assembly]::LoadWithPartialName('System.Messaging'))

$ComputerName = 'vdlnc00261t'
$queueName = ".\Private$\testqueue"

# Purge the entire queue
# Purge-MSMQMessagesFromQueue -Queuename $QueueName -Computername $ComputerName

# Delete a MSMQ queue
# Delete-MSMQMessageQueue -Queuename $QueueName -Computername $ComputerName

$MSMQTrustee = 'NEDCAR\MJ90624'
$MSMQAccessRights = [System.Messaging.MessageQueueAccessRights]::FullControl
$MSMQAccessControl = [System.Messaging.AccessControlEntryType]::Allow
Create-MSMQMessageQueue -Queuename $QueueName -Computername $ComputerName -Trustee $MSMQTrustee -AccessRights $MSMQAccessRights -AccessControl $MSMQAccessControl

$MSMQTrustee = 'NEDCAR\TEST.USER1'
$MSMQAccessRights = [System.Messaging.MessageQueueAccessRights]::FullControl
$MSMQAccessControl = [System.Messaging.AccessControlEntryType]::Allow
Set-MSMQQueueRights -Queuename $QueueName -Computername $ComputerName -Trustee $MSMQTrustee -AccessRights $MSMQAccessRights -AccessControl $MSMQAccessControl

$label = 'MyTestLabel'
$message = "this is is a transactional test message"
Write-MSMQMessageTransactional -Queuename $queueName -Computername $ComputerName -Message $message -Label $Label

$utf8  = new-object System.Text.UTF8Encoding
$msgs = Read-MSMQMessagesFromQueue -Queuename $queueName -Computername $ComputerName 
foreach ($msg in $msgs) {		
	$msg
	$utf8.GetString($msg.BodyStream.ToArray())
}