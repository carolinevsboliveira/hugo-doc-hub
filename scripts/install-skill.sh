#!/bin/bash
# Instala a skill /doc-pr globalmente no Claude Code.
# Após isso, o comando /doc-pr fica disponível em qualquer repo.
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/SEU-ORG/docs-hub/main/scripts/install-skill.sh | bash
#   ou:
#   bash scripts/install-skill.sh

set -e

SKILL_SRC="templates/global-skill-doc-pr.md"
SKILL_DST="$HOME/.claude/commands/doc-pr.md"

mkdir -p "$HOME/.claude/commands"

if [ -f "$SKILL_SRC" ]; then
    cp "$SKILL_SRC" "$SKILL_DST"
else
    # Baixa direto do repo se não estiver clonado
    : "${DOCHUB_REPO:?Defina DOCHUB_REPO antes de rodar}"
    gh api "repos/$DOCHUB_REPO/contents/templates/global-skill-doc-pr.md" \
        --jq '.content' | base64 -d > "$SKILL_DST"
fi

echo "✓ Skill instalada em $SKILL_DST"
echo ""
echo "Próximo passo — adicione ao seu ~/.zshrc ou ~/.bashrc:"
echo ""
echo "  export DOCHUB_REPO=\"sua-org/docs-hub\""
echo ""
echo "Depois rode: source ~/.zshrc"
echo "E teste com: /doc-pr 1 --repo sua-org/seu-projeto --team team-x"
