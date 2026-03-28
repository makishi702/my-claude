---
description: Playwright を使用して E2E テストを生成・実行する。テストジャーニーの作成、テスト実行、スクリーンショット・動画・トレースのキャプチャ、成果物のアップロードを行う。
---

# E2E コマンド

このコマンドは **e2e-runner** agent を呼び出し、Playwright を使用した E2E テストの生成・メンテナンス・実行を行います。

## このコマンドが行うこと

1. **テストジャーニーの生成** - ユーザーフローの Playwright テストを作成する
2. **E2E テストの実行** - 複数のブラウザでテストを実行する
3. **成果物のキャプチャ** - 失敗時のスクリーンショット、動画、トレース
4. **結果のアップロード** - HTML レポートと JUnit XML
5. **不安定なテストの特定** - 不安定なテストを隔離する

## 使いどころ

`/e2e` を使うタイミング：
- 重要なユーザージャーニーのテスト（ログイン、取引、決済）
- 複数ステップのフローがエンドツーエンドで動作することの確認
- UI のインタラクションとナビゲーションのテスト
- フロントエンドとバックエンドの統合の検証
- 本番デプロイの準備

## 動作の仕組み

e2e-runner agent は以下を行います：

1. **ユーザーフローを分析**してテストシナリオを特定する
2. Page Object Model パターンを使用した **Playwright テストを生成**する
3. 複数のブラウザ（Chrome、Firefox、Safari）で**テストを実行**する
4. スクリーンショット、動画、トレースで**失敗をキャプチャ**する
5. 結果と成果物をまとめた**レポートを生成**する
6. **不安定なテストを特定**して修正を提案する

## 使用例

```
ユーザー: /e2e マーケット検索と閲覧フローをテストしたい

Agent (e2e-runner):
# E2E テスト生成: マーケット検索・閲覧フロー

## 特定されたテストシナリオ

**ユーザージャーニー:** マーケット検索 → 検索結果の閲覧 → マーケットをクリック → 詳細の確認

**テストカバレッジ:**
1. マーケットページへ移動する
2. セマンティック検索を実行する
3. 検索結果を確認する
4. 最初の結果をクリックする
5. マーケット詳細ページが読み込まれることを確認する
6. チャートがレンダリングされることを確認する

## 生成されたテストコード

```typescript
// tests/e2e/markets/search-and-view.spec.ts
import { test, expect } from '@playwright/test'
import { MarketsPage } from '../../pages/MarketsPage'
import { MarketDetailsPage } from '../../pages/MarketDetailsPage'

