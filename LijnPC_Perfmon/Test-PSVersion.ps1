# ------------------------------------------------------------------------------
<#
.SYNOPSIS
    Update JPG to display computers that can be connected to.

.CREATED_BY
	Marcel Jussen

.CREATE_DATE
	11-09-2017

.CHANGE_DATE
	11-09-2017

.DESCRIPTION
    Update JPG to display computers that can be connected to.

#>
# ------------------------------------------------------------------------------
#-requires 3.0

# ---------------------------------------------------------
Import-Module VNB_PSLib -Force -ErrorAction Stop
# ---------------------------------------------------------

Function Get-SpecificComputers {
    param (
        [string]$ADSearchFilter = '(objectCategory=Computer)',
        [string]$OUPath
    )

    begin {
        try {
            $colResults = $null
            $objOU = New-Object System.DirectoryServices.DirectoryEntry($OUPath)
            $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
        }
        catch { }
    }
    process {
        try {
            $objSearcher.SearchRoot = $objOU
            $objSearcher.PageSize = 5000
            $objSearcher.Filter = $ADSearchFilter
            $colResults = $objSearcher.FindAll()
        }
        catch { }
        return $colResults
    }
}

# ---------------------------------------------------------
Clear-Host

$ADOU_PC = 'LDAP://OU=LijnPC,OU=FAS,OU=Factory,DC=nedcar,DC=nl'
Write-Output "Collecting computers from $ADOU_PC"
$OUComputers = Get-SpecificComputers -OUPath $ADOU_PC
if ($OUComputers -eq $null) {
    Write-Output "ERROR: No computers collected from $ADOU_DisplayPC"
}
else {
    Write-Output "Scanning computers."
    $CompNr = 0
    $DSComputers = New-Object System.Collections.ArrayList
    $OUComputers | ForEach-Object {
        $CompNr++
        $dnshostname = [System.String]$_.properties.dnshostname
        $CompName = $dnshostname

        Write-Output "Computername [$CompNr] : $CompName"
        $Connect = Test-Connection -ComputerName $CompName -ErrorAction SilentlyContinue
        if ($Connect) {
            Try {
                $PSTable = ( Invoke-Command -Computername $CompName { $PSVersionTable } -ErrorAction SilentlyContinue)
                $PSTable = $PSTable.PSVersion

                $item = New-Object System.Object
                $item | Add-Member -MemberType NoteProperty -Name "dnshostname" -Value $CompName
                $item | Add-Member -MemberType NoteProperty -Name "Major" -Value $($PSTable.Major)
                $item | Add-Member -MemberType NoteProperty -Name "Minor" -Value $($PSTable.Minor)
                $item | Add-Member -MemberType NoteProperty -Name "Build" -Value $($PSTable.Build)
                $item | Add-Member -MemberType NoteProperty -Name "Revision" -Value $($PSTable.Revision)
                Write-Output "  - Version : $($PSTable.Major) - $($PSTable.Minor) "
            }
            Catch {
                $item = New-Object System.Object
                $item | Add-Member -MemberType NoteProperty -Name "dnshostname" -Value $CompName
                $item | Add-Member -MemberType NoteProperty -Name "Major" -Value 'ERROR'
                $item | Add-Member -MemberType NoteProperty -Name "Minor" -Value ''
                $item | Add-Member -MemberType NoteProperty -Name "Build" -Value ''
                $item | Add-Member -MemberType NoteProperty -Name "Revision" -Value ''
                Write-Output "  - PS Version : ERROR"
            }
            $DSComputers.Add($item) | Out-Null
        }
        else {
            $item = New-Object System.Object
            $item | Add-Member -MemberType NoteProperty -Name "dnshostname" -Value $CompName
            $item | Add-Member -MemberType NoteProperty -Name "Major" -Value 'Cannot connect'
            $item | Add-Member -MemberType NoteProperty -Name "Minor" -Value ''
            $item | Add-Member -MemberType NoteProperty -Name "Build" -Value ''
            $item | Add-Member -MemberType NoteProperty -Name "Revision" -Value ''
            $DSComputers.Add($item) | Out-Null
            Write-Output '  - ERROR: Cannot connect to computer.'
        }
    }
    Write-Output "Completed scanning of [$CompNr] computers."
}
Write-Output "Script completed."

$DSComputers | Export-CSV -Path 'C:\Temptools\LijnPC.csv' -Delimiter ';' -NoClobber
$DSComputers | Format-Table -AutoSize