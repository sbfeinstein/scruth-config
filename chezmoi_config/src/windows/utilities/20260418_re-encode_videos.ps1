# This is a one-off script to re-encode our family media archive videos and save (a lot) of space
# I ran it manually (from IntelliJ) on April 18, 2026

# Set your source directory
$SourceDir = "D:\family media archives"
$FFmpegPath = "ffmpeg"

$Extensions = "*.mp4", "*.wmv", "*.mov", "*.3gp", "*.avi"
$VideoFiles = Get-ChildItem -Path $SourceDir -Include $Extensions -Recurse

Write-HostInfo "Re-encoding all video files in $SourceDir, recursively, including $Extensions"

foreach ($File in $VideoFiles) {
    $TempOutputFile = Join-Path $File.DirectoryName ($File.BaseName + "_tmp.mp4")
    $FinalOutputFile = Join-Path $File.DirectoryName ($File.BaseName + ".mp4")

    Write-HostInfo "Processing: $($File.FullName)"

    # Run FFmpeg
    $process = Start-Process -FilePath $FFmpegPath -ArgumentList "-i `"$($File.FullName)`" -vcodec libx265 -crf 28 -tag:v hvc1 -acodec aac `"$TempOutputFile`"" -Wait -NoNewWindow -PassThru

    if ($process.ExitCode -eq 0) {
        Write-HostSuccess "Completed $($File.FullName) and replacing original"

        # Remove the original file
        Remove-Item -Path $File.FullName -Force

        # Rename the temp file to the final name (cleans up suffix and ensures .mp4)
        # If the original was already .mp4, it simply replaces it.
        Move-Item -Path $TempOutputFile -Destination $FinalOutputFile -Force
    } else {
        Write-HostCaution "Error processing $($File.Name). Original file kept, cleaning up temp file."
        if (Test-Path $TempOutputFile) { Remove-Item $TempOutputFile }
    }
}
Write-HostSuccess "All processing complete!"
