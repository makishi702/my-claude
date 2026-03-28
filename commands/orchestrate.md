---
description: Sequential and tmux/worktree orchestration guidance for multi-agent workflows.
---

# Orchestrate コマンド

複雑なタスクのための逐次 agent ワークフロー。

## 使い方

`/orchestrate [ワークフロータイプ] [タスクの説明]`

---

## ⚠️ メインエージェントの役割（必読）

**このコマンドを実行するメインエージェントは「指揮者」であり「実装者」ではない。**

- コードを自分で書いてはならない
- ファイルを自分で編集してはならない
- 実装・テスト・レビューはすべて専門エージェントに委譲する
- メインエージェントの仕事は「エージェントを呼び出し、結果を受け取り、次のエージェントに渡すこと」のみ

planner の結果が手元にあっても、そのまま実装してはいけない。必ず tdd-guide エージェントに引き継ぐ。

---

## ステップ 0: ワークフロータイプの決定

`/orchestrate <説明>` のようにタイプが未指定の場合、以下の基準で自動推定し、**ユーザーに確認してから開始する**：

| タスクの特徴 | 推定タイプ |
|-------------|-----------|
| 新機能の追加・実装 | `feature` |
| バグ修正・不具合対応 | `bugfix` |
| コード整理・構造改善 | `refactor` |
| 認証・権限・セキュリティ | `security` |
| 上記に当てはまらない | ユーザーに確認 |

**確認メッセージの例：**
> タスクを「feature（フル機能実装）」ワークフローで実行します：
> `planner → tdd-guide → code-reviewer → security-reviewer`
> このワークフローで進めますか？

---

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

---

## 実行パターン（厳守）

各フェーズは必ずこの順序で行う：

1. **エージェントを呼び出す** - 前のフェーズの HANDOFF 文書をコンテキストとして渡す
2. **結果を受け取る** - エージェントの出力をそのまま収集する
3. **HANDOFF 文書を作成する** ← 省略禁止
4. **planner フェーズの場合は計画をユーザーに提示して承認を得る** ← 省略禁止
5. **次のエージェントへ渡す** - HANDOFF 文書を添えて次を呼び出す（承認後のみ）
6. **全フェーズ完了後** - 最終レポートを出力する

### フェーズ完了ゲート

次のエージェントを起動する前に、以下を確認する：

```
[ ] エージェントが完了した
[ ] HANDOFF 文書を作成した（下記フォーマット参照）
[ ] 未解決の問題をすべて HANDOFF 文書に記載した
```

---

## HANDOFF 文書フォーマット（必須）

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

---

## 例: Feature ワークフロー

```
/orchestrate feature "ユーザー認証を追加"
```

### Phase 1: Planner Agent

呼び出し後、以下が完了したことを確認する：
- [ ] 実装計画が作成された
- [ ] 依存関係が特定された
- [ ] `HANDOFF: planner -> tdd-guide` を作成した

**→ ここでユーザーに計画内容を提示し、承認を得る（必須）**

計画の要点（変更ファイル・アーキテクチャ上の判断・リスク）をユーザーに見せ、
「この計画で実装を進めてよいですか？」と確認する。
ユーザーの承認なしに tdd-guide を起動してはならない。

→ 承認後、HANDOFF 文書を添えて tdd-guide を起動する

### Phase 2: TDD Guide Agent

呼び出し後、以下が完了したことを確認する：
- [ ] テストが先に書かれた（RED）
- [ ] テストをパスする実装ができた（GREEN）
- [ ] カバレッジ 80% 以上を確認した
- [ ] `HANDOFF: tdd-guide -> code-reviewer` を作成した

→ HANDOFF 文書を添えて code-reviewer を起動する

### Phase 3: Code Reviewer Agent

呼び出し後、以下が完了したことを確認する：
- [ ] コード品質の問題が確認された
- [ ] 重大な問題がある場合は tdd-guide に差し戻した
- [ ] `HANDOFF: code-reviewer -> security-reviewer` を作成した

→ HANDOFF 文書を添えて security-reviewer を起動する

### Phase 4: Security Reviewer Agent

呼び出し後、以下が完了したことを確認する：
- [ ] セキュリティ脆弱性の確認が完了した
- [ ] 問題があれば修正指示を出した
- [ ] 最終レポートを出力した

---

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

---

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
6. **メインエージェントはコードを書かない** - 迷ったら専門エージェントに渡す
