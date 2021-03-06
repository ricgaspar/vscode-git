#--------------------------------------------------------------
# Update INI file with inline C#
# 25-06-2014
# Author: Marcel Jussen
#
# See: http://gallery.technet.microsoft.com/scriptcenter/Edit-old-fashioned-INI-f8fbc067

#
# Update default nsclient.ini that comes with the MSI installation.
#
#--------------------------------------------------------------

$CSharp = 'profileapi.cs'
if(Test-Path $CSharp) {
	add-type -Path $CSharp 
	
	$IniPath = 'C:\Program Files\NSClient++\nsclient.ini'	
	# Update INI file if INI file exists
	if(Test-Path $IniPath) { 

        #---------------------
        $Section = '/modules'
        $strItems = @('CheckDisk','CheckEventlog','CheckExternalScripts','CheckHelpers','CheckNSCP','CheckSystem','CheckWMI','NRPEServer','NSCAClient','NSClientServer')
        $Value= '1'
        foreach($Item in $strItems) {
				[Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)
        }        

        #---------------------
        $Section = '/settings/default'
		$Item = 'allowed hosts'
		$Value= '10.178.1.216'
		[Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)
    
		$Item = 'password'
		$Value= 'nedcar'
		[Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

		$Item = 'allow arguments'
		$Value= 'true'
		[Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        #---------------------
        $Section = '/settings/external scripts'
		$Item = 'allow arguments'
		$Value= 'true'
		[Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

		$Item = 'allow nasty characters'
		$Value= 'true'
		[Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        #---------------------
        $Section = '/settings/NRPE/server'
        $Item = 'allow arguments'
        $Value= 'true'
		[Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        #---------------------
        $Section = '/settings/external scripts/alias'
        $Item = 'alias_cpu'
        $Value= 'checkCPU warn=80 crit=90 time=5m time=1m time=30s'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_cpu_ex'
        $Value= 'checkCPU warn=$ARG1$ crit=$ARG2$ time=5m time=1m time=30s'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)
        
        $Item = 'alias_disk'
        $Value= 'CheckDriveSize MinWarn=10% MinCrit=5% CheckAll FilterType=FIXED'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_disk_loose'
        $Value= 'CheckDriveSize MinWarn=10% MinCrit=5% CheckAll FilterType=FIXED ignore-unreadable'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_event_log'
        $Value= 'CheckEventLog file=application file=system MaxWarn=1 MaxCrit=1 "filter=generated gt -2d AND severity NOT IN (''success'', ''informational'') AND source != ''SideBySide''" truncate=800 unique descriptions "syntax=%severity%: %source%: %message% (%count%)"'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_file_age'
        $Value= 'checkFile2 filter=out "file=$ARG1$" filter-written=>1d MaxWarn=1 MaxCrit=1 "syntax=%filename% %write%"'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_file_size'
        $Value= 'CheckFiles "filter=size > $ARG2$" "path=$ARG1$" MaxWarn=1 MaxCrit=1 "syntax=%filename% %size%" max-dir-depth=10'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_mem' 
        $Value= 'checkMem MaxWarn=80% MaxCrit=90% ShowAll=long type=physical type=virtual type=paged type=page'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_process'
        $Value= 'checkProcState "$ARG1$=started"'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_process_count'
        $Value= 'checkProcState MaxWarnCount=$ARG2$ MaxCritCount=$ARG3$ "$ARG1$=started"'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_process_hung'
        $Value= 'checkProcState MaxWarnCount=1 MaxCritCount=1 "$ARG1$=hung"'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_process_stopped'
        $Value= 'checkProcState "$ARG1$=stopped"'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)
        
        $Item = 'alias_sched_all'
        $Value= 'CheckTaskSched "filter=exit_code ne 0" "syntax=%title%: %exit_code%" warn=>0'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_sched_long'
        $Value= 'CheckTaskSched "filter=status = ''running'' AND most_recent_run_time < -$ARG1$" "syntax=%title% (%most_recent_run_time%)" warn=>0'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_sched_task'
        $Value= 'CheckTaskSched "filter=title eq ''$ARG1$'' AND exit_code ne 0" "syntax=%title% (%most_recent_run_time%)" warn=>0'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_service'
        $Value= 'checkServiceState CheckAll'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_service_ex'
        $Value= 'checkServiceState CheckAll "exclude=Net Driver HPZ12" "exclude=Pml Driver HPZ12" exclude=stisvc'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_up'
        $Value= 'checkUpTime MinWarn=1d MinWarn=1h'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_updates'
        $Value= 'check_updates -warning 0 -critical 0'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_volumes'
        $Value= 'CheckDriveSize MinWarn=10% MinCrit=5% CheckAll=volumes FilterType=FIXED'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'alias_volumes_loose'
        $Value= 'CheckDriveSize MinWarn=10% MinCrit=5% CheckAll=volumes FilterType=FIXED ignore-unreadable'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)

        $Item = 'default'
        $Value= '' 
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)
        

        #---------------------
        $Section = '/settings/external scripts/scripts'
        $Item = 'check_win_files'
        $Value= 'cscript.exe //T:30 //NoLogo scripts\check_win_files.vbs $ARG1$'
        [Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)
			
        #---------------------
		$Section = '/settings/external scripts/wrappings'
		$Item = 'ps1'
		$Value= 'cmd /c echo scripts\\%SCRIPT% %ARGS%; exit($lastexitcode) | powershell.exe -command -'
		[Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath) 

        #---------------------		
		$Section = '/settings/external scripts/wrapped scripts'
		$Item = 'check_time_W32TM'
		$Value= 'nrpe_Check_W32TM.ps1 $ARG1$ $ARG2$'
		[Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath) 
		
		$Item = 'check_win_sessions'
		$Value= 'nrpe_Win_Sessions.ps1 $ARG1$ $ARG2$'
		[Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)
		
		$Item = 'check_os_activation'
		$Value= 'nrpe_Check_Activation.ps1 $ARG1$ $ARG2$'
		[Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)
		
		$Item = 'check_win_WMICounter'
		$Value= 'nrpe_Check_WMICounter.ps1 $ARG1$ $ARG2$ $ARG3$ $ARG4$ $ARG5$ $ARG6$ $ARG7$'
		[Void][profileapi]::WritePrivateProfileString($Section,$Item,$Value,$IniPath)
		
			
	} else {
		Write-Host "ERROR: $IniPath does not exist!"
		exit 2
	}
} else {
	Write-Host "ERROR: Cannot find $CSharp"
	exit 2
}
 
