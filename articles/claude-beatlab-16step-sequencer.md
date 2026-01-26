---
title: "Claude Codeを16ステップビートシーケンサーに変えてみた"
emoji: "🎹"
type: "tech"
topics: ["claudecode", "python", "midi", "ai", "音楽"]
published: false
---

## はじめに

Claude Code の拡張機能（commands / agents / skills）を活用して、テキストプロンプトからビートを生成する 16ステップシーケンサーを作った。

```bash
/beat "lofi, jazzy, dusty, 92bpm"
```

これだけで JSON / MIDI / WAV / MP3 が生成される。

## 作ったもの

### デモ

```
            | 0| 1| 2| 3| 4| 5| 6| 7| 8| 9|10|11|12|13|14|15|
------------+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
Kick        | X|  |  |  |  |  |  |  | X|  |  |  |  |  |  |  |
Snare       |  |  |  |  | X|  |  |  |  |  |  |  | X|  |  |  |
HiHat       | X|  | X|  | X|  | X|  | X|  | X|  | X|  | X|  |
------------+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
C5          | O|  |  |  |  |  |  |  | O|  |  |  |  |  |  |  |
G4          |  |  |  |  | O|  |  |  |  |  |  |  | O|  |  |  |
------------+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
Beat        |1 |  |  |  |2 |  |  |  |3 |  |  |  |4 |  |  |  |
```

### 主な機能

- **テキストからビート生成**: 「lofi, jazzy」のようなスタイルプロンプトでビート生成
- **マルチフォーマット出力**: JSON / MIDI / WAV / MP3
- **ASCIIグリッド表示**: ターミナルで視覚的に確認
- **DAW連携**: MIDI 出力で任意の DAW にインポート可能

## アーキテクチャ

Claude Code の拡張システムをフル活用した構成:

```
/beat "<prompt>"
    │
    ▼
┌─────────────────────────────────┐
│  music-reference-agent (haiku)  │  ← スタイル解釈
│  プロンプト → BeatSpec YAML     │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  music-generation-agent (sonnet)│  ← ビート生成
│  BeatSpec → Beat JSON           │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  beatlab-pipeline (skill)       │  ← 検証・出力
│  validate → render → export     │
└─────────────────────────────────┘
```

### 2層の拡張機能

| 種類 | 役割 | ファイル |
|------|------|----------|
| **Skill** | ユーザー向けコマンド・再利用可能な知識 | `.claude/skills/beat/SKILL.md` |
| **Agent** | AI によるタスク実行 | `.claude/agents/*.md` |

## 使い方

### セットアップ

```bash
git clone https://github.com/ryok/claude-beatlab
cd claude-beatlab
uv sync  # Python 環境セットアップ
```

### ビート生成

```bash
claude  # Claude Code を起動

# スタイルプロンプトでビート生成
/beat "lofi, jazzy, dusty, 92bpm, minimal melody"
```

### 出力ファイル

```
beats/20260116_153520/
├── beat.json   # ビートデータ
├── beat.mid    # MIDI (DAW用)
├── beat.wav    # オーディオ
└── beat.mp3    # 圧縮オーディオ
```

## 実装のポイント

### 1. 2段階エージェント構成

なぜ 2つのエージェントに分けたのか:

```yaml
# music-reference-agent (haiku) - 軽量・高速
# スタイル解釈に特化
bpm: 92
swing: 0.12
drum_plan: "Kick on 0, 8; Snare on 4, 12"
melody_plan: "Minimal 2-note motif"
```

```json
// music-generation-agent (sonnet) - 高精度
// 実際のビートデータ生成
{
  "bpm": 92,
  "drumSequence": { "Kick": [0, 8], "Snare": [4, 12] }
}
```

**メリット**:
- haiku で高速にスタイル解釈 → 低コスト
- sonnet で正確な JSON 生成 → 高品質
- 責務分離でデバッグしやすい

### 2. スキルによる契約定義

`beatlab-contract` スキルで JSON フォーマットを厳密に定義:

```markdown
Allowed piano notes (fixed):
C5, B4, A4, G4, F4, E4, D4, C4, B3, A3, G3

Allowed drum sounds (fixed):
Kick, Snare, HiHat, Clap, OpenHat, Tom, Crash, Ride, Shaker, Cowbell

Steps: 0-15 only
```

これにより:
- エージェントが契約を参照して正確な JSON 生成
- バリデーションスクリプトで検証
- 最大 3回のリトライで品質担保

### 3. 決定論的パイプライン

AI の出力を Python スクリプトで確実に処理:

```python
# validate.py - JSON 検証・正規化
# render_grid.py - ASCII グリッド生成
# export_midi.py - MIDI 出力
# render_wav.py - オーディオ合成
```

スクリプトは `uv run python` で実行し、環境依存を排除。

## Beat JSON フォーマット

[Mastra AI Beats Lab](https://mastra.ai/blog/ai-beats-lab) 互換の形式を採用:

```json
{
  "bpm": 92,
  "swing": 0.12,
  "pianoSequence": {
    "C5": [0, 8],
    "G4": [4, 12]
  },
  "drumSequence": {
    "Kick": [0, 8],
    "Snare": [4, 12],
    "HiHat": [0, 2, 4, 6, 8, 10, 12, 14]
  }
}
```

## 今後の展望

- [ ] Web UI でのビジュアル編集
- [ ] ループ再生・リアルタイムプレビュー
- [ ] 複数パターンのチェーン再生
- [ ] カスタム音源対応

## まとめ

Claude Code の拡張システム（commands / agents / skills）を組み合わせることで、テキストベースのビートシーケンサーを実現できた。

特に学んだこと:
- **Commands**: ユーザー向けのインターフェース定義
- **Agents**: 異なるモデルを使い分けた AI タスク実行
- **Skills**: 再利用可能な知識とスクリプトのバンドル

Claude Code は単なる AI コーディングアシスタントではなく、拡張可能なプラットフォームとして活用できる。

## リンク

- [GitHub: claude-beatlab](https://github.com/ryok/claude-beatlab)
- [Claude Code ドキュメント](https://docs.anthropic.com/en/docs/claude-code)
- [Mastra AI Beats Lab](https://mastra.ai/blog/ai-beats-lab)
