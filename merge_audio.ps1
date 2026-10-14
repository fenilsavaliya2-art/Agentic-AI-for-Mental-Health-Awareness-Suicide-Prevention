# ============================================================
# merge_audio.ps1
# Pure PowerShell + .NET - no FFmpeg, no Python needed.
#
# 1. Reads existing per-slide WAV files from voiceover_wav\
# 2. Pads / trims each to its exact slide duration using .NET BinaryReader
# 3. Concatenates into one narration_full.wav
# 4. Uses Windows Shell (WScript.Shell) + PowerPoint COM to
#    embed the audio track and re-export the MP4 with narration.
#
# Run from mental_health_ai\ :
#   .\merge_audio.ps1
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$audioDir   = Join-Path $scriptDir "voiceover_wav"
$mergedWav  = Join-Path $audioDir  "narration_full.wav"
$pptxPath   = (Resolve-Path (Join-Path $scriptDir "MindGuard_AI_Presentation.pptx")).Path
$mp4Out     = Join-Path $scriptDir "MindGuard_AI_Presentation_voiced.mp4"

# Slide durations (must match export_video.ps1)
$durations = @(11,11,11,11,11,11,11,11,11,11,11,11,18)

# ── WAV helper functions ─────────────────────────────────────

function Read-WavData {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    # Parse WAV header: "RIFF....WAVEfmt " chunk then "data" chunk
    $ms   = New-Object System.IO.MemoryStream(,$bytes)
    $br   = New-Object System.IO.BinaryReader($ms)

    $riff = [System.Text.Encoding]::ASCII.GetString($br.ReadBytes(4))
    $br.ReadInt32() | Out-Null   # file size - 8
    $wave = [System.Text.Encoding]::ASCII.GetString($br.ReadBytes(4))

    if ($riff -ne "RIFF" -or $wave -ne "WAVE") { throw "Not a valid WAV: $Path" }

    $sampleRate = 0; $channels = 0; $bitsPerSample = 0; $dataBytes = $null

    while ($ms.Position -lt $ms.Length - 8) {
        $chunkId   = [System.Text.Encoding]::ASCII.GetString($br.ReadBytes(4))
        $chunkSize = $br.ReadInt32()
        if ($chunkId -eq "fmt ") {
            $br.ReadInt16() | Out-Null          # audio format (PCM=1)
            $channels      = $br.ReadInt16()
            $sampleRate    = $br.ReadInt32()
            $br.ReadInt32() | Out-Null          # byte rate
            $br.ReadInt16() | Out-Null          # block align
            $bitsPerSample = $br.ReadInt16()
            if ($chunkSize -gt 16) { $br.ReadBytes($chunkSize - 16) | Out-Null }
        } elseif ($chunkId -eq "data") {
            $dataBytes = $br.ReadBytes($chunkSize)
        } else {
            if ($chunkSize -gt 0) { $br.ReadBytes($chunkSize) | Out-Null }
        }
    }
    $br.Close(); $ms.Close()

    return @{
        SampleRate    = $sampleRate
        Channels      = $channels
        BitsPerSample = $bitsPerSample
        Data          = $dataBytes
    }
}

function Write-WavFile {
    param([string]$Path, [hashtable]$Wav)
    $dataLen   = $Wav.Data.Length
    $byteRate  = $Wav.SampleRate * $Wav.Channels * ($Wav.BitsPerSample / 8)
    $blockAlign= $Wav.Channels * ($Wav.BitsPerSample / 8)

    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)

    $bw.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
    $bw.Write([int32]($dataLen + 36))
    $bw.Write([System.Text.Encoding]::ASCII.GetBytes("WAVE"))
    $bw.Write([System.Text.Encoding]::ASCII.GetBytes("fmt "))
    $bw.Write([int32]16)
    $bw.Write([int16]1)                          # PCM
    $bw.Write([int16]$Wav.Channels)
    $bw.Write([int32]$Wav.SampleRate)
    $bw.Write([int32]$byteRate)
    $bw.Write([int16]$blockAlign)
    $bw.Write([int16]$Wav.BitsPerSample)
    $bw.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
    $bw.Write([int32]$dataLen)
    $bw.Write($Wav.Data)
    $bw.Flush()

    [System.IO.File]::WriteAllBytes($Path, $ms.ToArray())
    $bw.Close(); $ms.Close()
}

