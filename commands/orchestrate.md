---
description: Sequential and tmux/worktree orchestration guidance for multi-agent workflows.
---

# Orchestrate コマンド

複雑なタスクのための逐次 agent ワークフロー。

## 使い方

`/orchestrate [ワークフロータイプ] [タスクの説明]`

## ワークフロータイプ

### feature
フル機能実装ワークフロー：
```
planner -> tdd-guide -> code-reviewer -> security-reviewer
```

### bugfix
バグ調査・修正ワークフロー：
```
planner -> tdd-guide -> code-reviewer
```

### refactor
安全なリファクタリングワークフロー：
```
architect -> code-reviewer -> tdd-guide
```

### security
セキュリティ重視のレビュー：
```
security-reviewer -> code-reviewer -> architect
```

## 実行パターン

ワークフロー内の各 agent について：

1. **agent を呼び出す** - 前の agent からのコンテキストを渡す
2. **出力を収集** - 構造化された引き継ぎドキュメントとしてまとめる
3. **次の agent へ渡す** - チェーン内の次の agent へ渡す
4. **結果を集約** - 最終レポートにまとめる

## 引き継ぎドキュメントの形式

agent 間の引き継ぎドキュメント：

```markdown
## HANDOFF: [前の agent] -> [次の agent]

### コンテキスト
[何を行ったかのサマリー]

### 発見事項
[主要な発見や決定事項]

### 変更されたファイル
[触れたファイルの一覧]

### 未解決の問題
[次の agent に向けた未解決の項目]

### 推奨事項
[次のステップの提案]
```

## 例: Feature ワークフロー

```
/orchestrate feature "ユーザー認証を追加"
```

実行内容：

1. **Planner Agent**
   - 要件を分析する
   - 実装計画を作成する
   - 依存関係を特定する
   - 出力: `HANDOFF: planner -> tdd-guide`

2. **TDD Guide Agent**
   - planner の引き継ぎを読む
   - テストを先に書く
   - テストをパスするよう実装する
   - 出力: `HANDOFF: tdd-guide -> code-reviewer`

3. **Code Reviewer Agent**
   - 実装をレビューする
   - 問題を確認する
   - 改善を提案する
   - 出力: `HANDOFF: code-reviewer -> security-reviewer`

4. **Security Reviewer Agent**
   - セキュリティ監査を行う
   - 脆弱性を確認する
   - 最終承認を行う
   - 出力: 最終レポート

## 最終レポートの形式

```
オーケストレーションレポート
====================
ワークフロー: feature
タスク: ユーザー認証を追加
Agent: planner -> tdd-guide -> code-reviewer -> security-reviewer

サマリー
-------
[1段落のサマリー]

各 Agent の出力
-------------
Planner: [サマリー]
TDD Guide: [サマリー]
Code Reviewer: [サマリー]
Security Reviewer: [サマリー]

変更ファイル
-------------
[変更されたファイルの一覧]

テスト結果
------------
[テストの合否サマリー]

セキュリティステータス
---------------
[セキュリティの所見]

推奨事項
--------------
[SHIP / NEEDS WORK / BLOCKED]
```

## 並行実行

独立したチェックについては、agent を並行して実行する：

```markdown
### 並行フェーズ
同時実行:
- code-reviewer（品質）
- security-reviewer（セキュリティ）
- architect（設計）

### 結果のマージ
出力を1つのレポートに統合する
```

外部の tmux ペインワーカーと別の git worktree を使用する場合は `node scripts/orchestrate-worktrees.js plan.json --execute` を使用します。ビルトインのオーケストレーションパターンはインプロセスで動作します。このヘルパーは長時間実行またはクロスハーネスのセッション向けです。

ワーカーがメインチェックアウトのダーティファイルや未追跡ファイルを参照する必要がある場合は、plan ファイルに `seedPaths` を追加します。ECC は `git worktree add` 後に選択したパスのみを各ワーカーの worktree にオーバーレイし、ブランチを分離しつつ進行中のローカルスクリプト・計画・ドキュメントを公開します。

```json
{
  "sessionName": "workflow-e2e",
  "seedPaths": [
    "scripts/orchestrate-worktrees.js",
    "scripts/lib/tmux-worktree-orchestrator.js",
    ".claude/plan/workflow-e2e-test.json"
  ],
  "workers": [
    { "name": "docs", "task": "オーケストレーションドキュメントを更新する。" }
  ]
}
```

ライブな tmux/worktree セッションのコントロールプレーンスナップショットをエクスポートするには以下を実行します：

```bash
node scripts/orchestration-status.js .claude/plan/workflow-visual-proof.json
```

スナップショットには、セッションのアクティビティ、tmux ペインのメタデータ、ワーカーの状態、目標、シードされたオーバーレイ、最近の引き継ぎサマリーが JSON 形式で含まれます。

## オペレーターへのコントロールプレーン引き継ぎ

ワークフローが複数のセッション・worktree・tmux ペインにまたがる場合、最終引き継ぎにコントロールプレーンのブロックを追加します：

```markdown
コントロールプレーン
-------------
セッション:
- アクティブなセッション ID またはエイリアス
- 各アクティブワーカーのブランチと worktree パス
- 該当する場合の tmux ペインまたはデタッチセッション名

差分:
- git status サマリー
- 変更されたファイルの git diff --stat
- マージ・コンフリクトのリスクメモ

承認待ち:
- 保留中のユーザー承認
- 確認待ちのブロックされたステップ

テレメトリ:
- 最後のアクティビティタイムスタンプまたはアイドルシグナル
- 推定トークン数またはコストのドリフト
- hook やレビュアーによって発生したポリシーイベント
```

これにより、オペレーターサーフェスから planner・実装者・レビュアー・ループワーカーを把握しやすくなります。

## 引数

$ARGUMENTS:
- `feature <説明>` - フル機能ワークフロー
- `bugfix <説明>` - バグ修正ワークフロー
- `refactor <説明>` - リファクタリングワークフロー
- `security <説明>` - セキュリティレビューワークフロー
- `custom <agents> <説明>` - カスタム agent シーケンス

## カスタムワークフローの例

```
/orchestrate custom "architect,tdd-guide,code-reviewer" "キャッシュレイヤーを再設計する"
```

## Tips

1. **複雑な機能には planner から始める**
2. **マージ前には必ず code-reviewer を含める**
3. **認証・決済・PII には security-reviewer を使う**
4. **引き継ぎは簡潔に** - 次の agent が必要なことに焦点を当てる
5. **必要に応じて agent 間で検証を実行する**
