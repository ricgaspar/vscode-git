
# Disable the Analytic log first, then re-enable
wevtutil.exe set-log "Microsoft-Windows-Dsc/Analytic" /q:true /e:false
wevtutil.exe set-log "Microsoft-Windows-Dsc/Analytic" /q:true /e:true

wevtutil.exe set-log "Microsoft-Windows-Dsc/Debug" /q:true /e:false
wevtutil.exe set-log "Microsoft-Windows-Dsc/Debug" /q:true /e:true