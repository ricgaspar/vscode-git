<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output media-type="xml" omit-xml-declaration="yes" />
	<xsl:param name="To"/>
	<xsl:param name="UCount"/>
	<xsl:param name="Computername"/>
    <xsl:param name="Deadline"/>
    <xsl:param name="SCUpdates"/>
    <xsl:attribute-set name="screen-style">
		<xsl:attribute name="style">width:149 height:67; float:left; margin-right:0px; margin-bottom:0px</xsl:attribute>
		<xsl:attribute name="src">
			<xsl:value-of select="$SCUpdates" />
		</xsl:attribute>
		<xsl:attribute name="title">Software Center screenshot</xsl:attribute>
	</xsl:attribute-set>
	<xsl:param name="Logo"/>
	<xsl:attribute-set name="image-style">
		<xsl:attribute name="style">width:149 height:67; float:left; margin-right:0px; margin-bottom:0px</xsl:attribute>
		<xsl:attribute name="src">
			<xsl:value-of select="$Logo" />
		</xsl:attribute>
		<xsl:attribute name="title">VDL Nedcar logo</xsl:attribute>
	</xsl:attribute-set>
	<xsl:template match="/">
		<html>
			<head>
				<title>Herinnering: Er staan software updates klaar voor uw computer.</title>
				<style type="text/css">
                body {
				    font-family: Verdana,Arial,Tahoma,"Trebuchet MS",sans-serif;
				    font-size: 10pt;
    		        line-height: 1.0em;
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
						<p>Geachte <xsl:value-of select="$To" />,
						</p>
						<p>
							Er staan <xsl:value-of select="$UCount" /> software updates gereed in het Software Center die op de computer <strong><xsl:value-of select="$Computername" /></strong> ge&#239;nstalleerd moeten worden. Deze software updates zijn noodzakelijk voor de stabiliteit en beveiliging van deze computer.                            
                            <br />U heeft 7 dagen de tijd om de updates op een door u zelf gekozen moment te installeren en daarna uw computer te herstarten. <i>De deadline voor deze updates is <strong><xsl:value-of select="$Deadline" /></strong></i>
                            <br />Na de deadline worden de updates automatisch ge&#239;nstalleerd en wordt uw computer herstart.
						</p>
						<p>
							<u>Hoe kunt U deze software updates zelf installeren op een door u zelf gekozen moment?</u>
                            <br />
                            <br />Sla eerst uw werk op en sluit alle applicaties!
							<br />Ga naar het <strong><i>Start</i></strong> menu, open <strong><i>Microsoft System Center</i></strong> en selecteer <strong><i>Software Center</i></strong>. In het Software Center, kies voor de tab <strong><i>Updates</i></strong>.
                            <br />In het Update scherm ziet u de lijst met updates die ge&#239;nstalleerd moeten worden. Klik rechts op de knop <strong><i>'Install All'</i></strong>. De installatie wordt gestart en kan enige tijd duren.                            
							<br />
                            <br />
                            <xsl:element name="img" use-attribute-sets="screen-style"></xsl:element>
                            <br />
							<br />Als de installatie van software updates voltooid is volgt een mededeling dat de computer herstart moeten worden. Herstart dan de computer.
						</p>
						<p>
                            Met vriendelijke groeten,							
							<br />VDL Nedcar IT Helpdesk						
						</p>
						<xsl:element name="img" use-attribute-sets="image-style"></xsl:element>
						<p style='font-size: 8pt;'>
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