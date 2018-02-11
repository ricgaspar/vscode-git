<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" name="" content="">
	<title>VDL Nedcar Information Services - Rotator</title>
	
	<style type="text/css">
		body, html { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; }
		iframe { border: none; }
	</style>
<script type="text/javascript">
		var Dash = {
    nextIndex: 0,
    dashboards: [    		        
        {url: "http://reports.nedcar.nl/alcreports/ALCFA_R_FAS/mobile.html", time: 60},
        {url: "http://vdlnc01443/weather.php", time: 60},
    ],

    display: function()
    {
        var dashboard = Dash.dashboards[Dash.nextIndex];
        frames["displayArea"].location.href = dashboard.url;
        Dash.nextIndex = (Dash.nextIndex + 1) % Dash.dashboards.length;
        setTimeout(Dash.display, dashboard.time * 1000);
    }
};

window.onload = Dash.display;
</script>
</head>
<body>
<iframe name="displayArea" width="100%" height="100%"></iframe>
</body>
</html>