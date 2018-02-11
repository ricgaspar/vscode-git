# ---------------------------------------------------------
#
# XMPP Functions
# Marcel Jussen
# 10-3-2011
#
# ---------------------------------------------------------

# Download XMPP SDK from http://www.ag-software.de/index.php?page=agsxmpp-sdk   

function Send-XmppMessage {
# ---------------------------------------------------------
# Send a Jabber/XMPP message
#
# Usage:
#
# Send a broadcast message to all users on a XMPP server
# Send-XmppMessage "kpn01@s001" "test" "all@broadcast.s001" "-*- All XMPP users broadcast test -*- Please ignore this message. :-P"
#
# Send a broadcast message to a group/roster on a XMPP server
# Send-XmppMessage "kpn01@s001" "test" "Openfire-DistribGroup@broadcast.s001" "-*- Group broadcast test  -*- Please ignore this message :-P"
#
# Send a message to a user on a XMPP server
# Send-XmppMessage "kpn01@s001" "test" "kpn03@s001" "-*- User message test  -*- Please ignore this message :-P"
# ---------------------------------------------------------
	param (   
		$From = $( Throw "You must specify a Jabber ID for the sender." ),   
		$Password, # Leave blank to be prompted for password   
		$To = $( Throw "You must specify a Jabber ID for the recipient." ),   
		$Body = $( Throw "You must specify a body for the message." )   
	)   

	# This function reads a string from the host while masking with *'s.  
	function Read-HostMasked( [string]$prompt="Password" ) {  
		$password = Read-Host -AsSecureString $prompt;   
		$BSTR = [System.Runtime.InteropServices.marshal]::SecureStringToBSTR($password);  
		$password = [System.Runtime.InteropServices.marshal]::PtrToStringAuto($BSTR);  
		[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR);  
	return $password;  
	}  

	# Set path accordingly.  	
	$assemblyPath = $(resolve-path C:\Scripts\Secdump\PS\agsXMPP.dll)  
	[void][reflection.assembly]::LoadFrom( $assemblyPath )  
	$jidSender		= New-Object agsxmpp.jid( $From )  
	$jidReceiver	= New-Object agsxmpp.jid ( $To )  
	$xmppClient		= New-Object agsxmpp.XmppClientConnection( $jidSender.Server )  
	$Message		= New-Object agsXMPP.protocol.client.Message( $jidReceiver, $Body )  

	# The following switches may assist in troubleshooting connection issues.  
	# If SSL and StartTLS are disabled, then you can use a network sniffer to inspect the XML  
	# $xmppClient.UseSSL = $TRUE
	# $xmppClient.UseStartTLS = $TRUE

	# Since this function is only used to send a message, we don't care about doing the   
	# normal discovery and requesting a roster.  Leave disabled to quicken the login period.  
	$xmppClient.AutoAgents = $FALSE  
	$xmppClient.AutoRoster = $FALSE  

	# Use SRV lookups to determine correct XMPP server if different from the server  
	# portion of your JID.  e.g. user@gmail.com, the server is really talk.google.com  
	$xmppClient.AutoResolveConnectServer     = $TRUE  
	if ( !$password ) { $password = Read-HostMasked }  
    
	# Open connection, then wait for it to be authenticated  	
	$temp = $xmppClient.Open( $jidSender.User, $Password )  
	while ( !$xmppClient.Authenticated ) {  
		$xmppstate = $xmppClient.XmppConnectionState  
		# Write-Verbose $xmppstate
		Start-Sleep 1  
	}  
	# If server disconnects you, try enabling this  	
	$xmppClient.SendMyPresence()  
	Start-Sleep 3
	
	# Here we go
	$xmppClient.Send( $Message )  
	
	# Send is asynchronous, so we must wait a second before closing the connection  
	Start-Sleep 3  
	$xmppClient.Close()  
}

