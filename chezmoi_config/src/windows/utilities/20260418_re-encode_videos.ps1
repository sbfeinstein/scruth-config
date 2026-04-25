# This is a one-off script to re-encode our family media archive videos and save (a lot) of space
# I ran it manually (from IntelliJ) on April 18, 2026

$SourceDir = "D:\media\movies"
$FFmpegPath = "ffmpeg"

$Extensions = "*.mp4", "*.wmv", "*.mov", "*.3gp", "*.avi", "*.mkv", "*.mpg", "*.mpeg"
$VideoFiles = Get-ChildItem -Path $SourceDir -Include $Extensions -Recurse

Write-HostInfo "Re-encoding all video files in $SourceDir, recursively, including $Extensions"

foreach ($File in $VideoFiles) {
    # Check current codec using ffprobe
    $Codec = & ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$($File.FullName)"

    if ($Codec -eq "hevc") {
        Write-HostInfo "Skipping $($File.Name) - already encoded in HEVC."
        continue
    }

    $TempOutputFile = Join-Path $File.DirectoryName ($File.BaseName + "_tmp.mp4")
    $FinalOutputFile = Join-Path $File.DirectoryName ($File.BaseName + ".mp4")

    Write-HostInfo "Processing: $($File.FullName)"

    # Added -map_metadata 0 to preserve original dates/locations
    # These args and the commands below are equivalent, for example, to:
    #   ffmpeg -i 'The Matrix-old.mp4' -vcodec libx265 -crf 28 -tag:v hvc1 -acodec aac -map_metadata 0 'The Matrix.mp4'
    # Note the -crf param has substantial impact on quality and file size.  Lower = bigger file / better quality.
    # A value of 22 would generally be more or less undetectable from the original.
    # 28 seems to give good results for dramatic file size reduction while still being good enough for our
    # TV and project / casual viewings.  If we really care about seeing something in higher def, we can rent or
    # buy it case-by-case.
    $Args = "-i `"$($File.FullName)`" -vcodec libx265 -crf 28 -tag:v hvc1 -acodec aac -map_metadata 0 `"$TempOutputFile`""

    $process = Start-Process -FilePath $FFmpegPath -ArgumentList $Args -Wait -NoNewWindow -PassThru

    if ($process.ExitCode -eq 0) {
        Write-HostSuccess "Completed $($File.FullName) and replacing original"
        Remove-Item -Path $File.FullName -Force
        Move-Item -Path $TempOutputFile -Destination $FinalOutputFile -Force
    } else {
        Write-HostCaution "Error processing $($File.Name). Original file kept."
        if (Test-Path $TempOutputFile) { Remove-Item $TempOutputFile }
    }
}
Write-HostSuccess "Done processing videos in $SourceDir!"
