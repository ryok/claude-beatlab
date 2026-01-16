---
description: Generate a new 16-step beat (JSON + ASCII grid + MIDI + WAV). Manual-only.
argument-hint: "<style prompt>"
disable-model-invocation: true
allowed-tools: Read, Write, Bash(date:*), Bash(which:*), Bash(mkdir:*), Bash(uv:*), Bash(ffmpeg:*)
---

## Context (auto-collected)
- run_id: !`date +%Y%m%d_%H%M%S`
- ffmpeg: !`which ffmpeg || echo "(no ffmpeg)"`

## Input
User requested beat style: "$ARGUMENTS"

## Task: BeatLab pipeline (explicit, deterministic)
You are the orchestrator. Use subagents + pipeline scripts.

### Step 0: Prepare dirs
- Ensure `beats/` and `.beatlab/` exist.
- Create output dir: `beats/<run_id>/`

### Step 1: Generate (up to 3 attempts)
Repeat up to 3 times until validate succeeds:
1) Ask the `music-reference-agent` subagent for a BeatSpec YAML based on "$ARGUMENTS".
2) Ask the `music-generation-agent` subagent to generate Beat JSON from that BeatSpec.
3) Write the JSON to `beats/<run_id>/beat.json`
4) Run validator (normalize inplace):
   uv run python .claude/skills/beatlab-pipeline/scripts/validate.py beats/<run_id>/beat.json --inplace
5) If validation fails, take the validator errors and ask `music-generation-agent` to fix the JSON (still ONLY JSON), then overwrite beat.json and retry.

### Step 2: Update current
- Copy `beats/<run_id>/beat.json` to `.beatlab/current.json`

### Step 3: Render grid
- Run:
  uv run python .claude/skills/beatlab-pipeline/scripts/render_grid.py beats/<run_id>/beat.json
- Include the ASCII grid in the final response.

### Step 4: Export files
- MIDI:
  uv run python .claude/skills/beatlab-pipeline/scripts/export_midi.py beats/<run_id>/beat.json beats/<run_id>/beat.mid
- WAV:
  uv run python .claude/skills/beatlab-pipeline/scripts/render_wav.py beats/<run_id>/beat.json beats/<run_id>/beat.wav
- If ffmpeg exists, also:
  ffmpeg -y -i beats/<run_id>/beat.wav beats/<run_id>/beat.mp3

### Final response format
- Summary: bpm, swing, run_id
- Paths to beat.json / beat.mid / beat.wav (and beat.mp3 if created)
- The ASCII 16-step grid
