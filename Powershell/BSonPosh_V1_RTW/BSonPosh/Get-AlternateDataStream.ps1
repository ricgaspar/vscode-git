function Get-AlternateDataStream
{
        
    <#
        .Synopsis 
            Gets Alternate Data Stream from the file passed.
            
        .Description
            Gets Alternate Data Stream from the file passed.
            
        .Parameter FileName
            File to get the Alternate Data Stream from (aliased to FullName for piping.)
            
        .Example
            Get-AlternameDataStream -Filename C:\temp\myfile.ps1
            Description
            -----------
            Gets the ADS from the file C:\temp\myfile.ps1
    
        .Example
            dir c:\temp\myscripts | Get-AlternameDataStream 
            Description
            -----------
            Gets the ADS from each file in the pipeline.
    
        .OUTPUTS
            NTFS.StreamInfo
            
        .INPUTS
            System.String
            
        .Link
            Set-AlternateDataStream
        
        .Notes
            NAME:      Get-AlternameDataStream
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
   
    [Cmdletbinding()]
    Param(
        [alias("FullName")]
        [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$FileName
    )
    
    Process 
    {
        Write-Verbose " [Get-AlternateDataStream] :: Begin Process"
        Write-Verbose " [Get-AlternateDataStream] :: Processing $FileName"
        if(Test-Path $FileName)
        {
            Write-Verbose " [Get-AlternateDataStream] :: $FileName found. Getting ADS"
            $ADSObject = New-Object NTFS.FileStreams($FileName)
            if($ADSObject)
            {
                Write-Verbose " [Get-AlternateDataStream] :: Found ADS"
                foreach($ADS in $ADSObject)
                {
                    Write-Verbose " [Get-AlternateDataStream] :: Getting ADS info for [$($ADS.Name)]"
                    # Get Stream Text
                    $stream = $ADSObject.Item($ADS.Name).Open()
                    $streamReader = new-object System.IO.streamreader($stream)
                    $Text = $streamReader.ReadToEnd()
                    $stream.Close() 
                    $streamReader.Close()
                    
                    $MyADSObject = $ADS | Add-Member -Name FileName -Value $FileName -MemberType NoteProperty -PassThru
                    $MyADSObject = $MyADSObject | Add-Member -Name Data -Value $Text -MemberType NoteProperty -PassThru
                    $MyADSObject
                }
            }
            else            {
                Write-Verbose " [Get-AlternateDataStream] :: No ADS Found"
            }
        }
        else
        {
            Write-Host "`$FilePath [$FilePath] not provide or File not Found"
        }
        
        Write-Verbose " [Get-AlternateDataStream] :: End Process"
    }
}
    
