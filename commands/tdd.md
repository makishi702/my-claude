---
description: テスト駆動開発ワークフローを実施する。インターフェースをスキャフォールドし、先にテストを生成し、テストをパスする最小限のコードを実装する。カバレッジ80%以上を確保する。
---

# TDD コマンド

このコマンドは **tdd-guide** agent を呼び出し、テスト駆動開発の手法を実施します。

## このコマンドが行うこと

1. **インターフェースのスキャフォールド** - 型・インターフェースを先に定義する
2. **テストを先に生成** - 失敗するテストを書く（RED）
3. **最小限のコードを実装** - パスするのに十分なコードだけ書く（GREEN）
4. **リファクタリング** - テストを green に保ちながらコードを改善する（REFACTOR）
5. **カバレッジの確認** - テストカバレッジ 80% 以上を確保する

## 使いどころ

`/tdd` を使うタイミング：
- 新機能を実装するとき
- 新しい関数・コンポーネントを追加するとき
- バグを修正するとき（まずバグを再現するテストを書く）
- 既存コードをリファクタリングするとき
- 重要なビジネスロジックを構築するとき

## 動作の仕組み

tdd-guide agent は以下を行います：

1. 入出力の**インターフェースを定義**する
2. **失敗するテストを書く**（まだコードが存在しないため）
3. **テストを実行**し、正しい理由で失敗することを確認する
4. テストをパスさせるための**最小限の実装**を書く
5. **テストを実行**し、パスすることを確認する
6. テストを green に保ちながらコードを**リファクタリング**する
7. **カバレッジを確認**し、80% 未満なら追加のテストを書く

## TDD サイクル

```
RED → GREEN → REFACTOR → REPEAT

RED:      失敗するテストを書く
GREEN:    パスする最小限のコードを書く
REFACTOR: コードを改善し、テストをパスし続ける
REPEAT:   次の機能・シナリオへ
```

## 使用例

```
ユーザー: /tdd マーケット流動性スコアを計算する関数が必要

Agent (tdd-guide):
# TDD セッション: マーケット流動性スコア計算

## ステップ 1: インターフェースの定義（SCAFFOLD）

```typescript
// lib/liquidity.ts
export interface MarketData {
  totalVolume: number
  bidAskSpread: number
  activeTraders: number
  lastTradeTime: Date
}

export function calculateLiquidityScore(market: MarketData): number {
  // TODO: 実装
  throw new Error('Not implemented')
}
```

## ステップ 2: 失敗するテストを書く（RED）

```typescript
// lib/liquidity.test.ts
import { calculateLiquidityScore } from './liquidity'

describe('calculateLiquidityScore', () => {
  it('流動性の高い市場では高スコアを返すこと', () => {
    const market = {
      totalVolume: 100000,
      bidAskSpread: 0.01,
      activeTraders: 500,
      lastTradeTime: new Date()
    }

    const score = calculateLiquidityScore(market)

    expect(score).toBeGreaterThan(80)
    expect(score).toBeLessThanOrEqual(100)
  })

  it('流動性の低い市場では低スコアを返すこと', () => {
    const market = {
      totalVolume: 100,
      bidAskSpread: 0.5,
      activeTraders: 2,
      lastTradeTime: new Date(Date.now() - 86400000) // 1日前
    }

    const score = calculateLiquidityScore(market)

    expect(score).toBeLessThan(30)
    expect(score).toBeGreaterThanOrEqual(0)
  })

  it('エッジケース: ボリューム 0 を処理できること', () => {
    const market = {
      totalVolume: 0,
      bidAskSpread: 0,
      activeTraders: 0,
      lastTradeTime: new Date()
    }

    const score = calculateLiquidityScore(market)

    expect(score).toBe(0)
  })
})
```

## ステップ 3: テスト実行 - 失敗を確認

```bash
npm test lib/liquidity.test.ts

FAIL lib/liquidity.test.ts
  ✕ 流動性の高い市場では高スコアを返すこと (2 ms)
    Error: Not implemented

1 test failed, 0 passed
```

✅ 期待通りにテストが失敗。実装の準備完了。

## ステップ 4: 最小限のコードを実装（GREEN）

```typescript
// lib/liquidity.ts
export function calculateLiquidityScore(market: MarketData): number {
  // ゼロボリュームのエッジケースを処理
  if (market.totalVolume === 0) {
    return 0
  }

  // コンポーネントスコアを計算（0〜100 スケール）
  const volumeScore = Math.min(market.totalVolume / 1000, 100)
  const spreadScore = Math.max(100 - (market.bidAskSpread * 1000), 0)
  const traderScore = Math.min(market.activeTraders / 10, 100)

  // 直近アクティビティのボーナス
  const hoursSinceLastTrade = (Date.now() - market.lastTradeTime.getTime()) / (1000 * 60 * 60)
  const recencyScore = Math.max(100 - (hoursSinceLastTrade * 10), 0)

  // 加重平均
  const score = (
    volumeScore * 0.4 +
    spreadScore * 0.3 +
    traderScore * 0.2 +
    recencyScore * 0.1
  )

  return Math.min(Math.max(score, 0), 100) // 0〜100 にクランプ
}
```

## ステップ 5: テスト実行 - パスを確認

```bash
npm test lib/liquidity.test.ts

