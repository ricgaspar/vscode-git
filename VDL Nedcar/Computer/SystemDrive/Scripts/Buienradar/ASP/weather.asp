
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
	rs.Open "Select * from [WU].[dbo].[vw_WU_Observation]",cn	
  
  Response.Write "<data>"    		
  
	Do While Not rs.EOF			
		Response.Write "<Systemname>" + rs("Systemname") + "</Systemname>"
		Response.Write "<Domainname>" + rs("Domainname") + "</Domainname>"
		Response.Write "<PolDateTime>" + rs("PolDateTime") + "</PolDateTime>"
		Response.Write "<station_id>" + rs("station_id") + "</station_id>"
		Response.Write "<full>" + rs("full") + "</full>"
		Response.Write "<latitude>" + rs("latitude") + "</latitude>"
		Response.Write "<longitude>" + rs("longitude") + "</longitude>"
		Response.Write "<elevation>" + rs("elevation") + "</elevation>"		
		Response.Write "<weather>" + rs("weather") + "</weather>"
		Response.Write "<temp_c>" + rs("temp_c") + "</temp_c>"
		Response.Write "<relative_humidity>" + rs("relative_humidity") + "</relative_humidity>"
		Response.Write "<wind_dir>" + rs("wind_dir") + "</wind_dir>" 
		Response.Write "<wind_degrees>" + rs("wind_degrees") + "</wind_degrees>"
		Response.Write "<wind_kph>" + rs("wind_kph") + "</wind_kph>"
		Response.Write "<wind_gust_kph>" + rs("wind_gust_kph") + "</wind_gust_kph>"
		Response.Write "<pressure_mb>" + rs("pressure_mb") + "</pressure_mb>"
		Response.Write "<dewpoint_c>" + rs("dewpoint_c") + "</dewpoint_c>"
		Response.Write "<feelslike_c>" + rs("feelslike_c") + "</feelslike_c>" 
		Response.Write "<visibility_km>" + rs("visibility_km") + "</visibility_km>"
		Response.Write "<precip_1hr_metric>" + rs("precip_1hr_metric") + "</precip_1hr_metric>"
		Response.Write "<precip_today_metric>" + rs("precip_today_metric") + "</precip_today_metric>"
		Response.Write "<icon>" + rs("icon") + "</icon>"
		Response.Write "<icon_url>" + rs("icon_url") + "</icon_url>"				
		rs.MoveNext
	Loop
	
	
	
  Response.Write "</data>"    		
	rs.Close
	cn.Close

	Set rs = Nothing
	Set cn = Nothing
       
%>