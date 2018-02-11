# =========================================================
# Sign VNB scripts using domain trusted CA certificate
#
# VDL Nedcar - Information Systems
# Marcel Jussen
# 07-12-2015
# =========================================================
#Requires -version 3.0
#Requires -runasadministrator

cls
$Certificate = Get-ChildItem cert:\CurrentUser\My -CodeSigningCert | Where-Object {$_.FriendlyName -eq 'VNB Powershell code signing'}

if($Certificate) {
    $FSOFolder = 'C:\Scripts\Acties'
    $FSOInclude = '*.ps1'
    $fileEntries = Get-FilesByAge -Path $FSOFolder -Include $FSOInclude -Recurse $True
    foreach($filepath in $fileEntries) {        
        if($filepath -notmatch 'signscripts.ps1') {
            Write-Host "Signing script: $filepath"
            $result = Set-AuthenticodeSignature -Certificate $Certificate -FilePath $filepath
        }
    }
}

# =========================================================