# ============================================================
# add_voiceover_ffmpeg.ps1
#
# Steps:
#   1. Generate per-slide WAV narrations using Windows SAPI TTS
#   2. Pad/trim each WAV to exactly match slide duration
#   3. Install ffmpeg via winget (if not already present)
#   4. Concatenate all WAVs into one audio track
#   5. Merge audio into the existing MP4 → final output with voiceover
#
# Run from mental_health_ai\ directory:
#   .\add_voiceover_ffmpeg.ps1
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$mp4In      = Join-Path $scriptDir "MindGuard_AI_Presentation.mp4"
$mp4Out     = Join-Path $scriptDir "MindGuard_AI_Presentation_voiced.mp4"
$audioDir   = Join-Path $scriptDir "voiceover_wav"
$concatList = Join-Path $audioDir  "concat_list.txt"
$mergedWav  = Join-Path $audioDir  "narration_full.wav"

if (-not (Test-Path $audioDir)) { New-Item -ItemType Directory -Path $audioDir | Out-Null }

# ── Slide narrations & durations ────────────────────────────
# Timings: slides 1-12 = 11 s, slide 13 = 18 s  (total 150 s)
$slides = @(
    @{ dur=11; text="Welcome to MindGuard A I - a compassionate Mental Health Awareness and Suicide Prevention agent, powered by I B M Granite and watsonx dot a i." },
    @{ dur=11; text="Millions of people lack immediate, judgment-free mental health support. MindGuard bridges that gap - available 24 hours a day, 7 days a week - for individuals, their loved ones, and educators." },
    @{ dur=11; text="Every user message flows through a risk triage engine, then a Retrieval-Augmented Generation pipeline, before reaching the I B M Granite large language model, which returns an empathetic, grounded response." },
    @{ dur=11; text="The system is built from three Python modules: agent dot p y orchestrates the conversation, rag engine performs semantic retrieval using FAISS, and the knowledge base provides curated clinical content and crisis triage." },
    @{ dur=11; text="The RAG pipeline embeds 13 curated documents with SentenceTransformers, indexes them in FAISS, retrieves the most relevant context for each query, and injects it directly into the Granite prompt." },
    @{ dur=11; text="MindGuard detects two risk tiers. HIGH risk phrases like want to die or kill myself trigger immediate 24-7 crisis helplines. MEDIUM risk phrases trigger empathetic support and a gentle nudge to professional care." },
    @{ dur=11; text="The knowledge base spans eight clinical categories - depression, anxiety, suicide prevention, mindfulness, self-care, stress, trauma, and peer support - with 13 evidence-based documents and 34 risk trigger phrases." },
    @{ dur=11; text="MindGuard uses I B M Granite 13 B Instruct version 2 with carefully tuned generation parameters, a detailed system prompt defining the MindGuard persona, and real-time injection of RAG context and conversation history." },
    @{ dur=11; text="In a typical exchange, a user expressing hopelessness receives an empathetic, evidence-based reply. If they indicate a crisis, MindGuard immediately surfaces 24-7 helplines - no delay, no friction." },
    @{ dur=11; text="The stack includes ibm-watsonx-ai, LangChain, SentenceTransformers, FAISS, Flask, and Python dotenv - all configured through a single dot env file with three environment variables." },
    @{ dur=11; text="Every response carries a mandatory medical disclaimer. MindGuard never suggests harmful actions, never diagnoses, and always refers serious concerns to qualified professionals using person-first language." },
    @{ dur=11; text="MindGuard demonstrates that I B M Granite and watsonx dot a i can power responsible, life-saving AI - combining empathetic tone, evidence-based RAG, real-time crisis detection, and strict ethical guardrails." },
    @{ dur=18; text="Thank you for watching. MindGuard A I - Mental Health Awareness and Suicide Prevention - built with I B M Granite 13 B, watsonx dot a i, FAISS, SentenceTransformers, Flask, and Python. Together, technology and compassion can save lives." }
)

# ── STEP 1: Generate WAVs via SAPI ──────────────────────────
Write-Host "`n[Step 1] Generating narration WAV files via Windows SAPI TTS..."

$sapi   = New-Object -ComObject SAPI.SpVoice
$voices = $sapi.GetVoices()

# Prefer Zira (female, clearer for presentations)
$chosenVoice = $null
for ($v = 0; $v -lt $voices.Count; $v++) {
    if ($voices.Item($v).GetDescription() -match "Zira") { $chosenVoice = $voices.Item($v); break }
}
if (-not $chosenVoice) {
    for ($v = 0; $v -lt $voices.Count; $v++) {
        if ($voices.Item($v).GetDescription() -match "David") { $chosenVoice = $voices.Item($v); break }
    }
}
if ($chosenVoice) {
    $sapi.Voice = $chosenVoice
    Write-Host "  Voice: $($chosenVoice.GetDescription())"
}

$rawWavs = @()

