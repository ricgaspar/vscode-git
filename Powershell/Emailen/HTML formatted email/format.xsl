<?xml version="1.0"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 
<xsl:output media-type="xml" omit-xml-declaration="yes" />
    <xsl:param name="To"/>
    <xsl:param name="Content"/>
	<xsl:param name="Logo"/>

	
<xsl:attribute-set name="image-style">
  <xsl:attribute name="style">float:left; margin-right:0px; margin-bottom:0px</xsl:attribute>
  <xsl:attribute name="alt">green</xsl:attribute>
  <xsl:attribute name="src"><xsl:value-of select="$Logo" /></xsl:attribute>
  <xsl:attribute name="title">SP logo</xsl:attribute>
</xsl:attribute-set>

	
    <xsl:template match="/">
        <html>
            <head>
                <title>Your Password is due to Expire!</title>
            </head>
            <body>
            <div width="400px">
                <p>Hi <xsl:value-of select="$To" />,</p>
                <p></p>
                <p>Your windows password is due to expire in <xsl:value-of select="$Content" /> days.</p>
                <p></p>
				<p>This password is used to access your email, logon to work PCs, connect to the vpn, and various intranet sites.</p>
				<p></p>
				<p>If you are working on an Office computer, please press CTRL-ALT-DELETE and choose change password. Follow the instructions to set your new password. </p>
				<p></p>
				<p>If you are on a Sales laptop, please visit <a href="https://webmail.mydomain.com/">https://webmail.mydomain.com</a>, login and follow the prompts.</p>
				<p></p>
				<ul>
					<li>Must contain upper and lower case letters</li>
					<li>Must contain a number or special character (like !@#$%^)</li>
					<li>Must not be the same as your previous passwords</li>
					<li>Must not be similar to your username (if any three letters appear in the same order, it will be rejected)</li>
				</ul>
				<p><strong>Failure to change your password will likely result in your inability to perform your job correctly.</strong><br /></p>
				<p>If any point you have any questions or concerns please open a help desk ticket by replying to this email, or contact IT on (08) 5555 5555</p>
				<p></p>
            <Address>
			Many thanks,<br />	
            IT Team<br />
			</Address>
			<xsl:element name="img" use-attribute-sets="image-style"></xsl:element>
		</div>
      </body>
    </html>
    </xsl:template> 
</xsl:stylesheet>