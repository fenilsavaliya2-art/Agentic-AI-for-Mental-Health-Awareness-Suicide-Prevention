# Export MindGuard_AI_Presentation.pptx → MP4 (150 seconds total)
# Slide timings: slides 1-12 = 11s each, slide 13 = 18s  (12×11 + 18 = 150s)

$pptxPath = (Resolve-Path ".\MindGuard_AI_Presentation.pptx").Path
$videoPath = [System.IO.Path]::ChangeExtension($pptxPath, ".mp4")

Write-Host "Opening PowerPoint..."
$pptApp = New-Object -ComObject PowerPoint.Application
$pptApp.Visible = [Microsoft.Office.Core.MsoTriState]::msoTrue

Write-Host "Loading presentation: $pptxPath"
$pres = $pptApp.Presentations.Open($pptxPath, $false, $false, $true)

Write-Host "Setting slide timings (150 s total across 13 slides)..."
$slideCount = $pres.Slides.Count
for ($i = 1; $i -le $slideCount; $i++) {
    $slide = $pres.Slides.Item($i)
    # Last slide gets 18s, all others get 11s
    if ($i -eq $slideCount) {
        $duration = 18
    } else {
        $duration = 11
    }
    $slide.SlideShowTransition.AdvanceOnTime  = [Microsoft.Office.Core.MsoTriState]::msoTrue
    $slide.SlideShowTransition.AdvanceTime    = $duration
    $slide.SlideShowTransition.AdvanceOnClick = [Microsoft.Office.Core.MsoTriState]::msoFalse
}

# Save timings back into the file
$pres.Save()

Write-Host "Exporting to MP4: $videoPath"
# ppSaveAsMP4 = 39  |  UseTimingsAndNarrations = 2  |  VertResolution 720  |  fps 24  |  quality 85
$pres.SaveAs($videoPath, 39)

# Wait for the export to complete (PowerPoint exports asynchronously)
Write-Host "Waiting for export to finish..."
$timeout = 300  # 5-minute safety timeout
$elapsed = 0
while (-not (Test-Path $videoPath) -or ((Get-Item $videoPath).Length -lt 100000)) {
    Start-Sleep -Seconds 3
    $elapsed += 3
    if ($elapsed -ge $timeout) {
        Write-Host "Timeout waiting for export."
        break
    }
    Write-Host "  ... still exporting ($elapsed s elapsed)"
}

$pres.Close()
$pptApp.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($pres)  | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($pptApp) | Out-Null
[System.GC]::Collect()

if (Test-Path $videoPath) {
    $size = (Get-Item $videoPath).Length / 1MB
    Write-Host "SUCCESS: Video created → $videoPath  ($([math]::Round($size,1)) MB)"
} else {
    Write-Host "ERROR: Video file not found at $videoPath"
}
