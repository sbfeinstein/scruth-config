# This script re-encodes only videos that need orientation normalization.
# Updated April 21, 2026

$SourceDir = "D:\family media archives"
$FFmpegPath = "ffmpeg"

$Extensions = "*.mp4", "*.wmv", "*.mov", "*.3gp", "*.avi"
$VideoFiles = Get-ChildItem -Path $SourceDir -Include $Extensions -Recurse

Write-HostInfo ("Scanning {0} for videos needing orientation normalization..." -f $SourceDir)

foreach ($File in $VideoFiles) {

    Write-HostInfo ("Checking: {0}" -f $File.FullName)

    # --- 1. Read rotation tag (may be empty)
    $RotateTag = & ffprobe -v error -select_streams v:0 `
        -show_entries stream_tags=rotate `
        -of default=noprint_wrappers=1:nokey=1 "$($File.FullName)"

    # --- 2. Read width/height
    $Dimensions = & ffprobe -v error -select_streams v:0 `
        -show_entries stream=width,height `
        -of csv=p=0 "$($File.FullName)"

    if (-not $Dimensions) {
        Write-HostCaution ("Could not read dimensions for {0}. Skipping." -f $File.Name)
        continue
    }

    $Width, $Height = $Dimensions -split ','

    # --- 3. Determine if rotation normalization is needed
    $NeedsRotation = $false

    # Case A: rotation metadata present
    if ($RotateTag -and $RotateTag -ne "0") {
        $NeedsRotation = $true
    }
    # Case B: portrait resolution
    elseif ([int]$Height -gt [int]$Width) {
        $NeedsRotation = $true
    }

    if (-not $NeedsRotation) {
        Write-HostInfo ("Skipping {0} - orientation already correct." -f $File.Name)
        continue
    }

    Write-HostInfo ("Processing: {0} (rotation or portrait detected)" -f $File.FullName)

    # --- 4. Build output paths
    $TempOutputFile = Join-Path $File.DirectoryName ($File.BaseName + "_tmp.mp4")
    $FinalOutputFile = Join-Path $File.DirectoryName ($File.BaseName + ".mp4")

    # --- 5. Build the correct -vf filter
    $Filter = ""

    if ($RotateTag -and $RotateTag -ne "0") {
        switch ($RotateTag) {
            "90"  { $Filter = "transpose=1" }
            "180" { $Filter = "transpose=2,transpose=2" }
            "270" { $Filter = "transpose=2" }
            default { $Filter = "" }
        }
    }

    $ScalePad = "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2"

    if ($Filter) {
        $VF = "$Filter,$ScalePad"
    } else {
        $VF = $ScalePad
    }

    # --- 6. FFmpeg arguments
    $Args = @(
        "-i", "`"$($File.FullName)`"",
        "-vf", $VF,
        "-vcodec", "libx265",
        "-crf", "22",
        "-tag:v", "hvc1",
        "-acodec", "aac",
        "-metadata:s:v", "rotate=0",
        "`"$TempOutputFile`""
    )

    $process = Start-Process -FilePath $FFmpegPath -ArgumentList $Args -Wait -NoNewWindow -PassThru

    if ($process.ExitCode -eq 0) {
        Write-HostSuccess ("Completed {0} - replacing original" -f $File.FullName)
        Remove-Item -Path $File.FullName -Force
        Move-Item -Path $TempOutputFile -Destination $FinalOutputFile -Force
    } else {
        Write-HostCaution ("Error processing {0}. Original file kept." -f $File.Name)
        if (Test-Path $TempOutputFile) { Remove-Item $TempOutputFile }
    }
}

Write-HostSuccess ("Done processing videos in {0}!" -f $SourceDir)