test.describe('マーケット検索・閲覧フロー', () => {
  test('ユーザーがマーケットを検索して詳細を確認できること', async ({ page }) => {
    // 1. マーケットページへ移動
    const marketsPage = new MarketsPage(page)
    await marketsPage.goto()

    // ページが読み込まれたことを確認
    await expect(page).toHaveTitle(/Markets/)
    await expect(page.locator('h1')).toContainText('Markets')

    // 2. セマンティック検索を実行
    await marketsPage.searchMarkets('election')

    // API レスポンスを待つ
    await page.waitForResponse(resp =>
      resp.url().includes('/api/markets/search') && resp.status() === 200
    )

    // 3. 検索結果を確認
    const marketCards = marketsPage.marketCards
    await expect(marketCards.first()).toBeVisible()
    const resultCount = await marketCards.count()
    expect(resultCount).toBeGreaterThan(0)

    // 検索結果のスクリーンショットを撮影
    await page.screenshot({ path: 'artifacts/search-results.png' })

    // 4. 最初の結果をクリック
    const firstMarketTitle = await marketCards.first().textContent()
    await marketCards.first().click()

    // 5. マーケット詳細ページが読み込まれることを確認
    await expect(page).toHaveURL(/\/markets\/[a-z0-9-]+/)

    const detailsPage = new MarketDetailsPage(page)
    await expect(detailsPage.marketName).toBeVisible()
    await expect(detailsPage.marketDescription).toBeVisible()

    // 6. チャートがレンダリングされることを確認
    await expect(detailsPage.priceChart).toBeVisible()

    // マーケット名が一致することを確認
    const detailsTitle = await detailsPage.marketName.textContent()
    expect(detailsTitle?.toLowerCase()).toContain(
      firstMarketTitle?.toLowerCase().substring(0, 20) || ''
    )

    // マーケット詳細のスクリーンショットを撮影
    await page.screenshot({ path: 'artifacts/market-details.png' })
  })

  test('結果がない検索では空の状態が表示されること', async ({ page }) => {
    const marketsPage = new MarketsPage(page)
    await marketsPage.goto()

    // 存在しないマーケットを検索
    await marketsPage.searchMarkets('xyznonexistentmarket123456')

    // 空の状態を確認
    await expect(page.locator('[data-testid="no-results"]')).toBeVisible()
    await expect(page.locator('[data-testid="no-results"]')).toContainText(
      /no.*results|no.*markets/i
    )

    const marketCount = await marketsPage.marketCards.count()
    expect(marketCount).toBe(0)
  })

  test('検索をクリアすると全マーケットが再表示されること', async ({ page }) => {
    const marketsPage = new MarketsPage(page)
    await marketsPage.goto()

    // 初期マーケット数
    const initialCount = await marketsPage.marketCards.count()

    // 検索を実行
    await marketsPage.searchMarkets('trump')
    await page.waitForLoadState('networkidle')

    // 絞り込まれた結果を確認
    const filteredCount = await marketsPage.marketCards.count()
    expect(filteredCount).toBeLessThan(initialCount)

    // 検索をクリア
    await marketsPage.searchInput.clear()
    await page.waitForLoadState('networkidle')

    // 全マーケットが再表示されることを確認
    const finalCount = await marketsPage.marketCards.count()
    expect(finalCount).toBe(initialCount)
  })
})
```

## テストの実行

```bash
# 生成されたテストを実行
npx playwright test tests/e2e/markets/search-and-view.spec.ts

Running 3 tests using 3 workers

  ✓  [chromium] › search-and-view.spec.ts:5:3 › ユーザーがマーケットを検索して詳細を確認できること (4.2s)
  ✓  [chromium] › search-and-view.spec.ts:52:3 › 結果がない検索では空の状態が表示されること (1.8s)
  ✓  [chromium] › search-and-view.spec.ts:67:3 › 検索をクリアすると全マーケットが再表示されること (2.9s)

  3 passed (9.1s)

生成された成果物:
- artifacts/search-results.png
- artifacts/market-details.png
- playwright-report/index.html
```

## テストレポート

```
╔══════════════════════════════════════════════════════════════╗
║                    E2E テスト結果                            ║
╠══════════════════════════════════════════════════════════════╣
║ ステータス: ✅ 全テスト合格                                  ║
║ 合計:       3 テスト                                         ║
║ 合格:       3 (100%)                                         ║
║ 失敗:       0                                                ║
║ 不安定:     0                                                ║
║ 所要時間:   9.1s                                             ║
╚══════════════════════════════════════════════════════════════╝

成果物:
スクリーンショット: 2ファイル
動画: 0ファイル（失敗時のみ）
トレース: 0ファイル（失敗時のみ）
HTML レポート: playwright-report/index.html

レポートの確認: npx playwright show-report
```

✅ E2E テストスイートが CI/CD 統合の準備完了！
```

## テスト成果物

テスト実行時に以下の成果物がキャプチャされます：

**全テスト共通：**
- タイムラインと結果を含む HTML レポート
- CI 統合用の JUnit XML

**失敗時のみ：**
- 失敗状態のスクリーンショット
- テストの動画録画
- デバッグ用トレースファイル（ステップバイステップの再生）
- ネットワークログ
- コンソールログ

## 成果物の確認

```bash
# ブラウザで HTML レポートを確認
npx playwright show-report

# 特定のトレースファイルを確認
npx playwright show-trace artifacts/trace-abc123.zip

# スクリーンショットは artifacts/ ディレクトリに保存される
open artifacts/search-results.png
```

## 不安定なテストの検出

テストが断続的に失敗する場合：

