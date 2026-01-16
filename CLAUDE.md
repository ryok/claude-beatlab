# claude-beatlab

This repo turns Claude Code into a 16-step beat sequencer.

## Prerequisites

- Python 3.12+ (managed via uv)
- ffmpeg (optional, for MP3 export)

## Usage

Generate a beat:
```
/beat "<style prompt>"
```

Example:
```
/beat "lofi, jazzy, dusty, 92bpm, minimal melody"
```

## Output

Each `/beat` run produces:
- ASCII 16-step grid displayed in the response
- `beats/<run_id>/beat.json` - Beat data in BeatLab JSON format
- `beats/<run_id>/beat.mid` - MIDI file for DAW import
- `beats/<run_id>/beat.wav` - Audio render
- `beats/<run_id>/beat.mp3` - (optional, if ffmpeg exists)
- `.beatlab/current.json` - Updated with latest beat

## Architecture

```
/beat "<prompt>"
    ↓
music-reference-agent → BeatSpec (YAML)
    ↓
music-generation-agent → Beat JSON
    ↓
validate.py → OK/NG (retry up to 3x if NG)
    ↓
render_grid.py → ASCII grid
export_midi.py → .mid
render_wav.py → .wav
(ffmpeg → .mp3)
```

## Rules

- Always validate Beat JSON with `beatlab-pipeline/scripts/validate.py`
- 16 steps only (0-15)
- Only allowed notes and drums per `beatlab-contract`
- Use `uv run python` to execute scripts

## Beat JSON Contract (Mastra AI Beats Lab compatible)

```json
{
  "bpm": 92,
  "swing": 0.1,
  "pianoSequence": {
    "C5": [0, 7],
    "B4": [],
    "A4": [],
    "G4": [4],
    "F4": [],
    "E4": [],
    "D4": [],
    "C4": [],
    "B3": [],
    "A3": [],
    "G3": []
  },
  "drumSequence": {
    "Kick": [0, 8],
    "Snare": [4, 12],
    "HiHat": [2, 6, 10, 14],
    "Clap": [],
    "OpenHat": [],
    "Tom": [],
    "Crash": [],
    "Ride": [],
    "Shaker": [],
    "Cowbell": []
  }
}
```

### Allowed Piano Notes (fixed)
C5, B4, A4, G4, F4, E4, D4, C4, B3, A3, G3

### Allowed Drum Sounds (fixed)
Kick, Snare, HiHat, Clap, OpenHat, Tom, Crash, Ride, Shaker, Cowbell

## Directory Structure

```
claude-beatlab/
  CLAUDE.md
  pyproject.toml
  .python-version
  .claude/
    commands/
      beat.md
    agents/
      music-reference-agent.md
      music-generation-agent.md
    skills/
      beatlab-contract/
        SKILL.md
      beatlab-pipeline/
        SKILL.md
        scripts/
          validate.py
          render_grid.py
          export_midi.py
          render_wav.py
  beats/
  .beatlab/
    current.json
```

## Pipeline Scripts

Scripts are in `.claude/skills/beatlab-pipeline/scripts/`. Run via uv (do NOT read into context):

| Script | Command |
|--------|---------|
| Validate & normalize | `uv run python .claude/skills/beatlab-pipeline/scripts/validate.py <beat.json> --inplace` |
| ASCII grid | `uv run python .claude/skills/beatlab-pipeline/scripts/render_grid.py <beat.json>` |
| Export MIDI | `uv run python .claude/skills/beatlab-pipeline/scripts/export_midi.py <beat.json> <out.mid>` |
| Render WAV | `uv run python .claude/skills/beatlab-pipeline/scripts/render_wav.py <beat.json> <out.wav>` |

## Subagents

| Agent | Role | Model |
|-------|------|-------|
| `music-reference-agent` | Style prompt → BeatSpec YAML | haiku |
| `music-generation-agent` | BeatSpec → Beat JSON | sonnet |
