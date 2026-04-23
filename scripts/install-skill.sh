#!/bin/bash
# Instala a skill /doc-pr no repo atual (não globalmente).
# Rode este script de dentro do repo que vai gerar documentação.
#
# Uso:
#   bash <(gh api repos/ORG/docs-hub/contents/scripts/install-skill.sh --jq '.content' | base64 -d) \
#     --hub-repo org/docs-hub \
#     --teams team-payments,team-checkout \
#     --project payments-api \
#     --doc-types technical,product,faq

set -e

DOCHUB_REPO=""
TEAMS=""
PROJECT=""
DOC_TYPES="technical,product,faq"

while [[ $# -gt 0 ]]; do
    case $1 in
        --hub-repo)   DOCHUB_REPO="$2"; shift 2 ;;
        --teams)      TEAMS="$2";       shift 2 ;;
        --project)    PROJECT="$2";     shift 2 ;;
        --doc-types)  DOC_TYPES="$2";   shift 2 ;;
        *) echo "Opção desconhecida: $1"; exit 1 ;;
    esac
done

: "${DOCHUB_REPO:?Use --hub-repo org/docs-hub}"
: "${TEAMS:?Use --teams team-payments ou --teams team-payments,team-checkout}"

PROJECT="${PROJECT:-$(basename "$PWD")}"

git rev-parse --git-dir > /dev/null 2>&1 || { echo "Erro: rode dentro de um repositório git."; exit 1; }

echo "Instalando skill /doc-pr em $(pwd)..."

mkdir -p .claude/commands

for skill in doc-pr doc-feature doc-module; do
    gh api "repos/$DOCHUB_REPO/contents/templates/${skill}.md" \
        --jq '.content' | base64 -d > ".claude/commands/${skill}.md"
done

cat > .dochubrc <<EOF
DOCHUB_REPO=$DOCHUB_REPO
TEAMS=$TEAMS
PROJECT=$PROJECT
DOC_TYPES=$DOC_TYPES
EOF

echo ""
echo "✓ Skills instaladas em .claude/commands/"
echo "  - doc-pr.md"
echo "  - doc-feature.md"
echo "  - doc-module.md"
echo "✓ Configuração salva em .dochubrc"
echo ""
echo "  DOCHUB_REPO = $DOCHUB_REPO"
echo "  TEAMS       = $TEAMS"
echo "  PROJECT     = $PROJECT"
echo "  DOC_TYPES   = $DOC_TYPES"
echo ""
echo "Comandos disponíveis:"
echo "  /doc-pr 142"
echo "  /doc-feature pix-support --prs 138,141"
echo "  /doc-module src/payments"
