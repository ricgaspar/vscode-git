w32tm /config /syncfromflags:domhier /update
net stop w32time && net start w32time
w32tm /resync
w32tm /resync /rediscover