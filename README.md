# my-claude — チーム共有 Claude Code 設定

Nuxt 4 / Flask / Azure Web App / PostgreSQL スタック向けの Claude Code プラグインです。
チームで git 管理し、各自の `~/.claude/` にインストールして使います。

---

## クイックスタート

```bash
# 1. リポジトリをクローン（または git submodule として追加）
git clone <このリポジトリの URL> ~/.claude-team

# 2. インストール
cd ~/.claude-team
bash install.sh

# 3. プロジェクトルートに CLAUDE.md をコピー
cp CLAUDE.md /path/to/your/project/

# 4. Claude Code を再起動

# 5. 動作確認
# Claude Code で /plan と入力してみる
```

---

## MCPセットアップ（推奨3個）

プロジェクトルートの `.mcp.json` に以下を設定してください。

### このプロジェクト（Azure DevOps 使用）

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp", "--browser", "chrome"]
    },
    "azure-devops": {
      "command": "npx",
      "args": ["-y", "@azure-devops/mcp", "your-org-name", "--authentication", "envvar"],
      "env": {
        "ADO_MCP_AUTH_TOKEN": "your-pat-here"
      }
    }
  }
}
```

### GitHub を使うプロジェクトの場合

`azure-devops` の代わりに以下を使用してください：

```json
"github": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_あなたのトークンをここに"
  }
}
```

### どちらを使うか

| 状況 | 使用するMCP |
|------|------------|
| Azure DevOps でソース管理・Work Items・Pipelines を使っている | `azure-devops` |
| GitHub でソース管理・Issues・Actions を使っている | `github` |

### Azure DevOps PAT の取得方法

1. Azure DevOps → ユーザーアイコン → Personal access tokens
2. New Token
3. スコープ: `Full access` または `Code (Read & Write)`、`Work Items (Read & Write)`
4. 生成されたトークンを `ADO_MCP_AUTH_TOKEN` に設定

**注意**: `env` セクションの `${VAR}` 形式はシェル展開されません。PAT は直接値を記述してください。`.mcp.json` は `.gitignore` に追加してシークレットを保護すること。

### GitHub PAT の取得方法

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. スコープ: `repo`、`read:org` にチェック
4. 生成されたトークンを `GITHUB_PERSONAL_ACCESS_TOKEN` に設定

### MCP 設定ファイルの場所

| 推奨 | 理由 |
|------|------|
| プロジェクトルート `.mcp.json` | プロジェクト固有の設定を git 管理できる（PAT 含む場合は `.gitignore` に追加） |
| `~/.claude.json` の `mcpServers` | 全プロジェクト共通で使いたい場合 |

**注意**: 有効な MCP は 10 個以下を推奨（コンテキストウィンドウの節約）

---

## 日常の使い方

### 機能開発の流れ

```
新機能を開始
  ↓
/plan          # 実装計画を立てる（大きな機能はここから）
  ↓（計画を確認・承認）
/tdd           # TDD で実装
  ↓
/code-review   # コードレビュー
  ↓
/e2e           # E2E テスト
  ↓
