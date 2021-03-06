function Remove-AlternateDataStream 
{
        
    <#
        .Synopsis 
            Removes Alternate Data Stream from the file passed.
            
        .Description
            Removes Alternate Data Stream from the file passed.
        
        .Parameter Name
            Name of the Alternate Data Stream to remove.
            
        .Parameter FileName
            File to remove the Alternate Data Stream from (aliased to FullName for piping.)
            
        .Example
            Get-AlternameDataStream -Filename C:\temp\myfile.ps1 -Name 'Zone.Identifier'
            Description
            -----------
            Removes the 'Zone.Identifier' ADS from the file C:\temp\myfile.ps1
    
        .Example
            dir c:\temp\myscripts | Get-AlternameDataStream -name 'Zone.Identifier'
            Description
            -----------
            Removes the 'Zone.Identifier' ADS from each file in the pipeline.
    
        .OUTPUTS
            System.String
            
        .INPUTS
            System.String
            
        .Link
            Get-AlternateDataStream
        
        .Notes
            NAME:      Remove-AlternameDataStream
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [cmdletbinding(SupportsShouldProcess=$True)]
    Param(
        [parameter(mandatory=$true)]
        [string]$Name,
        [alias("FullName")]
        [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$FileName
    )
    
    Process 
    {
    
        Write-Verbose " [Remove-AlternateDataStream] :: Begin Process"
        
        if(Test-Path $FileName)
        {
            Write-Verbose " [Remove-AlternateDataStream] :: $FileName Found"
            Write-Verbose " [Remove-AlternateDataStream] :: Processing ADS"
            $ADS = New-Object NTFS.FileStreams($FileName)
            if($PSCmdlet.ShouldProcess($FileName,"Removing Alternate Data Stream $Name"))
            {
                Write-Verbose " [Remove-AlternateDataStream] :: Removing ADS"
                try
                {
                    if($ADS[$Name].delete())
                    {
                        "Stream Removed!"
                    }
                }
                catch
                {
                    "Error removing stream."
                }
            }
        }
        else
        {
            Write-Verbose " [Remove-AlternateDataStream] :: File not Found"
        }
        
        Write-Verbose " [Remove-AlternateDataStream] :: End Process"
    
    }
}
    
