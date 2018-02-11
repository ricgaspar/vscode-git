
<%@ Language="VBScript" %>
<%
	Option Explicit
	Response.ContentType = "text/xml"
	Response.Charset = "utf-8"
%>

<%       
  Dim cn 
	Dim rs 
	Dim xmlDoc 

	Set cn=Server.CreateObject("ADODB.Connection")
	Set rs=Server.CreateObject("ADODB.Recordset") 
  cn.Open "Provider=SQLOLEDB.1;Password=weather;Persist Security Info=True;User ID=wu_service;Initial Catalog=WU;Data Source=vs004.nedcar.nl"
  rs.CursorLocation = 3
	rs.Open "Select * from [WU].[dbo].[vw_WU_Forecast]",cn	
  
  Response.Write "<data>"    		
  
	Do While Not rs.EOF
		Response.Write "<day>"
		Response.Write "<Systemname>" + rs("Systemname") + "</Systemname>"
		Response.Write "<Domainname>" + rs("Domainname") + "</Domainname>"
		Response.Write "<PolDateTime>" + rs("PolDateTime") + "</PolDateTime>"
		
		Response.Write "<conditions>" + rs("conditions") + "</conditions>"
		Response.Write "<icon>" + rs("icon") + "</icon>"
		Response.Write "<day>" + rs("day") + "</day>"
		Response.Write "<month>" + rs("month") + "</month>"
		Response.Write "<year>" + rs("year") + "</year>"
		Response.Write "<weekday>" + rs("weekday") + "</weekday>"
		Response.Write "<weekday_short>" + rs("weekday_short") + "</weekday_short>"
		Response.Write "<high_celcius>" + rs("high_celcius") + "</high_celcius>"
		Response.Write "<low_celcius>" + rs("low_celcius") + "</low_celcius>"
		Response.Write "<avehumidity>" + rs("avehumidity") + "</avehumidity>" 
		Response.Write "<qpf_allday_mm>" + rs("qpf_allday_mm") + "</qpf_allday_mm>"		
		Response.Write "<maxwind_kph>" + rs("maxwind_kph") + "</maxwind_kph>"
		Response.Write "<maxwind_dir>" + rs("maxwind_dir") + "</maxwind_dir>"
		Response.Write "<maxwind_degrees>" + rs("maxwind_degrees") + "</maxwind_degrees>"
		Response.Write "<avewind_kph>" + rs("avewind_kph") + "</avewind_kph>" 
		Response.Write "<avewind_dir>" + rs("avewind_dir") + "</avewind_dir>"
		Response.Write "<avewind_degrees>" + rs("avewind_degrees") + "</avewind_degrees>"	
		
		Response.Write "</day>"
		rs.MoveNext
	Loop
	
	
	
  Response.Write "</data>"    		
	rs.Close
	cn.Close

	Set rs = Nothing
	Set cn = Nothing
       
%>