PR を作成
```

### 大規模機能の場合

```
/orchestrate feature
# → planner → tdd-guide → code-reviewer → security-reviewer が自動でチェーン実行
```

### コマンド一覧

| コマンド | 用途 | いつ使う |
|---------|------|---------|
| `/plan` | 実装計画 | 大きな機能・設計変更の前 |
| `/tdd` | TDD 実装 | 新機能・バグ修正 |
| `/code-review` | コードレビュー | PR 前・変更後 |
| `/build-fix` | ビルドエラー修正 | エラーが出たとき |
| `/e2e` | E2E テスト | 重要なユーザーフロー |
| `/orchestrate` | エージェントチェーン | 複雑な機能開発 |
| `/checkpoint` | 途中状態を保存 | 長い作業の途中 |
| `/save-session` | セッション保存 | 作業を中断するとき |
| `/resume-session` | セッション復元 | 前回の続きから |
| `/learn` | パターン抽出 | セッション終了時 |

---

## フォルダ構造の説明

```
my-claude/
├── CLAUDE.md          チーム共通ルール（プロジェクトルートにもコピー）
├── agents/            専門エージェント（Claude が自動的に使う）
├── commands/          スラッシュコマンド（/plan, /tdd 等）
├── contexts/          作業モード（dev/research/review）
├── skills/            ドメイン知識（エージェントが自動的に参照）
├── rules/             コーディングルール（常時適用）
├── hooks/             自動化フック（設定）
├── scripts/           フックの実装スクリプト
└── install.sh         インストーラー
```

### 各要素の役割

**agents/**: Claude Code が状況に応じて自動的に呼び出す専門家。人間が直接呼ぶ必要はない。
- `planner` → 複雑な機能の計画を立てる
- `code-reviewer` → コード品質・セキュリティを確認する
- `python-reviewer` → Flask/Python 固有のレビューをする
- `tdd-guide` → TDD ワークフローをガイドする
- `security-reviewer` → OWASP Top 10 を確認する

**skills/**: コマンドやエージェントが参照する知識定義。人間が直接使うものではない。
- `tdd-workflow` → TDD のやり方
- `nuxt4-patterns` → Nuxt 4 固有のパターン
- `python-patterns` → Flask/Python のパターン
- `postgres-patterns` → PostgreSQL の最適化
- 等...

**hooks/**: ツール実行のタイミングで自動実行される処理。
- `SessionStart` → 前回のセッションコンテキストを自動ロード
- `PostToolUse (Edit)` → ファイル編集後に自動フォーマット・console.log 警告
- `Stop` → セッション状態を自動保存
- `PreToolUse (Bash)` → `git --no-verify` のブロック

---

## カスタマイズ方法

### プロジェクト固有のルールを追加

`CLAUDE.md` をプロジェクトルートにコピーし、チームのルールを追記してください：

```markdown
# プロジェクト固有ルール（CLAUDE.md の末尾に追加）

## このプロジェクト固有の規約
- API エンドポイントは `/api/v1/` プレフィックスを付ける
- テストは `tests/` フォルダ以下に配置する
- ...
```

### スキルを追加する

```bash
mkdir -p ~/.claude/skills/my-custom-skill
# SKILL.md を作成し、ドメイン知識を記述する
```

### エージェントを追加する

```bash
# ~/.claude/agents/ に新しい .md ファイルを作成する
```

---

## セッション管理

セッションは `~/.claude/sessions/` に自動保存されます。

```bash
# 作業を中断するとき
/save-session

# 次のセッションで続きから
/resume-session
```

セッションファイルには以下が記録されます：
- 何を作っていたか
- 何が動いて何が失敗したか（**最重要**）
- 次にやること

---

## トラブルシューティング

### フックが動かない

1. `~/.claude/settings.json` に hooks が設定されているか確認
2. `node` がインストールされているか確認: `node --version`
3. `CLAUDE_PLUGIN_ROOT` が正しいか確認: `echo $CLAUDE_PLUGIN_ROOT`

### MCP が接続できない

1. `npx` が利用可能か確認: `npx --version`
2. PAT の権限を確認（Azure DevOps: `Code`, `Work Items` / GitHub: `repo`, `read:org`）
3. `.mcp.json` の PAT が直接値で書かれているか確認（`${VAR}` 形式は展開されない）
4. Claude Code を再起動する

### コマンドが認識されない

1. `~/.claude/commands/` にファイルがあるか確認
2. Claude Code を再起動する

---

## チームへの共有方法

```bash
# このフォルダを git リポジトリとして管理
cd /path/to/my-claude
git init
git add .
git commit -m "feat: 初期チーム Claude 設定"
git remote add origin <リポジトリ URL>
git push -u origin main

# チームメンバーはクローンしてインストール
git clone <URL> ~/my-claude
bash ~/my-claude/install.sh
```

---

## ライセンス

このフォルダの内容は [Everything Claude Code](https://github.com/anthropics/everything-claude-code) をベースに、チーム向けにカスタマイズしたものです。
