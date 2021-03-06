function Block-Script
{
    <#
        .Synopsis
            Sets the Alternate Data Stream (ADS) on the file to InternetZone.
            [ZoneTransfer]
            ZoneID=4
            
        .Description
            Sets the Alternate Data Stream on the file to InternetZone.
            [ZoneTransfer]
            ZoneID=4
                        
        .Parameter FileName 
            Path to the file to set the ADS on.
        
        .Example
            Block-Script -FileName C:\Local\MyFile.ps1
            Description
            -----------
            Sets the ADS on 'C:\Local\MyFile.ps1' to Internet Zone.
            
        .Example
            dir c:\temp\myscripts | Block-Script
            Description
            -----------
            Blocks all the files in the path C:\temp\myscripts.
    
        .OUTPUTS
            NTFS.StreamInfo
            
        .INPUTS
            System.String
            
        .Link
            Set-AlternateDataStream
            Unblock-Script
        
        .Notes
            NAME:      Block-Script
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding(SupportsShouldProcess=$True)]
    Param(
        [alias("FullName")]
        [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$FileName
    )
    Begin 
    {
        $Name = 'Zone.Identifier'
        $String  = "[ZoneTransfer]`nZoneID=4" 
    }
    Process 
    {
            if(Test-Path $FileName)
            {
                if($PSCmdlet.ShouldProcess($FileName,"Using Set-AlternateDataStream to Block"))
                {
                    Set-AlternateDataStream -FileName $FileName -Name $Name -Text $String
                }
            }
            else
            {
                Write-Host "`$FilePath [$FilePath] not provide or File not Found"
            }
    }
}
    
