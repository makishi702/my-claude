#!/bin/bash
set -e

DEST="${1:-$HOME/.claude}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "======================================"
echo "  my-claude インストーラー"
echo "======================================"
echo "インストール先: $DEST"
echo ""

# ディレクトリ作成
mkdir -p "$DEST"/{agents,commands,contexts,hooks,rules/common,rules/python,rules/typescript,scripts/hooks,scripts/lib}
for s in tdd-workflow verification-loop coding-standards nuxt4-patterns python-testing python-patterns backend-patterns api-design postgres-patterns e2e-testing database-migrations deployment-patterns security-review search-first codebase-onboarding; do
  mkdir -p "$DEST/skills/$s"
done

# agents / commands / contexts / skills
cp -r "$SCRIPT_DIR"/agents/* "$DEST/agents/"
cp -r "$SCRIPT_DIR"/commands/* "$DEST/commands/"
cp -r "$SCRIPT_DIR"/contexts/* "$DEST/contexts/"
cp -r "$SCRIPT_DIR"/skills/* "$DEST/skills/"

# rules
cp -r "$SCRIPT_DIR"/rules/common/* "$DEST/rules/common/"
cp -r "$SCRIPT_DIR"/rules/python/* "$DEST/rules/python/"
cp -r "$SCRIPT_DIR"/rules/typescript/* "$DEST/rules/typescript/"

# scripts
cp -r "$SCRIPT_DIR"/scripts/hooks/* "$DEST/scripts/hooks/"
cp -r "$SCRIPT_DIR"/scripts/lib/* "$DEST/scripts/lib/"

echo "✅ ファイルをコピーしました"

# hooks.json を settings.json にマージ
SETTINGS="$DEST/settings.json"
HOOKS_JSON="$SCRIPT_DIR/hooks/hooks.json"

# ${CLAUDE_PLUGIN_ROOT} を実際のインストールパスに置換
DEST_ESCAPED=$(printf '%s\n' "$DEST" | sed 's/[\/&]/\\&/g')
TMP_HOOKS=$(mktemp)
sed "s/\${CLAUDE_PLUGIN_ROOT}/$DEST_ESCAPED/g" "$HOOKS_JSON" > "$TMP_HOOKS"

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
echo "1. CLAUDE.md をプロジェクトルートにコピー"
echo "   cp \"$SCRIPT_DIR/CLAUDE.md\" /path/to/your/project/"
echo ""
echo "2. MCP を設定（README.md の「MCPセットアップ」を参照）"
echo ""
echo "3. Claude Code を再起動"
echo ""
echo "4. /plan や /tdd コマンドが使えることを確認"
