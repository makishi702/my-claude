# コードマップの更新

コードベースの構造を解析し、トークン効率の高いアーキテクチャドキュメントを生成する。

## ステップ 1: プロジェクト構造のスキャン

1. プロジェクトの種類を特定する（monorepo、単一アプリ、ライブラリ、マイクロサービス）
2. すべてのソースディレクトリを検出する（src/、lib/、app/、packages/）
3. エントリーポイントをマッピングする（main.ts、index.ts、app.py、main.go など）

## ステップ 2: コードマップの生成

`docs/CODEMAPS/`（または `.reports/codemaps/`）にコードマップを作成・更新する：

| ファイル | 内容 |
|------|----------|
| `architecture.md` | 高レベルのシステム図、サービス境界、データフロー |
| `backend.md` | APIルート、middlewareチェーン、service → repository のマッピング |
| `frontend.md` | ページツリー、コンポーネント階層、状態管理フロー |
| `data.md` | データベーステーブル、リレーション、マイグレーション履歴 |
| `dependencies.md` | 外部サービス、サードパーティ連携、共有ライブラリ |

### コードマップのフォーマット

各コードマップはトークン効率を重視し、AIのコンテキスト読み込みに最適化すること：

```markdown
# バックエンドアーキテクチャ

## Routes
POST /api/users → UserController.create → UserService.create → UserRepo.insert
GET  /api/users/:id → UserController.get → UserService.findById → UserRepo.findById

## Key Files
src/services/user.ts (ビジネスロジック, 120 lines)
src/repos/user.ts (データベースアクセス, 80 lines)

## Dependencies
- PostgreSQL (プライマリデータストア)
- Redis (セッションキャッシュ、レート制限)
- Stripe (決済処理)
```

## ステップ 3: 差分検出

1. 既存のコードマップがある場合、変更割合を計算する
2. 変更が 30% を超える場合は差分を表示し、上書き前にユーザーの承認を求める
3. 変更が 30% 以下の場合はその場で更新する

## ステップ 4: メタデータの追加

各コードマップに鮮度ヘッダーを追加する：

```markdown
<!-- Generated: 2026-02-11 | Files scanned: 142 | Token estimate: ~800 -->
```

## ステップ 5: 解析レポートの保存

`.reports/codemap-diff.txt` にサマリーを書き出す：
- 前回スキャン以降に追加・削除・変更されたファイル
- 新たに検出された依存関係
- アーキテクチャの変更（新しいルート、新しいサービスなど）
- 90日以上更新されていないドキュメントの陳腐化警告

## ヒント

- **高レベルの構造**に焦点を当て、実装の詳細は含めない
- 完全なコードブロックより**ファイルパスと関数シグネチャ**を優先する
- 効率的なコンテキスト読み込みのため、各コードマップは**1000トークン以内**に収める
- 詳細な説明の代わりに、データフローにはASCII図を使用する
- 大きな機能追加やリファクタリング後に実行する
