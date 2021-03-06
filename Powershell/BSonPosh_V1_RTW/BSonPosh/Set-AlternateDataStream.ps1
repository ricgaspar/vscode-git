function Set-AlternateDataStream
{
        
    <#
        .Synopsis 
            Sets Alternate Data Stream from the file passed.
            
        .Description
            Sets Alternate Data Stream from the file passed.
            
        .Parameter FileName
            File to get the Alternate Data Stream from (aliased to FullName for piping.)
            
        .Parameter Name
            Name of the Alternate Data Stream.
            
        .Parameter Data
            Data for the Alternate Data Stream.
            
        .Example
            Set-AlternameDataStream -Filename C:\temp\myfile.ps1 -Name 'Zone.Identifier' -data "[ZoneTransfer]`nZoneID=4" 
            Description
            -----------
            Sets the ADS on the file C:\temp\myfile.ps1
    
        .Example
            dir c:\temp\myscripts | Set-AlternameDataStream -Name 'Zone.Identifier' -data "[ZoneTransfer]`nZoneID=4" 
            Description
            -----------
            Sets the ADS on each file in the pipeline.
    
        .OUTPUTS
            NTFS.StreamInfo
            
        .INPUTS
            System.String
            
        .Link
            Get-AlternateDataStream
        
        .Notes
            NAME:      Set-AlternameDataStream
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding(SupportsShouldProcess=$True)]
    Param(
        [parameter(mandatory=$true)]
        [string]$Name,
        
        [Alias('Text')]
        [parameter(mandatory=$true)]
        [string]$Data,
        
        [alias("FullName")]
        [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$FileName
    )
    
    Process 
    {
    
        Write-Verbose " [Set-AlternateDataStream] :: Begin Process"
        
        if(Test-Path $FileName)
        {
            Write-Verbose " [Set-AlternateDataStream] :: $FileName Found"
            Write-Verbose " [Set-AlternateDataStream] :: Processing ADS"
            $ADS = New-Object NTFS.FileStreams($FileName)
            if($PSCmdlet.ShouldProcess($FileName,"Setting Alternate Data Stream $Name"))
            {
                Write-Verbose " [Set-AlternateDataStream] :: Adding ADS $Name"
                $ADS.Add($Name)
                Write-Verbose " [Set-AlternateDataStream] :: Creating Stream for $Name"
                $stream = $ADS.Item($Name).open()                           
                Write-Verbose " [Set-AlternateDataStream] :: Setting $Data to $Name"
                $sw = [System.IO.streamwriter]$stream
                $Sw.write($Data)      
                
                Write-Verbose " [Set-AlternateDataStream] :: Closing ADS"
                $sw.close()                                                                                            
                $stream.close()
                
                # Returning ADS text
                Write-Verbose " [Set-AlternateDataStream] :: Returning ADS Object via Get-AlternateDataStream"
                Get-AlternateDataStream $FileName
            }
        }
        else
        {
            Write-Verbose " [Set-AlternateDataStream] :: File not Found"
        }
        
        Write-Verbose " [Set-AlternateDataStream] :: End Process"
    
    }
}
    