```
⚠️  不安定なテストを検出: tests/e2e/markets/trade.spec.ts

テストは 10 回中 7 回合格（70% 合格率）

一般的な失敗:
"Timeout waiting for element '[data-testid="confirm-btn"]'"

推奨される修正:
1. 明示的な待機を追加: await page.waitForSelector('[data-testid="confirm-btn"]')
2. タイムアウトを増やす: { timeout: 10000 }
3. コンポーネント内の競合状態を確認する
4. アニメーションによる要素の非表示を確認する

隔離の推奨: 修正されるまで test.fixme() でマークする
```

## ブラウザ設定

デフォルトでは複数のブラウザでテストを実行します：
- ✅ Chromium（デスクトップ Chrome）
- ✅ Firefox（デスクトップ）
- ✅ WebKit（デスクトップ Safari）
- ✅ モバイル Chrome（オプション）

ブラウザの調整は `playwright.config.ts` で設定します。

## CI/CD 統合

CI パイプラインに追加：

```yaml
# .github/workflows/e2e.yml
- name: Playwright のインストール
  run: npx playwright install --with-deps

- name: E2E テストの実行
  run: npx playwright test

- name: 成果物のアップロード
  if: always()
  uses: actions/upload-artifact@v3
  with:
    name: playwright-report
    path: playwright-report/
```

## 優先すべき重要フロー

**重要（常に合格していなければならない）：**
1. ユーザーがウォレットに接続できる
2. ユーザーがマーケットを閲覧できる
3. ユーザーがマーケットを検索できる（セマンティック検索）
4. ユーザーがマーケット詳細を確認できる
5. ユーザーが取引を実行できる（テスト資金を使用）
6. マーケットが正しく解決される
7. ユーザーが資金を引き出せる

**重要：**
1. マーケット作成フロー
2. ユーザープロフィールの更新
3. リアルタイム価格更新
4. チャートのレンダリング
5. マーケットのフィルタリングとソート
6. モバイルレスポンシブレイアウト

## ベストプラクティス

**すべきこと：**
- ✅ メンテナビリティのために Page Object Model を使用する
- ✅ セレクターには data-testid 属性を使用する
- ✅ 任意のタイムアウトでなく API レスポンスを待つ
- ✅ 重要なユーザージャーニーをエンドツーエンドでテストする
- ✅ main へのマージ前にテストを実行する
- ✅ テスト失敗時は成果物を確認する

**してはいけないこと：**
- ❌ 壊れやすいセレクターを使用する（CSS クラスは変わりうる）
- ❌ 実装の詳細をテストする
- ❌ 本番環境に対してテストを実行する
- ❌ 不安定なテストを放置する
- ❌ 失敗時に成果物の確認を省略する
- ❌ 全てのエッジケースを E2E でテストする（ユニットテストを使うこと）

## 重要事項

- 実際のお金を扱う E2E テストはテストネット・ステージング環境でのみ実行すること
- 本番環境に対して取引テストを実行しないこと
- 金融テストには `test.skip(process.env.NODE_ENV === 'production')` を設定すること
- テスト用ウォレットは少額のテスト資金のみ使用すること

## 他のコマンドとの連携

- テストすべき重要なジャーニーを特定するために `/plan` を使う
- ユニットテスト（より高速で細かい粒度）には `/tdd` を使う
- インテグレーション・ユーザージャーニーのテストには `/e2e` を使う
- テスト品質を確認するために `/code-review` を使う

## 関連 Agent

このコマンドは ECC が提供する `e2e-runner` agent を呼び出します。

手動インストールの場合、ソースファイルは以下にあります：
`agents/e2e-runner.md`

## クイックコマンド

```bash
# 全 E2E テストを実行
npx playwright test

# 特定のテストファイルを実行
npx playwright test tests/e2e/markets/search.spec.ts

# ヘッドありモードで実行（ブラウザを表示）
npx playwright test --headed

# テストをデバッグ
npx playwright test --debug

# テストコードを生成
npx playwright codegen http://localhost:3000

# レポートを確認
npx playwright show-report
```
