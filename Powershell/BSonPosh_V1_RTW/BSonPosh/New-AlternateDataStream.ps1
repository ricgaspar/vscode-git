function New-AlternateDataStream 
{
    
    <#
        .Synopsis 
            Creates an Alternate data stream and attachs to a file.
            
        .Description
            Creates an Alternate data stream and attachs to a file.
        
        .Parameter FullName
            Name and path of the file you want to set the Alternate Data Stream on.
            
        .Parameter Name
            Name of the Alternate Data Stream
        
        .Parameter Text
            Data to be stored in the Alternate Data Stream
                
        .Example
            New-AlternateDataStream -FullName c:\temp\myfile.ps1 -name 'Zone.Identifier' -text "[ZoneTransfer]`nZoneID=4"
            Description
            -----------
            Creates the following ADS and sets on the file c:\temp\myfile.ps1
            
            [ZoneTransfer]
            ZoneID=4
            
        .OUTPUTS
            NTFS.StreamInfo
            
        .INPUTS
            System.String
            
        .Link
            Get-AlternateDataStream
            Set-AlternateDataStream
            
        .Notes
            NAME:      Block-Script
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding(SupportsShouldProcess=$True)]
    Param(
    
        [parameter(mandatory=$true)]
        [string]$Name,
        
        [parameter(mandatory=$true)]
        [string]$Text,
        
        [alias("FullName")]
        [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$FileName
        
    )
    Process 
    {
    
        Write-Verbose " [New-AlternateDataStream] :: Begin Process"
        
        if(Test-Path $FileName)
        {
            Write-Verbose " [New-AlternateDataStream] :: $FileName Found"
            Write-Verbose " [New-AlternateDataStream] :: Processing ADS"
            $ADS = New-Object NTFS.FileStreams($FileName)
            if($PSCmdlet.ShouldProcess($FileName,"Creating Alternate Data Stream $Name"))
            {
                Write-Verbose " [New-AlternateDataStream] :: Adding ADS $Name"
                $ADS.Add($Name)
                Write-Verbose " [New-AlternateDataStream] :: Creating Stream for $Name"
                $stream = $ADS.Item($Name).open()                           
                Write-Verbose " [New-AlternateDataStream] :: Setting $Text to $Name"
                $sw = [System.IO.streamwriter]$stream
                $Sw.write($Text)      
                
                Write-Verbose " [New-AlternateDataStream] :: Closing ADS"
                $sw.close()                                                                                            
                            
                $stream.close()
                
                # Returning ADS text
                Write-Verbose " [New-AlternateDataStream] :: Returning ADS Object via Get-AlternateDataStream"
                Get-AlternateDataStream $FileName
            }
        }
        else
        {
            Write-Verbose " [New-AlternateDataStream] :: File not Found"
        }
        
        Write-Verbose " [New-AlternateDataStream] :: End Process"
    
    }
}
    
