# ============================================================
# add_voiceover.ps1
# Generates per-slide TTS narration (Windows SAPI) and embeds
# it into MindGuard_AI_Presentation.pptx, then re-exports MP4.
#
# Requirements: PowerPoint installed, Windows SAPI voices present.
# Run from the mental_health_ai\ directory:
#   .\add_voiceover.ps1
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Paths ────────────────────────────────────────────────────
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$pptxPath  = Join-Path $scriptDir "MindGuard_AI_Presentation.pptx"
$videoPath = Join-Path $scriptDir "MindGuard_AI_Presentation.mp4"
$audioDir  = Join-Path $scriptDir "voiceover_wav"

if (-not (Test-Path $audioDir)) { New-Item -ItemType Directory -Path $audioDir | Out-Null }

# ── Slide narration scripts ──────────────────────────────────
# Timings: slides 1-12 = 11 s each, slide 13 = 18 s  (150 s total)
$narrations = @(
    # Slide 1 — Title  (11 s)
    "Welcome to MindGuard A I — a compassionate Mental Health Awareness and Suicide Prevention agent, " +
    "powered by I B M Granite and watsonx dot a i.",

    # Slide 2 — Project Overview  (11 s)
    "Millions of people lack immediate, judgment-free mental health support. " +
    "MindGuard bridges that gap — available 24 hours a day, 7 days a week — for individuals, their loved ones, and educators.",

    # Slide 3 — System Architecture  (11 s)
    "Every user message flows through a risk triage engine, then a Retrieval-Augmented Generation pipeline, " +
    "before reaching the I B M Granite large language model, which returns an empathetic, grounded response.",

    # Slide 4 — Core Modules  (11 s)
    "The system is built from three Python modules: agent dot p y orchestrates the conversation, " +
    "rag underscore engine dot p y performs semantic retrieval using FAISS, " +
    "and knowledge underscore base dot p y provides curated clinical content and crisis triage.",

    # Slide 5 — RAG Pipeline  (11 s)
    "The RAG pipeline embeds 13 curated documents with SentenceTransformers, indexes them in FAISS, " +
    "retrieves the most relevant context for each query, and injects it directly into the Granite prompt.",

    # Slide 6 — Crisis Detection  (11 s)
    "MindGuard detects two risk tiers. HIGH risk phrases like 'want to die' or 'kill myself' trigger " +
    "immediate 24-7 crisis helplines. MEDIUM risk phrases trigger empathetic support and a gentle nudge to professional care.",

    # Slide 7 — Knowledge Base  (11 s)
    "The knowledge base spans eight clinical categories — depression, anxiety, suicide prevention, mindfulness, " +
    "self-care, stress, trauma, and peer support — with 13 evidence-based documents and 34 risk trigger phrases.",

    # Slide 8 — Granite Integration  (11 s)
    "MindGuard uses I B M Granite 13 B Instruct version 2 with carefully tuned generation parameters, " +
    "a detailed system prompt defining the M I N D G U A R D persona, and real-time injection of RAG context and conversation history.",

    # Slide 9 — Sample Conversation  (11 s)
    "In a typical exchange, a user expressing hopelessness receives an empathetic, evidence-based reply. " +
    "If they indicate a crisis, MindGuard immediately surfaces 24-7 helplines — no delay, no friction.",

    # Slide 10 — Tech Stack  (11 s)
    "The stack includes ibm-watsonx-ai, LangChain, SentenceTransformers, FAISS, Flask, and Python dot env — " +
    "all configured through a single dot env file with three environment variables.",

    # Slide 11 — Ethics & Safety  (11 s)
    "Every response carries a mandatory medical disclaimer. MindGuard never suggests harmful actions, " +
    "never diagnoses, and always refers serious concerns to qualified professionals using person-first language.",

    # Slide 12 — Summary & Impact  (11 s)
    "MindGuard demonstrates that I B M Granite and watsonx dot a i can power responsible, life-saving AI — " +
    "combining empathetic tone, evidence-based RAG, real-time crisis detection, and strict ethical guardrails.",

    # Slide 13 — Thank You  (18 s)
    "Thank you for watching. MindGuard A I — Mental Health Awareness and Suicide Prevention — " +
    "built with I B M Granite 13 B, watsonx dot a i, FAISS, SentenceTransformers, Flask, and Python. " +
    "Together, technology and compassion can save lives."
)

# Slide durations in seconds (must match export_video.ps1 timings)
$durations = @(11,11,11,11,11,11,11,11,11,11,11,11,18)

# ── Step 1: Render narrations to WAV via Windows SAPI ───────
Write-Host "`n[Step 1] Synthesising narration WAV files via Windows SAPI..."

$sapi = New-Object -ComObject SAPI.SpVoice

# Pick the best available voice (prefer a natural-sounding one)
$voices = $sapi.GetVoices()
$chosenVoice = $null
$preferredNames = @("Zira","David","Mark","Hazel","Susan","George")
foreach ($name in $preferredNames) {
    for ($v = 0; $v -lt $voices.Count; $v++) {
        if ($voices.Item($v).GetDescription() -match $name) {
            $chosenVoice = $voices.Item($v)
            break
        }
    }
    if ($chosenVoice) { break }
}
if ($chosenVoice) {
    $sapi.Voice = $chosenVoice
    Write-Host "  Using voice: $($chosenVoice.GetDescription())"
} else {
    Write-Host "  Using default system voice."
}

$wavPaths = @()

