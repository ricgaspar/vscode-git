
# $IP_List = "E:\Bodyshop\Remote\bvs_lijst.txt"
# $content = get-content $IP_List
# foreach($line in $content) {
    # $tarr = $line.Split(';')
    # $ip = $tarr[1]
    # $ip >> iplijst.txt
# }

$nmapfile = ".\nmap-failed.xml"

# Scan 10 top ports to determine if remote host is online 
#
cmd.exe /c " nmap -Pn -n -p T:21,2121,80,8080 -A -v -iL iplijst.txt -oX $nmapfile --no-stylesheet"

# $csvfilename = ".\scan_results.csv"
# .\parse-nmap.ps1 $nmapfile | select ipv4, status | Export-Csv $csvfilename
