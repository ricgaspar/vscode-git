function Unblock-Script
{
        
    <#
        .Synopsis 
            Removes 'Zone.Identifier' Alternate Data Stream from the file passed.
            
        .Description
            Removes 'Zone.Identifier' Alternate Data Stream from the file passed.
            
        .Parameter FileName
            File to remove the 'Zone.Identifier' Alternate Data Stream from (aliased to FullName for piping.)
            
        .Example
            Unblock-Script -Filename C:\temp\myfile.ps1 
            Description
            -----------
            Removes the 'Zone.Identifier' ADS from the file C:\temp\myfile.ps1
    
        .Example
            dir c:\temp\myscripts | Unblock-Script
            Description
            -----------
            Removes the 'Zone.Identifier' ADS from each file in the pipeline.
    
        .OUTPUTS
            System.String
            
        .INPUTS
            System.String
            
        .Link
            Block-Script
            Remove-AlternateDataStream
        
        .Notes
            NAME:      Unblock-Script
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [cmdletbinding(SupportsShouldProcess=$True)]
    Param(
        [alias("FullName")]
        [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$FileName
    )
    
    Begin 
    {
    
            $Name = 'Zone.Identifier'
        
    }
    
    Process 
    {
    
            if(Test-Path $FileName)
            {
                if($PSCmdlet.ShouldProcess($FileName,"Using Remove-AlternateDataStream to Unblock"))
                {
                    Remove-AlternateDataStream -FileName $FileName -Name $Name
                }
            }
            else
            {
                Write-Host "`$FilePath [$FilePath] not provide or File not Found"
            }
        
    }
}
    