for ($i = 0; $i -lt $narrations.Count; $i++) {
    $slideNum = $i + 1
    $wavFile  = Join-Path $audioDir "slide_$slideNum.wav"
    $wavPaths += $wavFile

    # Estimate words-per-minute needed for the allocated duration
    $wordCount     = ($narrations[$i] -split '\s+').Count
    $targetSeconds = $durations[$i]
    # WPM = words / (seconds/60).  Clamp between 120 and 200.
    $wpm = [math]::Round($wordCount / ($targetSeconds / 60))
    $wpm = [math]::Max(120, [math]::Min(200, $wpm))
    # SAPI rate: -10 (slowest) to 10 (fastest). 0 ≈ 150 WPM. Each step ≈ 10%.
    $rate = [math]::Round(($wpm - 150) / 10)
    $rate = [math]::Max(-5, [math]::Min(5, $rate))
    $sapi.Rate = $rate

    # Write to WAV via SpFileStream
    $stream = New-Object -ComObject SAPI.SpFileStream
    # SSFMCreateForWrite = 3
    $stream.Open($wavFile, 3, $false)
    $sapi.AudioOutputStream = $stream
    $sapi.Speak($narrations[$i], 0)   # 0 = synchronous
    $stream.Close()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($stream) | Out-Null

    $sizekb = [math]::Round((Get-Item $wavFile).Length / 1KB, 1)
    Write-Host "  Slide $slideNum → $wavFile  ($sizekb KB, rate=$rate)"
}

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($sapi) | Out-Null
Write-Host "  All WAV files generated."

# ── Step 2: Open PPTX and embed audio on each slide ─────────
Write-Host "`n[Step 2] Opening PowerPoint and embedding narration audio..."

$pptApp = New-Object -ComObject PowerPoint.Application
$pptApp.Visible = [Microsoft.Office.Core.MsoTriState]::msoTrue
Start-Sleep -Seconds 2

$pres = $pptApp.Presentations.Open($pptxPath, $false, $false, $true)
Start-Sleep -Seconds 1

$slideCount = $pres.Slides.Count
Write-Host "  Presentation has $slideCount slides."

for ($i = 1; $i -le $slideCount; $i++) {
    $slide   = $pres.Slides.Item($i)
    $wavFile = $wavPaths[$i - 1]

    if (-not (Test-Path $wavFile)) {
        Write-Host "  [WARN] WAV missing for slide $i — skipping."
        continue
    }

    # ── Remove any existing audio shapes on this slide ──────
    $toRemove = @()
    foreach ($shape in $slide.Shapes) {
        if ($shape.Type -eq 16) {   # msoMedia = 16
            $toRemove += $shape
        }
    }
    foreach ($shape in $toRemove) { $shape.Delete() }

    # ── Add the WAV as a media object (hidden, auto-play) ───
    # AddMediaObject2(fileName, linkToFile, saveWithDocument, left, top)
    $audioShape = $slide.Shapes.AddMediaObject2($wavFile, $false, $true, 10, 10)
    $audioShape.Width  = 1
    $audioShape.Height = 1
    $audioShape.Visible = [Microsoft.Office.Core.MsoTriState]::msoFalse

    # Set to auto-play when the slide is shown
    $effect = $slide.TimeLine.MainSequence.AddEffect(
        $audioShape,
        [Microsoft.Office.Interop.PowerPoint.MsoAnimEffect]::msoAnimEffectMediaPlay,  # 3846
        [Microsoft.Office.Interop.PowerPoint.MsoAnimateByLevel]::msoAnimateLevelNone, # 0
        [Microsoft.Office.Interop.PowerPoint.MsoAnimTriggerType]::msoAnimTriggerWithPrevious # 3
    )
    $effect.Timing.TriggerType = 3   # msoAnimTriggerWithPrevious — plays on slide entry
    $effect.Timing.Duration    = $durations[$i - 1]

    # Slide timing
    $slide.SlideShowTransition.AdvanceOnTime  = [Microsoft.Office.Core.MsoTriState]::msoTrue
    $slide.SlideShowTransition.AdvanceTime    = $durations[$i - 1]
    $slide.SlideShowTransition.AdvanceOnClick = [Microsoft.Office.Core.MsoTriState]::msoFalse

    Write-Host "  Slide $i — audio embedded, advance in $($durations[$i-1]) s"
}

Write-Host "`n  Saving PPTX with embedded narrations..."
$pres.Save()
Write-Host "  Saved."

# ── Step 3: Export to MP4 with narrations ───────────────────
Write-Host "`n[Step 3] Exporting to MP4 with narrations..."

# ppSaveAsMP4 = 39  |  UseTimingsAndNarrations = 2
$pres.SaveAs($videoPath, 39)

Write-Host "  Waiting for export to complete..."
$timeout = 360
$elapsed = 0
while (-not (Test-Path $videoPath) -or ((Get-Item $videoPath).Length -lt 100000)) {
    Start-Sleep -Seconds 3
    $elapsed += 3
    if ($elapsed -ge $timeout) { Write-Host "  Timeout — export may still be running."; break }
    Write-Host "  ... $elapsed s elapsed"
}

$pres.Close()
$pptApp.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($pres)   | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($pptApp) | Out-Null
[System.GC]::Collect()

# ── Result ──────────────────────────────────────────────────
if (Test-Path $videoPath) {
    $sizeMB = [math]::Round((Get-Item $videoPath).Length / 1MB, 1)
    Write-Host "`n✅ SUCCESS: $videoPath  ($sizeMB MB)"
} else {
    Write-Host "`n❌ ERROR: MP4 not found at $videoPath"
}
