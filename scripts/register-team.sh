#!/bin/bash
# Cadastra um novo time em data/teams.yaml
# Uso: bash register-team.sh --id team-xyz --name "XYZ" [--slack "#xyz"] [--repos repo1,repo2] [--pr]

set -e

TEAM_ID=""
TEAM_NAME=""
TEAM_SLACK=""
TEAM_REPOS=""
TEAM_DOC_TYPES="technical,product,faq"
OPEN_PR=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --id)         TEAM_ID="$2";        shift 2 ;;
        --name)       TEAM_NAME="$2";      shift 2 ;;
        --slack)      TEAM_SLACK="$2";     shift 2 ;;
        --repos)      TEAM_REPOS="$2";     shift 2 ;;
        --doc-types)  TEAM_DOC_TYPES="$2"; shift 2 ;;
        --pr)         OPEN_PR=true;        shift ;;
        *) echo "Erro: opção desconhecida: $1"; exit 1 ;;
    esac
done

# Valida disponibilidade de ferramentas para --pr
if [[ "$OPEN_PR" == true ]]; then
    if ! command -v git &> /dev/null; then
        echo "❌ Erro: --pr requer Git instalado"
        exit 1
    fi
    if ! command -v gh &> /dev/null; then
        echo "❌ Erro: --pr requer GitHub CLI (gh) instalado"
        echo ""
        echo "Instale em https://cli.github.com ou use:"
        echo "  bash register-team.sh --id $TEAM_ID --name '$TEAM_NAME' # sem --pr"
        echo "  Depois faça commit e push manualmente"
        exit 1
    fi
fi

# Validação básica
: "${TEAM_ID:?Faltou: --id team-xyz}"
: "${TEAM_NAME:?Faltou: --name 'Nome do Time'}"

[[ ! -f "data/teams.yaml" ]] && echo "Erro: rode dentro do docs-hub" && exit 1

TEAM_ID="${TEAM_ID// /}"

if grep -q "^  - id: ${TEAM_ID}$" "data/teams.yaml" 2>/dev/null; then
    echo "Erro: time '${TEAM_ID}' já existe"
    exit 1
fi

# Formata doc_types como lista YAML
DOC_TYPES_YAML="["
IFS=',' read -ra DT_LIST <<< "$TEAM_DOC_TYPES"
for dt in "${DT_LIST[@]}"; do
    DOC_TYPES_YAML="${DOC_TYPES_YAML}${dt// /}, "
done
DOC_TYPES_YAML="${DOC_TYPES_YAML%, }]"

# Escreve em data/teams.yaml
{
    echo ""
    echo "  - id: ${TEAM_ID}"
    echo "    name: \"${TEAM_NAME}\""
    [[ -n "$TEAM_SLACK" ]] && echo "    slack: \"${TEAM_SLACK}\""
    if [[ -n "$TEAM_REPOS" ]]; then
        echo "    repos:"
        IFS=',' read -ra REPO_LIST <<< "$TEAM_REPOS"
        for repo in "${REPO_LIST[@]}"; do
            echo "      - ${repo// /}"
        done
    fi
    echo "    doc_types: ${DOC_TYPES_YAML}"
} >> "data/teams.yaml"

# Cria estrutura de conteúdo
TODAY=$(date +%Y-%m-%d)
mkdir -p "content/teams/${TEAM_ID}"

cat > "content/teams/${TEAM_ID}/_index.md" <<EOF
---
title: "${TEAM_NAME}"
description: "Documentação do time ${TEAM_NAME}"
---
EOF

# Cria seções por doc_type
IFS=',' read -ra DT_LIST <<< "$TEAM_DOC_TYPES"
for dt in "${DT_LIST[@]}"; do
    dt="${dt// /}"
    mkdir -p "content/teams/${TEAM_ID}/$dt"

    dt_title=$(echo "$dt" | sed 's/^./\U&/')
    cat > "content/teams/${TEAM_ID}/$dt/_index.md" <<EOF
---
title: "${dt_title}"
team: "${TEAM_ID}"
---
EOF
done

echo "✓ Time '${TEAM_ID}' adicionado"
echo "  Arquivo: data/teams.yaml"
echo "  Pasta: content/teams/${TEAM_ID}/"

# Abre PR se solicitado e git está disponível
if [[ "$OPEN_PR" == true ]]; then
    BRANCH="register-team/${TEAM_ID}"

    git fetch origin --quiet
    git checkout main --quiet
    git reset --hard origin/main --quiet
    git branch -D "$BRANCH" 2>/dev/null || true
    git checkout -b "$BRANCH"

    git config user.name "DocHub Bot"
    git config user.email "dochub-bot@noreply.github.com"
    git add data/teams.yaml "content/teams/${TEAM_ID}"
    git commit -m "feat: cadastra time ${TEAM_ID}"

    if command -v gh &> /dev/null; then
        PR_URL=$(gh pr create \
            --head "$BRANCH" \
            --base main \
            --title "feat: cadastra time ${TEAM_ID}" \
            --body "Cadastra o time \`${TEAM_ID}\` no docs-hub.

**Nome:** ${TEAM_NAME}
**Slack:** ${TEAM_SLACK:----}
**Repos:** ${TEAM_REPOS:----}
**Doc types:** ${TEAM_DOC_TYPES}")

        echo "✓ PR aberto: ${PR_URL}"
    else
        echo "⚠ GitHub CLI (gh) não encontrado. Commit criado na branch '${BRANCH}', mas PR não foi aberto."
        echo "  Faça o push manualmente e abra um PR no GitHub."
    fi
else
    echo ""
    echo "Para abrir um PR automaticamente, use: bash register-team.sh --pr"
fi