for ($i = 0; $i -lt $slides.Count; $i++) {
    $slideNum  = $i + 1
    $text      = $slides[$i].text
    $wavRaw    = Join-Path $audioDir "raw_slide_$slideNum.wav"
    $rawWavs  += $wavRaw

    # Set rate so speech fits the slide duration
    $wordCount = ($text -split '\s+').Count
    $dur       = $slides[$i].dur
    $wpm       = [math]::Round($wordCount / ($dur / 60))
    $wpm       = [math]::Max(120, [math]::Min(190, $wpm))
    # SAPI rate: 0=150wpm; each unit ~10wpm
    $rate      = [math]::Max(-4, [math]::Min(4, [math]::Round(($wpm - 150) / 10)))
    $sapi.Rate = $rate

    $stream = New-Object -ComObject SAPI.SpFileStream
    $stream.Open($wavRaw, 3, $false)   # SSFMCreateForWrite = 3
    $sapi.AudioOutputStream = $stream
    $sapi.Speak($text, 0)              # 0 = synchronous
    $stream.Close()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($stream) | Out-Null

    $kb = [math]::Round((Get-Item $wavRaw).Length / 1KB, 1)
    Write-Host "  Slide $slideNum/$($slides.Count) → $kb KB  (rate=$rate, ~$wpm wpm)"
}

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($sapi) | Out-Null
Write-Host "  All WAV files generated."

# ── STEP 2: Install FFmpeg if needed ────────────────────────
Write-Host "`n[Step 2] Checking for FFmpeg..."

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    # Try common manual install paths first
    $manualPaths = @(
        "C:\ffmpeg\bin\ffmpeg.exe",
        "C:\Program Files\ffmpeg\bin\ffmpeg.exe",
        "C:\tools\ffmpeg\bin\ffmpeg.exe",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Gyan.FFmpeg*\ffmpeg*\bin\ffmpeg.exe"
    )
    $found = $null
    foreach ($p in $manualPaths) {
        $resolved = Resolve-Path $p -ErrorAction SilentlyContinue
        if ($resolved) { $found = $resolved.Path; break }
    }
    if ($found) {
        $ffmpeg = $found
        Write-Host "  Found FFmpeg at: $found"
    } else {
        Write-Host "  FFmpeg not found - installing via winget..."
        winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("PATH","User")
        $ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
        if (-not $ffmpeg) {
            # winget installs to a versioned folder - find it
            $wingetPkg = Resolve-Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Gyan.FFmpeg*" -ErrorAction SilentlyContinue
            if ($wingetPkg) {
                $ffmpegExe = Get-ChildItem $wingetPkg.Path -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($ffmpegExe) { $ffmpeg = $ffmpegExe.FullName }
            }
        }
    }
}

$ffmpegExe = if ($ffmpeg -is [string]) { $ffmpeg } else { $ffmpeg.Source }
if (-not $ffmpegExe -or -not (Test-Path $ffmpegExe)) {
    Write-Error "FFmpeg could not be located. Please install manually from https://ffmpeg.org/download.html and add to PATH."
}
Write-Host "  FFmpeg: $ffmpegExe"

# ── STEP 3: Pad/trim each WAV to exact slide duration ───────
Write-Host "`n[Step 3] Padding WAVs to exact slide durations..."

$paddedWavs = @()
for ($i = 0; $i -lt $slides.Count; $i++) {
    $slideNum   = $i + 1
    $dur        = $slides[$i].dur
    $rawWav     = $rawWavs[$i]
    $paddedWav  = Join-Path $audioDir "padded_slide_$slideNum.wav"
    $paddedWavs += $paddedWav

    # apad adds silence at the end; atrim cuts to exact duration
    & $ffmpegExe -y -i $rawWav `
        -af "apad=whole_dur=${dur},atrim=duration=$dur" `
        -ar 44100 -ac 1 `
        $paddedWav 2>&1 | Out-Null

    $kb = [math]::Round((Get-Item $paddedWav).Length / 1KB, 1)
    Write-Host "  Slide $slideNum → ${dur}s  ($kb KB)"
}

# ── STEP 4: Concatenate all padded WAVs ─────────────────────
Write-Host "`n[Step 4] Concatenating all slides into one audio track..."

# Build ffmpeg concat list
$concatContent = $paddedWavs | ForEach-Object { "file '$($_ -replace "\\","/" )'" }
$concatContent | Set-Content -Path $concatList -Encoding UTF8

& $ffmpegExe -y -f concat -safe 0 -i $concatList `
    -ar 44100 -ac 1 `
    $mergedWav 2>&1 | Out-Null

$mergedKB = [math]::Round((Get-Item $mergedWav).Length / 1KB, 1)
$mergedDur = (150)   # 12×11 + 18 = 150 s
Write-Host "  Merged audio: $mergedWav  ($mergedKB KB, $mergedDur s)"

# ── STEP 5: Merge audio into MP4 ────────────────────────────
Write-Host "`n[Step 5] Merging narration audio into MP4..."

if (-not (Test-Path $mp4In)) {
    Write-Error "Source MP4 not found: $mp4In"
}

# -shortest keeps video length; -map 0:v + 1:a replaces original audio
& $ffmpegExe -y `
    -i $mp4In `
    -i $mergedWav `
    -map 0:v -map 1:a `
    -c:v copy `
    -c:a aac -b:a 128k `
    -shortest `
    $mp4Out 2>&1 | Out-Null

if (Test-Path $mp4Out) {
    $sizeMB = [math]::Round((Get-Item $mp4Out).Length / 1MB, 1)
    Write-Host "`n✅ SUCCESS: $mp4Out  ($sizeMB MB)"
    Write-Host "   Play it to hear the narration!"
} else {
    Write-Error "Output MP4 was not created. Check FFmpeg output above."
}

# ── Optional: replace original MP4 ─────────────────────────
$replace = Read-Host "`nReplace original MindGuard_AI_Presentation.mp4 with voiced version? (y/n)"
if ($replace -eq 'y') {
    Copy-Item -Path $mp4Out -Destination $mp4In -Force
    Write-Host "  Original MP4 replaced with voiced version."
}
