#!/bin/bash
# Instala a skill /doc-pr no repo atual (não globalmente).
# Rode este script de dentro do repo que vai gerar documentação.
#
# Uso:
#   bash <(gh api repos/ORG/docs-hub/contents/scripts/install-skill.sh --jq '.content' | base64 -d) \
#     --hub-repo org/docs-hub \
#     --team team-payments \
#     --project payments-api \
#     --doc-types technical,product,faq
#
# Ou, se já clonou o docs-hub:
#   bash /caminho/para/docs-hub/scripts/install-skill.sh --hub-repo org/docs-hub --team team-payments

set -e

DOCHUB_REPO=""
TEAM=""
PROJECT=""
DOC_TYPES="technical,product,faq"

while [[ $# -gt 0 ]]; do
    case $1 in
        --hub-repo)   DOCHUB_REPO="$2"; shift 2 ;;
        --team)       TEAM="$2";        shift 2 ;;
        --project)    PROJECT="$2";     shift 2 ;;
        --doc-types)  DOC_TYPES="$2";   shift 2 ;;
        *) echo "Opção desconhecida: $1"; exit 1 ;;
    esac
done

: "${DOCHUB_REPO:?Use --hub-repo org/docs-hub}"
: "${TEAM:?Use --team team-payments}"

# Default: nome da pasta atual
PROJECT="${PROJECT:-$(basename "$PWD")}"

# Verifica se está dentro de um repo git
git rev-parse --git-dir > /dev/null 2>&1 || { echo "Erro: rode dentro de um repositório git."; exit 1; }

echo "Instalando skill /doc-pr em $(pwd)..."

mkdir -p .claude/commands

# Baixa o template da skill do docs-hub
gh api "repos/$DOCHUB_REPO/contents/templates/doc-pr.md" \
    --jq '.content' | base64 -d > .claude/commands/doc-pr.md

# Cria o arquivo de configuração local
cat > .dochubrc <<EOF
DOCHUB_REPO=$DOCHUB_REPO
TEAM=$TEAM
PROJECT=$PROJECT
DOC_TYPES=$DOC_TYPES
EOF

echo ""
echo "✓ Skill instalada em .claude/commands/doc-pr.md"
echo "✓ Configuração salva em .dochubrc"
echo ""
echo "  DOCHUB_REPO = $DOCHUB_REPO"
echo "  TEAM        = $TEAM"
echo "  PROJECT     = $PROJECT"
echo "  DOC_TYPES   = $DOC_TYPES"
echo ""
echo "Use: /doc-pr 142"
echo "     /doc-pr 142 --only technical"
