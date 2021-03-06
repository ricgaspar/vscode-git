###########################################################
# AUTHOR  : Marius / Hican - http://www.hican.nl - @hicannl
# DATE    : 16-06-2014
# COMMENT : Read through the computer objects of a specific
#           OU, retrieve the BitLocker Recovery Keys and
#           output that to a file.
# VERSION : 1.00
###########################################################

#CHANGELOG

#ERROR REPORTING ALL
Set-StrictMode -Version latest

#----------------------------------------------------------
#STATIC VARIABLES
#----------------------------------------------------------
$script_parent     = Split-Path -Parent $MyInvocation.MyCommand.Definition
$output            = $script_parent + "\recovery_keys.csv"
$output            = "\\s007\f$\temp\recovery_keys.csv"

$script:searchbase = ""
$script:ou         = "OU=Clients"

Try
{
  If (Test-Path $output) { $delete = Remove-Item $output -Force -ErrorAction Stop }
}
Catch
{
  Write-Host "$($_.Exception.Message)" -foregroundcolor Red
  Break
}

$base = $env:USERDNSDOMAIN.Split(".")
ForEach ($b In $base)
{
  $searchbase += ",DC=$($b)"
}

#----------------------------------------------------------
#LOAD AD MODULE
#----------------------------------------------------------
Try { Import-Module ActiveDirectory } Catch { Write-Host "[ERROR]`t $($_.Exception.Message)" }

Function Create-CSV
{
  "Machine,CN,RecoveryPassword,CreationDate" | Out-File $output -Encoding ASCII

  $comps = Get-ADComputer -Filter * -SearchBase ($ou + $searchbase)

  ForEach ($comp In $comps)
  {
    $comp_dn = $comp.DistinguishedName
    $recovery_info = Get-ADObject -Filter 'ObjectClass -eq "msFVE-RecoveryInformation"' -SearchBase $comp_dn -Properties cn,msfve-recoverypassword,whencreated
    ForEach ($info In $recovery_info)
    {
      Try
      {
        "$($comp.Name),$($info.cn),$($info.'msfve-recoverypassword'),$($info.whencreated)" | Out-File $output -Append -Encoding ASCII
      }
      Catch
      {
        Write-Host "$($_.Exception.Message)" -foregroundcolor Red
      }
    }
  }
}


Create-CSV
