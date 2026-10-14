# Save slide timings back into PPTX with COM retry logic
$pptxPath = (Resolve-Path ".\MindGuard_AI_Presentation.pptx").Path

function Invoke-ComRetry {
    param([scriptblock]$Action, [int]$MaxRetries = 10, [int]$DelayMs = 500)
    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try { return & $Action } catch { Start-Sleep -Milliseconds $DelayMs }
    }
    throw "COM call failed after $MaxRetries retries"
}

$pptApp = New-Object -ComObject PowerPoint.Application
$pptApp.Visible = [Microsoft.Office.Core.MsoTriState]::msoTrue
Start-Sleep -Seconds 2

$pres = Invoke-ComRetry { $pptApp.Presentations.Open($pptxPath, $false, $false, $true) }
Start-Sleep -Seconds 2

$slideCount = Invoke-ComRetry { $pres.Slides.Count }
Write-Host "Slide count: $slideCount"

for ($i = 1; $i -le $slideCount; $i++) {
    $slide = Invoke-ComRetry { $pres.Slides.Item($i) }
    $duration = if ($i -eq $slideCount) { 18 } else { 11 }
    Invoke-ComRetry { $slide.SlideShowTransition.AdvanceOnTime  = [Microsoft.Office.Core.MsoTriState]::msoTrue }
    Invoke-ComRetry { $slide.SlideShowTransition.AdvanceTime    = $duration }
    Invoke-ComRetry { $slide.SlideShowTransition.AdvanceOnClick = [Microsoft.Office.Core.MsoTriState]::msoFalse }
    Write-Host "  Slide $i → ${duration}s"
}

Start-Sleep -Seconds 1
Invoke-ComRetry { $pres.Save() }
Write-Host "Timings saved to PPTX."

Invoke-ComRetry { $pres.Close() }
Invoke-ComRetry { $pptApp.Quit() }
[System.GC]::Collect()
Write-Host "Done."
