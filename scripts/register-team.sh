#!/bin/bash
# Cadastra um novo time em data/teams.yaml
# Uso: bash register-team.sh --id team-xyz --name "XYZ" [--slack "#xyz"] [--repos repo1,repo2]

set -e

TEAM_ID=""
TEAM_NAME=""
TEAM_SLACK=""
TEAM_REPOS=""
TEAM_DOC_TYPES="technical,product,faq"

while [[ $# -gt 0 ]]; do
    case $1 in
        --id)         TEAM_ID="$2";        shift 2 ;;
        --name)       TEAM_NAME="$2";      shift 2 ;;
        --slack)      TEAM_SLACK="$2";     shift 2 ;;
        --repos)      TEAM_REPOS="$2";     shift 2 ;;
        --doc-types)  TEAM_DOC_TYPES="$2"; shift 2 ;;
        *) echo "Erro: opção desconhecida: $1"; exit 1 ;;
    esac
done

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
