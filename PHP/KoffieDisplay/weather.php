<!DOCTYPE html>
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" name="" content="">
		<title>VDL Nedcar Information Services Weather</title>
		<link rel="stylesheet" href="/css/normalize.css">		
		<link rel="stylesheet" href="/css/progressbar.css">
		
		<link rel="stylesheet" type="text/css" href="/css/weather.css" />
		<link rel="stylesheet" type="text/css" href="/css/css3clock.css" />
						
		<script src="/js/jquery-1.11.3.min.js"></script>		
		<script src="/js/jquery.js" type="text/javascript"></script>
		<script src="/js/modernizr.js" type="text/javascript"></script>
		
		<script>
		$(document).ready(function() {
			if(!Modernizr.meter){
				alert('Sorry your brower does not support HTML5 progress bar');
			} else {
				var progressbar = $('#progressbar'),
					max = progressbar.attr('max'),					
					time = 1000,
			        value = progressbar.val();

			    var loading = function() {
			        value += 1;
			        addValue = progressbar.val(value);
			        
			        $('.progress-value').html(value + '%');

			        if (value == max) {
			            clearInterval(animate);			           
			        }
			    };

			    var animate = setInterval(function() {
			        loading();
			    }, time);
			};
		});
		</script>
		
	</head>
			
	<body>				
		<header id="header">
			<div class="innertube"></div>
		</header>
				
		<main>
			
			<?php
				// Suppress all error messages
				error_reporting(E_ALL); 
				ini_set('log_errors','1'); 
				ini_set('display_errors','0');
			?>			
			
			<div class="innertube">
				<canvas id="Title" width="420" height="120"></canvas>
    		<script>
					var canvas = document.getElementById('Title');
					var context = canvas.getContext('2d');
					context.font = '60pt Arial';
					context.fillText('Het Weer', 0, 105);
    		</script>

				<?php

				function simplexml_load_file_from_url($url, $timeout = 5){
 					$opts = array('http' => array('timeout' => (int)$timeout));
  					$context  = stream_context_create($opts);
  					$data = file_get_contents($url, false, $context);
  					if(!$data){
    					trigger_error('Cannot load data from url: ' . $url, E_USER_NOTICE);
    					return false;
  					}
  					return simplexml_load_string($data);
				}
				
				// set feed URL and read feed into SimpleXML object
				$observation_location = 'empty';
				$url = 'http://vs004.nedcar.nl/weather.asp';
				
				// Make sure we catch any error when trying to load XML.
				libxml_use_internal_errors(true);
				// Retrieve XML output from central website serving the Wunderground data.
				//$sxml = simplexml_load_file($url);
				$sxml = simplexml_load_file_from_url($url,10);
				
				if ($sxml) {
					// Show what we got
					$observation_location = $sxml->full;
					$observation_time = $sxml->PolDateTime;
					$weather_icon = $sxml->icon;
					$weather_temp_c = $sxml->temp_c;
					$weather_pressure_mb = $sxml->pressure_mb;
					$weather_vis = $sxml -> visibility_km;
					$weather_dewpoint = $sxml->dewpoint_c;
					$weather_relhum = $sxml->relative_humidity;
					$weather_precip_1hr = $sxml->precip_1hr_metric;
					$weather_precip_today = $sxml->precip_today_metric;
					$weather_wind_dir = $sxml->wind_dir;
					$weather_wind_deg = $sxml->wind_degrees;
					$weather_wind_kph = $sxml->wind_kph;
					$weather_desc = $sxml->weather;
					$weather_feelslike = $sxml->feelslike_c;
				} else {
					// The download of data is considered failed when Observation_location is empty					
					$observation_location = "";
					
					// Show current time instead of last update time.
					$datetime = date('d-m-Y H:i');
					
					// Default values so there is something to see when debugged.
					$observation_time = $datetime;
					$weather_icon = 'clear';
					$weather_temp_c = '00';
					$weather_pressure_mb = '00';
					$weather_vis = '00';
					$weather_dewpoint = '00';
					$weather_relhum = '00 %';
					$weather_precip_1hr = '00';
					$weather_precip_today = '00';
					$weather_wind_dir = '? ';
					$weather_wind_deg = '00';
					$weather_wind_kph = '00';
					$weather_desc = 'Onbekend';
					$weather_feelslike = '00';
				}
				?>				
					
				<table class="tg" style="undefined;table-layout: fixed; width: 100%">
				<colgroup>
				<col style="width: 25%">
				<col style="width: 25%">
				<col style="width: 25%">
				<col style="width: 25%">
				</colgroup>
				<thead>
					<tr>
    				<th class="tg-left"><?php echo $observation_location; ?></th>    				
    				<th class="tg-right" colspan="3"><?php echo "update: "; echo $observation_time; ?></th>
  				</tr>	
				</thead> 
				<tfoot> 
					<tr><td>
            <?php if ($observation_location == '') { ?>
            	<p>Actuele weer informatie is momenteel niet beschikbaar. We proberen het later nog eens...</p>
            <?php }?>
            </td>            			
        	</tr>
				</tfoot>
								
				<?php if ($observation_location <> '') { ?>
				 				
  				<tr>
    				<td class="tg-center"><img src="/img/weather/<?php echo $weather_icon; ?>.png"></img></td>
    				<td class="tg-center">
    					<canvas id="canvasTemp" width="250" height="200"></canvas>
    					<script>
								var canvas = document.getElementById('canvasTemp');
								var context = canvas.getContext('2d');
								context.font = '60pt Arial';
								context.fillText('<?php echo $weather_temp_c; ?>°C', 0, 125);
    					</script>    				
    				</td>
    				<td class="tg-right" rowspan="1">
    				Druk</br>
					Zicht</br>
					Dauwpunt</br>
					Vochtigheid</br>					
					Neerslag</br>
					Wind richting</br>
					Wind snelheid</br>
					</td>
					<td class="tg-left" rowspan="1">
					<?php echo $weather_pressure_mb; ?> millibar</br> 
					<?php echo $weather_vis; ?> kilometers</br>
					<?php echo $weather_dewpoint; ?> °C</br>
					<?php echo $weather_relhum; ?></br> 					
					<?php echo $weather_precip_today; ?> mm</br> 
					<?php echo $weather_wind_dir; ?> (<?php echo $weather_wind_deg; ?>°)</br> 
					<?php echo $weather_wind_kph; ?> Km/u</br>
				</td>
  				</tr>
  				<tr>
    				<td class="tg-center"><?php echo $weather_desc; ?></td>
    				<td class="tg-center">Gevoelstemperatuur <?php echo $weather_feelslike; ?>°C</td>
    				<td class="tg-right"></td>
    				<td class="tg-left"></td>    		
  				</tr> 
  				
  				<?php } ?>  					
			</table>
			
			<?php if ($observation_location <> '') { ?>
			
			<table class="tf" style="undefined;table-layout: fixed; width: 100%">
			<colgroup>
				<col style="width: 12%">
				<col style="width: 12%">
				<col style="width: 12%">
				<col style="width: 12%">
				<col style="width: 12%">
				<col style="width: 12%">
				<col style="width: 12%">
				<col style="width: 12%">
			</colgroup>
			
			<?php							
									
				// set feed URL and read feed into SimpleXML object				
				$url = 'http://vs004.nedcar.nl/forecast.asp';				
				// Make sure we catch any error when trying to load XML.
				libxml_use_internal_errors(true);
				// Retrieve XML output from central website serving the Wunderground data.
				$sxml = simplexml_load_file($url);
			?>		
			
			<?php if ($sxml) { ?>				
			<thead>
				<tr>
					<?php	 foreach ($sxml as $value) { ?>
							<th class="tf-center" colspan="2"><?php echo $value->weekday_short;?> <?php echo $value->day;?>/<?php echo $value->month;?></th>
					<?php	} ?>
  			</tr>					
			</thead>
			<?php	} ?>				
						
			<?php	if ($sxml) { ?>
			<tr>
				<?php foreach ($sxml as $value) { ?>
							<td class="tf-center">Min <?php echo $value->low_celcius; ?>°C</td>
							<td class="tf-center">Max <?php echo $value->high_celcius; ?>°C</td>
					<?php	} ?>
			</tr>
			<?php }?>
			<?php	if ($sxml) { ?>
			<tr>
				<?php foreach ($sxml as $value) { ?>
							<td class="tf-center" colspan="2"><img width=90px; src="/img/weather/<?php echo $value->icon; ?>.png"></td>
					<?php	} ?>
			</tr>
			<?php }?>
			
			<?php	if ($sxml) { ?>
			<tr>
				<?php foreach ($sxml as $value) { ?>
							<td class="tf-center" colspan="2"><?php echo $value->conditions; ?></td>
					<?php	} ?>
			</tr>
			<?php }?>
			
			<?php	if ($sxml) { ?>
			<tr>
				<?php foreach ($sxml as $value) { ?>
							<td class="tf-right">Neerslag</td>
							<td class="tf-left" ><?php echo $value->qpf_allday_mm; ?> mm</td>
					<?php	} ?>
			</tr>
			<?php }?>
			<?php	if ($sxml) { ?>
			<tr>
				<?php foreach ($sxml as $value) { ?>
							<td class="tf-right">Wind</td>
							<td class="tf-left" ><?php echo $value->avewind_kph; ?> km/u <?php echo $value->avewind_dir; ?></td>
					<?php	} ?>
			</tr>
			<?php }?>
			</table>						
			</div>
		<?php } ?>				
		</main>
		
		
		<div id="right">
			<div id="uphalf">

		  </div>
		  <div id="downhalf">
			  <?php
				  $url = 'http://vs004.nedcar.nl/image.gif';
				  $array = get_headers($url);
				  $string = $array[0];
				  if(strpos($string,"200"))
  		   	{
  		?>  		
    			  <img width=350px; src='<?php echo $url; ?>'></img>
    	<?php
  			  }
  		?>			
		  </div>					
		</div>
		
		<footer id="footer">
			<div class="demo-wrapper html5-progress-bar">		
			<div class="progress-bar-wrapper">

				<progress id="progressbar" value="0" max="60"></progress>
				<span class="progress-value"></span>
			</div>
			</div>
		</footer>				
	</body>
</html>