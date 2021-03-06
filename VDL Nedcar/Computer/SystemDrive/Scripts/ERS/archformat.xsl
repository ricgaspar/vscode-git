<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output media-type="xml" omit-xml-declaration="yes" />
	<xsl:param name="To"/>
	<xsl:param name="Content"/>
	<xsl:param name="Logo"/>

	<xsl:attribute-set name="image-style">
		<xsl:attribute name="style">float:left; margin-right:0px; margin-bottom:0px</xsl:attribute>
		<xsl:attribute name="alt">green</xsl:attribute>
		<xsl:attribute name="src">
			<xsl:value-of select="$Logo" />
		</xsl:attribute>
		<xsl:attribute name="title">SP logo</xsl:attribute>
	</xsl:attribute-set>
	
	<xsl:template match="/">
		<html>
			<head>
				<title>Exchange archive distribution.</title>
			</head>
			<body>
				<div width="800px">
					<p>Hi <xsl:value-of select="$To" />,</p>
					<p>Please check the mailbox distribution counters in your Exchange archive databases. If the maximum number of mailboxes per archive database is reached, no new archives can be created by ERS.<br />
					   The maximum number of mailboxes per archive database is controlled on SQL server VS064, database SECDUMP, table Exchange_Default_ARCHDB.<br/>
					   If you add a new Exchange archive database or wish to change the number of mailboxes per archive database, please change the forementioned SQL table.</p>
					<xsl:element name="img" use-attribute-sets="image-style"></xsl:element>
					<Address>
						This message was automatically generated. Please do not reply to this email.<br />
						VDL Nedcar - Information Systems<br />
					</Address>					
				</div>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>
