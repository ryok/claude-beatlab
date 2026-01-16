# claude-beatlab

Claude Code を 16ステップのビートシーケンサーに変える実験的プロジェクト。

## 概要

スタイルプロンプトを入力すると、Claude Code がビートを生成し、JSON / MIDI / WAV / MP3 として出力します。

```
/beat "lofi, jazzy, dusty, 92bpm, minimal melody"
```

## 必要環境

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (CLI)
- Python 3.12+
- [uv](https://docs.astral.sh/uv/) (Python パッケージマネージャー)
- ffmpeg (オプション、MP3出力用)

## セットアップ

```bash
# リポジトリをクローン
git clone <repo-url>
cd claude-beatlab

# Python環境をセットアップ (uvが自動で.venvを作成)
uv sync
```

## 使い方

Claude Code を起動してプロジェクトディレクトリで `/beat` コマンドを実行:

```bash
claude

# Claude Code 内で
/beat "lofi, jazzy, dusty, 92bpm, minimal melody"
```

## 出力

各 `/beat` 実行で以下が生成されます:

| ファイル | 説明 |
|---------|------|
| `beats/<run_id>/beat.json` | BeatLab JSON形式のビートデータ |
| `beats/<run_id>/beat.mid` | DAWインポート用MIDIファイル |
| `beats/<run_id>/beat.wav` | オーディオレンダリング |
| `beats/<run_id>/beat.mp3` | MP3 (ffmpegがある場合) |
| `.beatlab/current.json` | 最新ビートのコピー |

## アーキテクチャ

```
/beat "<prompt>"
    │
    ▼
music-reference-agent (haiku)
    │ スタイルプロンプト → BeatSpec (YAML)
    ▼
music-generation-agent (sonnet)
    │ BeatSpec → Beat JSON
    ▼
validate.py
    │ 検証・正規化 (NGなら最大3回リトライ)
    ▼
render_grid.py → ASCIIグリッド表示
export_midi.py → .mid
render_wav.py  → .wav
ffmpeg         → .mp3 (オプション)
```

## Beat JSON フォーマット

[Mastra AI Beats Lab](https://mastra.ai/blog/ai-beats-lab) 互換:

```json
{
  "bpm": 92,
  "swing": 0.12,
  "pianoSequence": {
    "C5": [], "B4": [6], "A4": [2, 10], "G4": [14],
    "F4": [], "E4": [], "D4": [], "C4": [],
    "B3": [], "A3": [], "G3": []
  },
  "drumSequence": {
    "Kick": [0, 8], "Snare": [6], "HiHat": [3, 11, 14],
    "Clap": [], "OpenHat": [15], "Tom": [],
    "Crash": [], "Ride": [], "Shaker": [], "Cowbell": []
  }
}
```

### 許可されたノート/ドラム

- **Piano**: C5, B4, A4, G4, F4, E4, D4, C4, B3, A3, G3
- **Drums**: Kick, Snare, HiHat, Clap, OpenHat, Tom, Crash, Ride, Shaker, Cowbell
- **Steps**: 0-15 (16ステップ)

## ディレクトリ構成

```
claude-beatlab/
├── CLAUDE.md                 # Claude Code用プロジェクト説明
├── README.md
├── pyproject.toml
├── .python-version
├── .claude/
│   ├── commands/
│   │   └── beat.md           # /beat コマンド定義
│   ├── agents/
│   │   ├── music-reference-agent.md
│   │   └── music-generation-agent.md
│   └── skills/
│       ├── beatlab-contract/
│       │   └── SKILL.md      # JSON契約定義
│       └── beatlab-pipeline/
│           ├── SKILL.md
│           └── scripts/
│               ├── validate.py
│               ├── render_grid.py
│               ├── export_midi.py
│               └── render_wav.py
├── beats/                    # 生成されたビート
└── .beatlab/
    └── current.json          # 最新ビート
```

## ライセンス

MIT
