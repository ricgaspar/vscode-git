Import-Module VNB_PSLib -Force

$Action = {
        $account = $Event.SourceEventArgs.NewEvent.TargetInstance.InsertionStrings[0]
        $workstation = $Event.SourceEventArgs.NewEvent.TargetInstance.InsertionStrings[1]
        $dc = $Event.SourceEventArgs.NewEvent.TargetInstance.Computer
        Write-Host "$(Get-Date): $($DC) reported $($Account) $($Workstation)"
}

# Monitor 4725 'Account disabled' and 4722 'Account enabled'
# Start-EventLogMonitor -Computer DC07,DC08 -Logname Security -EventID 4725,4722 -Action $Action

Stop-EventLogMonitor