# チーム共通 Claude ルール

## 技術スタック

- **Frontend**: Nuxt 4, Vue 3 (Composition API), TypeScript
- **Backend**: Python + Flask, REST API
- **Database**: PostgreSQL（マイグレーション: Flask-Migrate / Alembic）
- **Infrastructure**: Azure Web App
- **Testing**: pytest（backend 80%+）、Vitest（frontend）、Playwright（E2E）

---

## 絶対ルール（違反不可）

1. **テストを先に書く** — TDD 必須。実装の前に必ずテストを書く
2. **console.log / print() をコミットしない** — Python は `logging` モジュール、JS/TS は logger を使う
3. **シークレットのハードコード禁止** — `.env` を使い、コードに直書きしない
4. **`Any` / `any` 型の禁止** — TypeScript の `any`、Python の `Any` を使わない
5. **ファイル上限 800 行** — 推奨は 200〜400 行。超えたら分割を検討する
6. **`--no-verify` 使用禁止** — git hook をスキップしない

---

## コーディング規約

### Python / Flask
- フォーマッター: **Black** + **Ruff**
- 型ヒント必須（public 関数・メソッド全て）
- docstring 必須（public 関数）
- バリデーション: **Pydantic** または **marshmallow**
- 例外: 素の `except:` は使わない。`except SpecificError as e:` で捕捉

### TypeScript / Vue / Nuxt
- フォーマッター: **Biome** または **Prettier**（プロジェクトに合わせる）
- Composition API 統一（Options API 禁止）
- バリデーション: **Zod**
- 不変性: スプレッド演算子を使い、直接変更しない

### API 設計（共通）
- RESTful URL（名詞複数形、kebab-case、動詞禁止）
- 統一レスポンス形式: `{ success, data, error }`
- 適切な HTTP ステータスコード

---

## Git ワークフロー

- **Conventional Commits** を使う: `feat/fix/docs/chore/refactor/test`
- PR はレビュー後にマージ（セルフマージ禁止）
- ブランチ: `feature/xxx`、`fix/xxx`、`chore/xxx`

---

## 利用可能なコマンド

| コマンド | 用途 |
|---------|------|
| `/plan` | 大きな機能の実装計画を立てる（ここから始める） |
| `/tdd` | TDD ワークフローで実装する |
| `/code-review` | コードレビュー（セキュリティ・品質） |
| `/build-fix` | ビルドエラー・型エラーを修正する |
| `/e2e` | E2E テストを生成・実行する |
| `/orchestrate` | 複数エージェントをチェーン実行（大規模機能向け） |
| `/checkpoint` | 作業の途中状態を保存・検証する |
| `/save-session` | セッションを保存して次回引き継ぎ |
| `/resume-session` | 前回のセッションを復元する |
| `/learn` | 今日のセッションから学習パターンを抽出 |

---

## エージェント一覧

Claude Code が自動的に適切なエージェントに委譲します。明示的に呼び出す必要はありません。

| エージェント | 役割 |
|------------|------|
| planner | 実装計画の立案 |
| code-reviewer | コード品質・セキュリティレビュー |
| tdd-guide | TDD ワークフローのガイド |
| python-reviewer | Python / Flask 専門レビュー |
| build-error-resolver | ビルド・型エラーの修正 |
| security-reviewer | セキュリティ脆弱性の検出 |
| doc-updater | ドキュメント・コードマップの更新 |
| chief-of-staff | 複数タスクの調整（/orchestrate と組み合わせ） |
