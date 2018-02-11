<?xml version="1.0"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 
<xsl:output media-type="xml" omit-xml-declaration="yes" />
<xsl:param name="To"/>
<xsl:param name="Content"/>
<xsl:param name="UID"/>
<xsl:param name="Logo"/>
	
<xsl:attribute-set name="image-style">
  <xsl:attribute name="style">width:149 height:67; float:left; margin-right:0px; margin-bottom:0px</xsl:attribute>  
  <xsl:attribute name="src"><xsl:value-of select="$Logo" /></xsl:attribute>
  <xsl:attribute name="title">VDL Nedcar logo</xsl:attribute>
</xsl:attribute-set>

<xsl:template match="/">
	<html>
  	<head>
    	<title>Your password is due to expire!</title>
      <style type="text/css">			
			body {
				font-family: Verdana,Arial,Tahoma,"Trebuchet MS",sans-serif;
				font-size: 10pt;
    		line-height: 1.2em;
    		margin-right: 10px;
    		margin-left: 10px;
    		margin-top: 0px;
    		margin-bottom: 0px;
    		padding: 0; 
    		width: 100% !important; 
    		overflow-y: hidden; 
    		background-color: #ffffff;     		
    		vertical-align: top;
    		border-spacing: 0px;
			}
			
		</style>
  </head>
  <body>
		<div class="container">
			<div id="content">
				<p>Dear Mr./Mrs. <xsl:value-of select="$To" />,</p>
				<p><strong>The password for your VDL Nedcar Windows domain account '<xsl:value-of select="$UID" />' is due to expire in <xsl:value-of select="$Content" /> days.</strong>
					<br />This account is used to logon to work PCs, access your email, connect to office shares and printers, VDL Nedcar Citrix, VDL Nedcar VPN and various intranet sites.
				</p>				
				<p>					
					<i>How to change your domain password?</i>
					<br />If you are working on an office computer at VDL Nedcar, please press CTRL-ALT-DELETE and choose 'Change password' and follow the instructions to set your new password.
					<br />					
					<br />If you are presently not located at the VDL Nedcar site, please access VDL Nedcar Citrix at <a href="https://desktop.vdlnedcar.nl/">https://desktop.vdlnedcar.nl</a>, login using your current id, password and a SAS token.
					<br />When in Citrix, please follow the instructions as described in the email attachment <i>'Change Windows password in Citrix.pdf'</i>.
				</p>
				<p>Be aware that your new password must adhere to the following password complexity rules.
					<ul style='line-height: 0.2em'>
						<li style='line-height: 1.2em'>Your new password must not be the same as your previous passwords.</li>
						<li style='line-height: 1.2em'>Your new password must be at least 8 characters in length.</li>
						<li style='line-height: 1.2em'>Your new password must contain at least one capital and lower-case character.</li>
						<li style='line-height: 1.2em'>Your new password must contain at least one base 10 digit (0 through 9).</li>
						<li style='line-height: 1.2em'>Your new password must contain at least one non-alphanumeric character.</li>
					</ul>
				</p>				
				<p>
					<i>Reminder: If a smartphone was provided to you with access to your VDL Nedcar email, please make sure to change the password for your email account on your smartphone as well or else mail synchronisation will fail.</i>
				</p>
				<p><strong>Failure to change your password will likely result in your inability to perform your job correctly.</strong>
					<br />If at any point you have any questions or concerns please open a helpdesk ticket by replying to this email, or contact VDL Nedcar IT on (+31) 46 489 5500					
				</p>
      	<p>
      		Kind regards,
      		<br />VDL Nedcar IT Helpdesk
      	</p>
        <xsl:element name="img" use-attribute-sets="image-style"></xsl:element>
        <p style='font-size: 10pt;'>
        	<strong>Information Management
        	<br />VDL Nedcar bv</strong>
        	<br /> 
        	<br />Dr. Hub van Doorneweg 1
        	<br />6121 RD Born
					<br />P.O. Box 150
					<br />6130 AD Sittard-Geleen
					<br />The Netherlands
					<br />
					<br />Phone +31 (0)46 489 5500
					<br />helpdesk@vdlnedcar.nl
					<br />www.vdlnedcar.nl
				</p>				
			</div>			
		</div>
  </body>
</html>
</xsl:template> 
</xsl:stylesheet>