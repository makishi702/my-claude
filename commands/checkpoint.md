# Checkpoint コマンド

ワークフローにチェックポイントを作成または検証します。

## 使い方

`/checkpoint [create|verify|list] [名前]`

## チェックポイントの作成

チェックポイントを作成する場合：

1. `/verify quick` を実行して現在の状態がクリーンであることを確認する
2. チェックポイント名付きの git stash またはコミットを作成する
3. チェックポイントを `.claude/checkpoints.log` に記録する：

```bash
echo "$(date +%Y-%m-%d-%H:%M) | $CHECKPOINT_NAME | $(git rev-parse --short HEAD)" >> .claude/checkpoints.log
```

4. チェックポイントが作成されたことを報告する

## チェックポイントの検証

チェックポイントに対して検証する場合：

1. ログからチェックポイントを読み込む
2. 現在の状態をチェックポイントと比較する：
   - チェックポイント以降に追加されたファイル
   - チェックポイント以降に変更されたファイル
   - 現在のテスト合格率との比較
   - 現在のカバレッジとの比較

3. レポートを出力する：
```
チェックポイント比較: $NAME
============================
変更されたファイル: X
テスト: +Y 合格 / -Z 失敗
カバレッジ: +X% / -Y%
ビルド: [PASS/FAIL]
```

## チェックポイントの一覧表示

以下の情報と共に全チェックポイントを表示する：
- 名前
- タイムスタンプ
- Git SHA
- ステータス（current、behind、ahead）

## ワークフロー

典型的なチェックポイントのフロー：

```
[開始] --> /checkpoint create "feature-start"
   |
[実装] --> /checkpoint create "core-done"
   |
[テスト] --> /checkpoint verify "core-done"
   |
[リファクタリング] --> /checkpoint create "refactor-done"
   |
[PR] --> /checkpoint verify "feature-start"
```

## 引数

$ARGUMENTS:
- `create <名前>` - 名前付きチェックポイントを作成する
- `verify <名前>` - 名前付きチェックポイントに対して検証する
- `list` - 全チェックポイントを表示する
- `clear` - 古いチェックポイントを削除する（直近 5 件を保持）