PASS lib/liquidity.test.ts
  ✓ 流動性の高い市場では高スコアを返すこと (3 ms)
  ✓ 流動性の低い市場では低スコアを返すこと (2 ms)
  ✓ エッジケース: ボリューム 0 を処理できること (1 ms)

3 tests passed
```

✅ 全テスト通過！

## ステップ 6: リファクタリング（IMPROVE）

```typescript
// lib/liquidity.ts - 定数と可読性を改善したリファクタリング版
const WEIGHTS = {
  VOLUME: 0.4,
  SPREAD: 0.3,
  TRADERS: 0.2,
  RECENCY: 0.1,
} as const

const SCALE_FACTORS = {
  VOLUME: 1000,
  SPREAD: 1000,
  TRADERS: 10,
  RECENCY_PENALTY: 10,
} as const

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max)
}

export function calculateLiquidityScore(market: MarketData): number {
  if (market.totalVolume === 0) return 0

  const volumeScore = Math.min(market.totalVolume / SCALE_FACTORS.VOLUME, 100)
  const spreadScore = clamp(100 - (market.bidAskSpread * SCALE_FACTORS.SPREAD), 0, 100)
  const traderScore = Math.min(market.activeTraders / SCALE_FACTORS.TRADERS, 100)

  const hoursSinceLastTrade = (Date.now() - market.lastTradeTime.getTime()) / (1000 * 60 * 60)
  const recencyScore = clamp(100 - (hoursSinceLastTrade * SCALE_FACTORS.RECENCY_PENALTY), 0, 100)

  const weightedScore =
    volumeScore * WEIGHTS.VOLUME +
    spreadScore * WEIGHTS.SPREAD +
    traderScore * WEIGHTS.TRADERS +
    recencyScore * WEIGHTS.RECENCY

  return clamp(weightedScore, 0, 100)
}
```

## ステップ 7: テストが引き続きパスすることを確認

```bash
npm test lib/liquidity.test.ts

PASS lib/liquidity.test.ts
  ✓ 流動性の高い市場では高スコアを返すこと (3 ms)
  ✓ 流動性の低い市場では低スコアを返すこと (2 ms)
  ✓ エッジケース: ボリューム 0 を処理できること (1 ms)

3 tests passed
```

✅ リファクタリング完了、テストも引き続きパス！

## ステップ 8: カバレッジの確認

```bash
npm test -- --coverage lib/liquidity.test.ts

File           | % Stmts | % Branch | % Funcs | % Lines
---------------|---------|----------|---------|--------
liquidity.ts   |   100   |   100    |   100   |   100

カバレッジ: 100% ✅ (目標: 80%)
```

✅ TDD セッション完了！
```

## TDD ベストプラクティス

**すべきこと：**
- ✅ 実装より先にテストを書く
- ✅ 実装前にテストが失敗することを実行して確認する
- ✅ テストをパスさせる最小限のコードを書く
- ✅ テストが green になってからリファクタリングする
- ✅ エッジケースとエラーシナリオを追加する
- ✅ カバレッジ 80% 以上を目指す（重要なコードは 100%）

**してはいけないこと：**
- ❌ テストより先に実装を書く
- ❌ 変更のたびにテストを実行するのを省略する
- ❌ 一度に多くのコードを書きすぎる
- ❌ 失敗しているテストを放置する
- ❌ 実装の詳細をテストする（振る舞いをテストすること）
- ❌ 全てをモックにする（インテグレーションテストを優先する）

## 含めるべきテストの種類

**ユニットテスト**（関数レベル）：
- 正常系シナリオ
- エッジケース（空・null・最大値）
- エラー条件
- 境界値

**インテグレーションテスト**（コンポーネントレベル）：
- API エンドポイント
- データベース操作
- 外部サービス呼び出し
- hook を持つ React コンポーネント

**E2E テスト**（`/e2e` コマンドを使用）：
- 重要なユーザーフロー
- 複数ステップのプロセス
- フルスタックの統合

## カバレッジ要件

- 全コードで**最低 80%**
- 以下は**100% 必須**：
  - 金融計算
  - 認証ロジック
  - セキュリティ上重要なコード
  - コアビジネスロジック

## 重要事項

**必須**: テストは実装より先に書くこと。TDD サイクルは：

1. **RED** - 失敗するテストを書く
2. **GREEN** - パスするよう実装する
3. **REFACTOR** - コードを改善する

RED フェーズを省略しないこと。テストより先にコードを書かないこと。

## 他のコマンドとの連携

- 何を構築するかを理解するために先に `/plan` を使う
- テスト付きで実装するために `/tdd` を使う
- ビルドエラーが発生した場合は `/build-fix` を使う
- 実装のレビューには `/code-review` を使う
- カバレッジ確認には `/test-coverage` を使う

## 関連 Agent

このコマンドは ECC が提供する `tdd-guide` agent を呼び出します。

関連する `tdd-workflow` skill も ECC にバンドルされています。

手動インストールの場合、ソースファイルは以下にあります：
- `agents/tdd-guide.md`
- `skills/tdd-workflow/SKILL.md`
