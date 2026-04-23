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

# --- Verifica suporte a GitHub ---

echo ""
read -rp "Você vai usar o GitHub para abrir PRs de documentação? (sim/não): " use_github
if [[ "$use_github" != "sim" && "$use_github" != "s" ]]; then
    echo ""
    echo "Aviso: atualmente o DocHub só tem suporte completo via GitHub."
    echo "As skills serão instaladas, mas a abertura automática de PRs não funcionará"
    echo "sem autenticação no GitHub CLI (gh auth login)."
    echo ""
    read -rp "Deseja continuar mesmo assim? (sim/não): " continuar
    if [[ "$continuar" != "sim" && "$continuar" != "s" ]]; then
        echo "Instalação cancelada."
        exit 0
    fi
fi

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

# --- Valida os times contra data/teams.yaml do docs-hub ---

if [[ -n "$DOCHUB_PATH" ]]; then
    TEAMS_YAML="$DOCHUB_PATH/data/teams.yaml"
    if [[ ! -f "$TEAMS_YAML" ]]; then
        echo "Erro: $TEAMS_YAML não encontrado."
        exit 1
    fi
    VALID_TEAMS=$(grep "^  - id:" "$TEAMS_YAML" | sed 's/  - id: //')
else
    VALID_TEAMS=$(gh api "repos/$DOCHUB_REPO/contents/data/teams.yaml" \
        --jq '.content' | base64 -d | grep "^  - id:" | sed 's/  - id: //')
fi

INVALID=""
IFS=',' read -ra TEAM_LIST <<< "$TEAMS"
for t in "${TEAM_LIST[@]}"; do
    t="${t// /}"  # remove espaços
    if ! echo "$VALID_TEAMS" | grep -qx "$t"; then
        INVALID="$INVALID $t"
    fi
done

if [[ -n "$INVALID" ]]; then
    echo ""
    echo "Erro: os seguintes times não existem no docs-hub:$INVALID"
    echo ""
    echo "Times disponíveis:"
    echo "$VALID_TEAMS" | sed 's/^/  - /'
    echo ""
    echo "Para cadastrar um novo time, edite data/teams.yaml no docs-hub e abra um PR."
    exit 1
fi

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
