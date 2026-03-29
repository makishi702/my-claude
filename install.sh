#!/bin/bash
set -e

# 使用方法:
#   ./install.sh [project-dest] [user-dest]
#
# project-dest: エージェント・コマンド・スキル・ルールのインストール先（必須）
#               例: /path/to/project/.claude
# user-dest:    settings.json/hooks のマージ先（省略時: ~/.claude）
#               例: ~/.claude
#
# 典型的な使い方:
#   ./install.sh /home/user/repos/my-project/.claude
#   ./install.sh /home/user/repos/my-project/.claude ~/.claude

PROJECT_DEST="${1}"
USER_DEST="${2:-$HOME/.claude}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$PROJECT_DEST" ]; then
  echo "エラー: project-dest が指定されていません"
  echo ""
  echo "使用方法: $0 [project-dest] [user-dest]"
  echo "例:       $0 /path/to/project/.claude"
  exit 1
fi

echo "======================================"
echo "  my-claude インストーラー"
echo "======================================"
echo "プロジェクトレベル: $PROJECT_DEST"
echo "ユーザーレベル:     $USER_DEST"
echo ""

# ===== プロジェクトレベルのインストール =====
echo "--- プロジェクトレベルの設定をインストール中 ---"

# ディレクトリ作成
mkdir -p "$PROJECT_DEST"/{agents,commands,contexts,rules/common,rules/python,rules/typescript}
for s in tdd-workflow verification-loop coding-standards nuxt4-patterns python-testing python-patterns backend-patterns api-design postgres-patterns e2e-testing database-migrations deployment-patterns security-review search-first codebase-onboarding; do
  mkdir -p "$PROJECT_DEST/skills/$s"
done

# agents / commands / contexts / skills
cp -r "$SCRIPT_DIR"/agents/* "$PROJECT_DEST/agents/"
cp -r "$SCRIPT_DIR"/commands/* "$PROJECT_DEST/commands/"
[ -d "$SCRIPT_DIR/contexts" ] && cp -r "$SCRIPT_DIR"/contexts/* "$PROJECT_DEST/contexts/" 2>/dev/null || true

for s in tdd-workflow verification-loop coding-standards nuxt4-patterns python-testing python-patterns backend-patterns api-design postgres-patterns e2e-testing database-migrations deployment-patterns security-review search-first codebase-onboarding; do
  [ -d "$SCRIPT_DIR/skills/$s" ] && cp -r "$SCRIPT_DIR/skills/$s/." "$PROJECT_DEST/skills/$s/"
done

# rules
cp -r "$SCRIPT_DIR"/rules/common/* "$PROJECT_DEST/rules/common/"
cp -r "$SCRIPT_DIR"/rules/python/* "$PROJECT_DEST/rules/python/"
cp -r "$SCRIPT_DIR"/rules/typescript/* "$PROJECT_DEST/rules/typescript/"

echo "✅ プロジェクトレベルのファイルをコピーしました"

# ===== ユーザーレベルのインストール（hooks/settings のみ） =====
echo ""
echo "--- ユーザーレベルの設定をインストール中 ---"

mkdir -p "$USER_DEST"/{hooks,scripts/hooks,scripts/lib}

# scripts（hooks から参照される）
cp -r "$SCRIPT_DIR"/scripts/hooks/* "$USER_DEST/scripts/hooks/"
cp -r "$SCRIPT_DIR"/scripts/lib/* "$USER_DEST/scripts/lib/"

echo "✅ スクリプトをコピーしました"

# hooks.json を settings.json にマージ
SETTINGS="$USER_DEST/settings.json"
HOOKS_JSON="$SCRIPT_DIR/hooks/hooks.json"

# ${CLAUDE_PLUGIN_ROOT} を実際のインストールパスに置換
USER_DEST_ESCAPED=$(printf '%s\n' "$USER_DEST" | sed 's/[\/&]/\\&/g')
TMP_HOOKS=$(mktemp)
sed "s/\${CLAUDE_PLUGIN_ROOT}/$USER_DEST_ESCAPED/g" "$HOOKS_JSON" > "$TMP_HOOKS"

if [ -f "$SETTINGS" ] && command -v node &>/dev/null; then
  node -e "
    const fs = require('fs');
    const raw = fs.readFileSync('$SETTINGS', 'utf8').trim();
    const settings = raw ? JSON.parse(raw) : {};
    const hooks = JSON.parse(fs.readFileSync('$TMP_HOOKS', 'utf8'));
    settings.hooks = hooks.hooks;
    fs.writeFileSync('$SETTINGS', JSON.stringify(settings, null, 2) + '\n');
    console.log('✅ hooks を settings.json にマージしました');
  "
elif [ ! -f "$SETTINGS" ]; then
  cp "$TMP_HOOKS" "$SETTINGS"
  echo "✅ settings.json を作成しました"
else
  echo "⚠️  node が見つかりません"
  echo "   手動で hooks/hooks.json の内容を $SETTINGS にマージしてください"
fi
rm -f "$TMP_HOOKS"

echo ""
echo "======================================"
echo "  インストール完了！"
echo "======================================"
echo ""
echo "次のステップ:"
echo ""
echo "1. CLAUDE.md をプロジェクトルートにコピー（または既存ファイルと統合）"
echo "   cp \"$SCRIPT_DIR/CLAUDE.md\" /path/to/your/project/"
echo ""
echo "2. MCP を設定（README.md の「MCPセットアップ」を参照）"
echo ""
echo "3. Claude Code を再起動"
echo ""
echo "4. /plan や /tdd コマンドが使えることを確認"
