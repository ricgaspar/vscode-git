<?xml version="1.0"?>

<xsl:stylesheet version="1.0" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns:m="http://schemas.microsoft.com/office/2004/12/omml" xmlns="http://www.w3.org/TR/REC-html40" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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
			@font-face {font-family:"Cambria Math";	panose-1:2 4 5 3 5 4 6 3 2 4;}
			@font-face {font-family:Calibri; panose-1:2 15 5 2 2 2 4 3 2 4;}
			body { margin:0; padding:0; width:100%; overflow-y:hidden; background-color:#ffffff; font-family:Calibri; vertical-align:top; border-spacing: 0px;}
			
			p.MsoNormal, li.MsoNormal, div.MsoNormal { margin:0cm; margin-bottom:.0001pt; font-size:11.0pt; font-family:"Calibri",sans-serif; mso-fareast-language:EN-US;}
			a:link, span.MsoHyperlink { mso-style-priority:99; color:#0563C1; text-decoration:underline;} 
			a:visited, span.MsoHyperlinkFollowed { mso-style-priority:99; color:#954F72; text-decoration:underline; }
			span.EmailStyle17 {mso-style-type:personal-compose; font-family:"Calibri",sans-serif; color:windowtext;}
			.MsoChpDefault {mso-style-type:export-only;	font-family:"Calibri",sans-serif; mso-fareast-language:EN-US;}
			@page WordSection1 {size:612.0pt 792.0pt; margin:70.85pt 70.85pt 70.85pt 70.85pt;}
			div.WordSection1 {page:WordSection1;}
		</style>
  </head>
  <body>
		<div class="container">
			<div class="content">
          	<p class='MsoNormal'>Geachte <xsl:value-of select="$To"/>,<br /><br/></p>			
      		<p class='MsoNormal'>VDL Nedcar IT controleert regelmatig de applicaties die op VDL Nedcar werkplekken worden geinstalleerd. Onderstaande applicaties hebben we aangetroffen op werkplekken die U in gebruik heeft.<br /><br/></p>
      		
			<p class='MsoNormal'>Volgens onze informatie heeft VDL Nedcar voor deze software GEEN licenties.<br /><br/></p>  
			
			<table class='MsoNormalTable' border='0' cellspacing='0' cellpadding='0' width='1704' style='width:1278.0pt;border-collapse:collapse'>
			<tr style='height:13.0pt'>
				<td width='276' valign='top' style='width:207.0pt;background:#4472C4;padding:0cm 3.5pt 0cm 3.5pt;height:13.0pt'>
					<p class='MsoNormal'><span style='color:white;mso-fareast-language:NL'>Titel<o:p></o:p></span></p>
				</td>
				<td width='120' valign='top' style='width:90.0pt;background:#4472C4;padding:0cm 3.5pt 0cm 3.5pt;height:13.0pt'>
					<p class='MsoNormal'><span style='color:white;mso-fareast-language:NL'>Computernaam<o:p></o:p></span></p>
				</td>
				<td width='151' valign='top' style='width:113.0pt;background:#4472C4;padding:0cm 3.5pt 0cm 3.5pt;height:13.0pt'>
					<p class='MsoNormal'><span style='color:white;mso-fareast-language:NL'>SCCM Top User<o:p></o:p></span></p>
				</td>
				<td width='261' valign='top' style='width:196.0pt;background:#4472C4;padding:0cm 3.5pt 0cm 3.5pt;height:13.0pt'>
					<p class='MsoNormal'><span style='color:white;mso-fareast-language:NL'>AD Last logon User<o:p></o:p></span></p>
				</td>
				<td width='219' valign='top' style='width:164.0pt;background:#4472C4;padding:0cm 3.5pt 0cm 3.5pt;height:13.0pt'>
					<p class='MsoNormal'><span style='color:white;mso-fareast-language:NL'>Email adres<o:p></o:p></span></p>
				</td>
				<td width='43' valign='top' style='width:32.0pt;background:#4472C4;padding:0cm 3.5pt 0cm 3.5pt;height:13.0pt'>
					<p class='MsoNormal'><span style='color:white;mso-fareast-language:NL'>Tel<o:p></o:p></span></p>
				</td>
				<td width='204' valign='top' style='width:153.0pt;background:#4472C4;padding:0cm 3.5pt 0cm 3.5pt;height:13.0pt'>
					<p class='MsoNormal'><span style='color:white;mso-fareast-language:NL'>Manager<o:p></o:p></span></p>
				</td>
				<td width='288' valign='top' style='width:216.0pt;background:#4472C4;padding:0cm 3.5pt 0cm 3.5pt;height:13.0pt'>
					<p class='MsoNormal'><span style='color:white;mso-fareast-language:NL'>ISP_Department_Name<o:p></o:p></span></p>
				</td>
				<td width='143' valign='top' style='width:107.0pt;background:#4472C4;padding:0cm 3.5pt 0cm 3.5pt;height:13.0pt'>
					<p class='MsoNormal'><span style='color:white;mso-fareast-language:NL'>ISP Department_nr<o:p></o:p></span></p>
				</td>
			</tr>
			</table>
			
			<xsl:value-of select="$Content" />
			
      		<p class='MsoNormal'><br/>U wordt daarom vriendelijk verzocht deze software van de genoemde computers te verwijderen binnen de termijn van 1 week na ontvangst van deze email.<br/>
			   Mocht het zijn dat deze software onontbeerlijk is dan verzoek ik U om contact met uw manager op te nemen en voor de juiste licenties te zorgen.<br/><br/></p>			
      		<p class='MsoNormal'>Met vriendelijke groet,<br />
			Marcel Sieliakus<br />
			VDL Nedcar IT<br />
			</p>
      		</div>			
		</div>
  </body>
</html>
</xsl:template> 
</xsl:stylesheet>