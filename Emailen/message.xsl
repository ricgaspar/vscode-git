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
    		margin:                     0; 
    		padding:                    0; 
    		width:                      100% !important; 
    		overflow-y:                 hidden; 
    		background-color:           #ffffff; 
    
    		font-family:                Arial;
    		vertical-align:             top;
    		border-spacing:             0px;
			}

		</style>
  </head>
  <body>
		<div class="container">
			<div class="content">
				<table border="0">
      	<tr>      		        	
      		<td valign="top" style='width:90%; font-size:12.0pt; margin-right:30px;'>
          	<p>Hi <xsl:value-of select="$To" />,</p>
						<p></p>
      			<p><strong>The password for your VDL Nedcar Windows account <xsl:value-of select="$UID" /> is due to expire in <xsl:value-of select="$Content" /> days.</strong></p>
      			<p></p>
						<p>This password is used to logon to work PCs, access your email, connect to fileshares and printers, Citrix, the VPN and various VDL Nedcar intranet sites.</p>          
      			<p>If you are working on a computer at VDL Nedcar, please press CTRL-ALT-DELETE and choose 'Change password' and follow the instructions to set your new password.</p>
						<p></p>
						<p>If you are working on a VDL Nedcar laptop and you are not located at the Nedcar site, <br />please visit <a href="http://webmail.vdlnedcar.nl/">http://webmail.vdlnedcar.nl</a>, login and follow the prompts.</p>
						<p></p>
						<p>Be aware that your new password must adhere to the rules below.</p>
						<ul>
							<li>Your new password must contain upper and lower case letters</li>
							<li>Your new password must contain a number of special character (like !@#$%^)</li>
							<li>Your new password must not be the same as your previous passwords</li>
							<li>Your new password must not be similar to your username (if any three letters appear in the same order, it will be rejected)</li>
						</ul>
						<p><strong>Failure to change your password will likely result in your inability to perform your job correctly.</strong><br /></p>
						<p>If at any point you have any questions or concerns please open a help desk ticket by replying to this email, or contact IT on +31 (0)46 489 5500.</p>
						<p></p>
      			<Address>Kind regards,<br />
            VDL Nedcar IT<br />
						</Address>
      		</td>
      		<td valign="top" style='font-size:11.0pt; margin-right:30px;'>
      			<xsl:element name="img" use-attribute-sets="image-style"></xsl:element>
      			<p></p>
        		<p><strong>Information Management<br />
        		VDL Nedcar bv</strong></p>
        		<p>Dr. Hub van Doorneweg 1<br />
        		6121 RD Born </p>
						<p>P.O. Box 150<br />
						6130 AD Sittard-Geleen<br /> 
						The Netherlands</p>
						<p></p>
						<p>Phone +31 (0)46 489 5500<br />
						helpdesk@vdlnedcar.nl<br />
						www.vdlnedcar.nl</p>												
        	</td>
      	</tr>
      	</table>						
			</div>			
		</div>
  </body>
</html>
</xsl:template> 
</xsl:stylesheet>