function Pad-WavToSeconds {
    param([hashtable]$Wav, [int]$Seconds)
    $bytesPerSec = $Wav.SampleRate * $Wav.Channels * ($Wav.BitsPerSample / 8)
    $targetBytes = $Seconds * $bytesPerSec

    if ($Wav.Data.Length -ge $targetBytes) {
        # Trim
        $trimmed = New-Object byte[] $targetBytes
        [Array]::Copy($Wav.Data, $trimmed, $targetBytes)
        $Wav.Data = $trimmed
    } else {
        # Pad with silence (zeros)
        $padded = New-Object byte[] $targetBytes
        [Array]::Copy($Wav.Data, $padded, $Wav.Data.Length)
        $Wav.Data = $padded
    }
    return $Wav
}

# ── STEP 1: Pad each WAV and concatenate ────────────────────
Write-Host "`n[Step 1] Padding WAVs to slide durations and concatenating..."

$allData   = New-Object System.Collections.Generic.List[byte]
$masterWav = $null

for ($i = 1; $i -le 13; $i++) {
    $wavPath = Join-Path $audioDir "raw_slide_$i.wav"
    if (-not (Test-Path $wavPath)) { throw "Missing: $wavPath" }

    $wav = Read-WavData -Path $wavPath
    $dur = $durations[$i - 1]
    $wav = Pad-WavToSeconds -Wav $wav -Seconds $dur

    if ($null -eq $masterWav) { $masterWav = $wav }   # grab format from first slide
    $allData.AddRange($wav.Data)

    $kb = [math]::Round($wav.Data.Length / 1KB, 0)
    Write-Host "  Slide $i - ${dur}s - $kb KB"
}

$masterWav.Data = $allData.ToArray()
Write-Host "  Total audio: $([math]::Round($masterWav.Data.Length/1KB,0)) KB  ($($masterWav.SampleRate) Hz, $($masterWav.Channels)ch, $($masterWav.BitsPerSample)-bit)"

# ── STEP 2: Write merged WAV ─────────────────────────────────
Write-Host "`n[Step 2] Writing narration_full.wav..."
Write-WavFile -Path $mergedWav -Wav $masterWav
$sizeMB = [math]::Round((Get-Item $mergedWav).Length / 1MB, 2)
Write-Host "  Saved: $mergedWav  ($sizeMB MB)"

# ── STEP 3: Embed audio in PPTX + export MP4 ────────────────
Write-Host "`n[Step 3] Opening PowerPoint, embedding audio, exporting MP4..."

$pptApp = $null
$retries = 5
for ($r = 1; $r -le $retries; $r++) {
    try {
        $pptApp = New-Object -ComObject PowerPoint.Application
        if ($pptApp) { break }
    } catch {
        Write-Host "  COM init attempt $r failed, retrying..."
        Start-Sleep -Seconds 3
    }
}
if (-not $pptApp) { throw "Could not start PowerPoint COM object after $retries attempts." }

$pptApp.Visible = 1   # msoTrue = 1 (avoid enum resolution issue)
Start-Sleep -Seconds 3

$pres = $null
for ($r = 1; $r -le $retries; $r++) {
    try {
        $pres = $pptApp.Presentations.Open($pptxPath, $false, $false, $true)
        if ($pres) { break }
    } catch {
        Write-Host "  Open attempt $r failed, retrying..."
        Start-Sleep -Seconds 3
    }
}
if (-not $pres) { throw "Could not open PPTX: $pptxPath" }
Start-Sleep -Seconds 2

$slideCount = $pres.Slides.Count
Write-Host "  Slides: $slideCount"

# Offset tracker: where in the full audio each slide starts (seconds)
$offsetSec = 0

