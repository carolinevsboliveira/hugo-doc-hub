#!/bin/bash
# Instala as skills /doc-pr, /doc-feature e /doc-module no repo atual (não globalmente).
# Rode este script de dentro do repo que vai gerar documentação.
#
# Uso não-interativo (todos os valores via flags):
#   bash install-skill.sh \
#     --hub-repo org/docs-hub \
#     --teams team-payments,team-checkout \
#     --project payments-api \
#     --doc-types technical,product,faq
#
# Uso interativo (omita as flags — o script pergunta):
#   bash install-skill.sh

set -e

DOCHUB_REPO=""
DOCHUB_PATH=""
TEAMS=""
PROJECT=""
DOC_TYPES="technical,product,faq"

while [[ $# -gt 0 ]]; do
    case $1 in
        --hub-repo)   DOCHUB_REPO="$2"; shift 2 ;;
        --hub-path)   DOCHUB_PATH="$2"; shift 2 ;;
        --teams)      TEAMS="$2";       shift 2 ;;
        --project)    PROJECT="$2";     shift 2 ;;
        --doc-types)  DOC_TYPES="$2";   shift 2 ;;
        *) echo "Opção desconhecida: $1"; exit 1 ;;
    esac
done

git rev-parse --git-dir > /dev/null 2>&1 || { echo "Erro: rode dentro de um repositório git."; exit 1; }

# --- Modo interativo: preenche o que não veio via flags ---

if [[ -z "$DOCHUB_PATH" && -z "$DOCHUB_REPO" ]]; then
    echo ""
    read -rp "Você tem o docs-hub clonado localmente? Digite o caminho (ou Enter para pular): " DOCHUB_PATH
    if [[ -n "$DOCHUB_PATH" ]]; then
        # Expande ~ manualmente (read não faz isso)
        DOCHUB_PATH="${DOCHUB_PATH/#\~/$HOME}"
        if [[ ! -d "$DOCHUB_PATH/.git" ]]; then
            echo "Aviso: '$DOCHUB_PATH' não parece um repositório git. Ignorando."
            DOCHUB_PATH=""
        fi
    fi
    if [[ -z "$DOCHUB_PATH" ]]; then
        read -rp "Informe o repositório do docs-hub (ex: org/docs-hub): " DOCHUB_REPO
    fi
fi

if [[ -z "$DOCHUB_REPO" && -z "$DOCHUB_PATH" ]]; then
    echo "Erro: é necessário informar --hub-repo org/docs-hub ou --hub-path /caminho/local/docs-hub"
    exit 1
fi

if [[ -z "$TEAMS" ]]; then
    echo ""
    read -rp "Times associados a este repo (ex: team-payments ou team-payments,team-checkout): " TEAMS
fi

: "${TEAMS:?Times não informados. Use --teams ou responda à pergunta acima.}"

PROJECT="${PROJECT:-$(basename "$PWD")}"

if [[ -z "$DOC_TYPES" || "$DOC_TYPES" == "technical,product,faq" ]]; then
    echo ""
    read -rp "Tipos de documentação [technical,product,faq]: " input_types
    DOC_TYPES="${input_types:-technical,product,faq}"
fi

echo ""
echo "Instalando skills em $(pwd)..."

mkdir -p .claude/commands

# Copia os templates: do path local (se disponível) ou via gh api
for skill in doc-pr doc-feature doc-module; do
    if [[ -n "$DOCHUB_PATH" ]]; then
        cp "$DOCHUB_PATH/templates/${skill}.md" ".claude/commands/${skill}.md"
    else
        gh api "repos/$DOCHUB_REPO/contents/templates/${skill}.md" \
            --jq '.content' | base64 -d > ".claude/commands/${skill}.md"
    fi
done

cat > .dochubrc <<EOF
DOCHUB_REPO=$DOCHUB_REPO
DOCHUB_PATH=$DOCHUB_PATH
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
echo "  TEAMS     = $TEAMS"
echo "  PROJECT   = $PROJECT"
echo "  DOC_TYPES = $DOC_TYPES"
[[ -n "$DOCHUB_PATH" ]] && echo "  DOCHUB_PATH = $DOCHUB_PATH" || echo "  DOCHUB_REPO = $DOCHUB_REPO"
echo ""
echo "Comandos disponíveis:"
echo "  /doc-pr 142"
echo "  /doc-feature pix-support --prs 138,141"
echo "  /doc-module src/payments"
