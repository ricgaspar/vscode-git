# =========================================================
# Sign VNB scripts using domain trusted CA certificate
#
# VDL Nedcar - Information Systems
# Marcel Jussen
# 15-03-2018
# =========================================================
#Requires -version 4.0

# Install the code signing certificate in the Computer certificate store
$Certificate = Get-ChildItem cert:\CurrentUser\My -CodeSigningCert
$Filepath = 'C:\VSCode\vscode-git\Powershell\IBM Server Protect\install.ps1'
if($Certificate) {
    $result = Set-AuthenticodeSignature -Certificate $Certificate -FilePath $Filepath
}

# =========================================================