for ($i = 1; $i -le $slideCount; $i++) {
    $slide = $pres.Slides.Item($i)
    $dur   = $durations[$i - 1]

    # Remove existing media on this slide
    $toRemove = @()
    foreach ($shape in $slide.Shapes) { if ($shape.Type -eq 16) { $toRemove += $shape } }
    foreach ($shape in $toRemove) { $shape.Delete() }

    # Write a trimmed WAV just for this slide
    $slideWavPath = Join-Path $audioDir "final_slide_$i.wav"
    $bytesPerSec  = $masterWav.SampleRate * $masterWav.Channels * ($masterWav.BitsPerSample / 8)
    $startByte    = $offsetSec * $bytesPerSec
    $lengthBytes  = $dur * $bytesPerSec
    $slideData    = New-Object byte[] $lengthBytes
    $copyLen      = [math]::Min($lengthBytes, $masterWav.Data.Length - $startByte)
    if ($copyLen -gt 0) {
        [Array]::Copy($masterWav.Data, $startByte, $slideData, 0, $copyLen)
    }
    $slideWav      = @{ SampleRate=$masterWav.SampleRate; Channels=$masterWav.Channels; BitsPerSample=$masterWav.BitsPerSample; Data=$slideData }
    Write-WavFile -Path $slideWavPath -Wav $slideWav

    # Embed as media object - saved with document
    $audioShape = $slide.Shapes.AddMediaObject2($slideWavPath, $false, $true, 1, 1)
    $audioShape.Width  = 1
    $audioShape.Height = 1
    $audioShape.Visible = [Microsoft.Office.Core.MsoTriState]::msoFalse

    # Auto-play on slide entry via MediaFormat settings
    try {
        $audioShape.AnimationSettings.PlaySettings.PlayOnEntry = $true
        $audioShape.AnimationSettings.PlaySettings.HideWhileNotPlaying = $true
    } catch {
        # Fallback: use TimeLine AddEffect with numeric enum
        try {
            # msoAnimEffectMediaPlay=3846, msoAnimateLevelNone=0, msoAnimTriggerWithPrevious=3
            $eff = $slide.TimeLine.MainSequence.AddEffect($audioShape, 3846, 0, 3)
            $eff.Timing.TriggerType = 3
            $eff.Timing.Duration    = $dur
        } catch {
            Write-Host "    (Animation not set for slide $i - audio still embedded)"
        }
    }

    # Slide advance timing
    $slide.SlideShowTransition.AdvanceOnTime  = [Microsoft.Office.Core.MsoTriState]::msoTrue
    $slide.SlideShowTransition.AdvanceTime    = $dur
    $slide.SlideShowTransition.AdvanceOnClick = [Microsoft.Office.Core.MsoTriState]::msoFalse

    $offsetSec += $dur
    Write-Host "  Slide $i embedded ($dur s)"
}

Write-Host "`n  Saving PPTX with narrations embedded..."
$pptxSaved = Join-Path $scriptDir "MindGuard_AI_Presentation_voiced.pptx"
$pres.SaveAs($pptxSaved, 1)   # 1 = ppSaveAsDefault (.pptx)
Write-Host "  PPTX saved: $pptxSaved"

Write-Host "  Exporting MP4 with narration..."
$pres.SaveAs($mp4Out, 39)   # 39 = ppSaveAsMP4

# Wait for async export
$timeout = 300; $elapsed = 0
while (-not (Test-Path $mp4Out) -or ((Get-Item $mp4Out).Length -lt 100000)) {
    Start-Sleep -Seconds 3; $elapsed += 3
    if ($elapsed -ge $timeout) { Write-Host "  Timeout."; break }
    Write-Host "  ... $elapsed s"
}

$pres.Close()
$pptApp.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($pres)   | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($pptApp) | Out-Null
[System.GC]::Collect()

# ── Result ──────────────────────────────────────────────────
if (Test-Path $mp4Out) {
    $mb = [math]::Round((Get-Item $mp4Out).Length / 1MB, 1)
    Write-Host "`n✅ Done! $mp4Out  ($mb MB)"
    Write-Host "   Play it - voice narration is embedded."
} else {
    Write-Host "`n❌ MP4 not found. Check PowerPoint export."
}
