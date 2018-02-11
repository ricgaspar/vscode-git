$scopes = @(
    'CurrentUser'
    'LocalMachine'
    'MachinePolicy'
    'Process'
    'UserPolicy'
)

$scopes | % {Get-ExecutionPolicy -Scope $_}