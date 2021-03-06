<#
.SYNOPSIS
    VNB Library - CRC32

.CREATED_BY
	Marcel Jussen

.CHANGE_DATE
	4-6-2017
 
.DESCRIPTION
    Function to calculate CRC32
#>
#requires -version 3.0

Set-Alias crc32 Get-Crc32

$asm = Add-Type -Mem @'
    [DllImport("ntdll.dll")]
    internal static extern UInt32 RtlComputeCrc32(
        UInt32 InitialCrc,
        Byte[] Buffer,
        Int32 Length
    );
    
    public static String ComputeCrc32(String file) {
      UInt32 crc32 = 0;
      Int32  read;
      Byte[] buf = new Byte[4096];
      
      using (FileStream fs = File.OpenRead(file)) {
        while ((read = fs.Read(buf, 0, buf.Length)) != 0)
          crc32 = RtlComputeCrc32(crc32, buf, read);
      }
            
      return ("0x" + crc32.ToString("X", CultureInfo.CurrentCulture));
    }
'@ -Name Check -NameSpace Crc32 -Using System.IO, System.Globalization -PassThru

function Get-Crc32 {
  <#
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateScript({Test-Path $_})]
    [String]$FileName
  )
  
  $FileName = cvpa $FileName
  $asm::ComputeCrc32($FileName)
}

# --------------------------------------------------------- 
# Export aliases
# --------------------------------------------------------- 
export-modulemember -alias * -function *