#!/bin/bash
# PostToolUse hook: Play generated beat audio (macOS)

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Trigger on ffmpeg MP3 conversion (final step)
if [[ "$command" == *"ffmpeg"* ]] && [[ "$command" == *"beat.mp3"* ]]; then
  mp3_path=$(echo "$command" | grep -oE 'beats/[0-9_]+/beat\.mp3')
  if [ -f "$mp3_path" ]; then
    afplay "$mp3_path" &
  fi
# Fallback: play WAV if no ffmpeg available
elif [[ "$command" == *"render_wav.py"* ]] && [[ "$command" == *".wav"* ]]; then
  wav_path=$(echo "$command" | grep -oE 'beats/[0-9_]+/beat\.wav')
  if ! command -v ffmpeg &> /dev/null && [ -f "$wav_path" ]; then
    afplay "$wav_path" &
  fi
fi

echo '{"continue": true}'
exit 0
