# ---------------------------------------------------------
#
# Read BVS csv list and create IP list
# Marcel Jussen
# 14-4-2014
#
# ---------------------------------------------------------
cls

$bvslist = Get-Content \\s007\e$\Bodyshop\Remote\bvs_lijst.txt

$stream = [System.IO.StreamWriter] "\\s007\e$\Bodyshop\Remote\bodyshop.txt"
$stream2 = [System.IO.StreamWriter] "\\s007\e$\Bodyshop\Remote\bodyshop_iponly.txt"

foreach ($Data in $bvslist) {
	$bvs_name, $bvs_ip = $Data -split ';' -replace '^\s*|\s*$'	
	$octet = [byte[]]($bvs_ip -split '\.')
	$start = $octet[3]
	$end = 40	
	
	do {
		$octet[3] = $start
		switch ($octet[3]) 
    	{ 
        	21 {$type = "IndustriePC (BVS)"} 
        	22 {$type = "MicroboxPC (BVT)"} 
			23 {$type = "MicroboxPC (BVT)"} 
			24 {$type = "MicroboxPC (BVT)"} 
			25 {$type = "MicroboxPC (BVT)"} 
			26 {$type = "MicroboxPC (BVT)"} 
			27 {$type = "MicroboxPC (BVT)"} 
        	28 {$type = "APC_Pannel B&R (BVO)"}
			29 {$type = "APC_Pannel B&R (BVO)"}
			30 {$type = "APC_Pannel B&R (BVO)"}
			31 {$type = "APC_Pannel B&R (BVO)"}
			32 {$type = "APC_Pannel B&R (BVO)"}
			33 {$type = "APC_Pannel B&R (BVO)"}
			34 {$type = "APC_Pannel B&R (BVO)"}
			35 {$type = "APC_Pannel B&R (BVO)"}
			36 {$type = "APC_Pannel B&R (BVO)"}
			37 {$type = "APC_Pannel B&R (BVO)"}
			38 {$type = "APC_Pannel B&R (BVO)"}
			39 {$type = "APC_Pannel B&R (BVO)"}
			40 {$type = "APC_Pannel B&R (BVO)"}
        	default {$type = "ERROR"}
    	}			
		$ip = $octet -join '.'
		
		$line = "$ip;$bvs_name;$type;"
		$stream.WriteLine($line)
		$stream2.WriteLine($ip)
		Write-Host $line
		$start++
	}
	while ($start -le $end)		
}
      
$stream.close()
$stream2.close()


