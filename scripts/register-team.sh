#!/bin/bash
# Cadastra um novo time em data/teams.yaml do docs-hub.
# Rode de dentro do docs-hub ou defina DOCHUB_PATH.
#
# Uso não-interativo:
#   bash register-team.sh --id team-xyz --name "XYZ" --slack "#team-xyz" \
#     --repos api-xyz --doc-types technical,product,faq --pr
#
# Uso interativo (omita as flags — o script pergunta):
#   bash register-team.sh [--pr]

set -e

TEAM_ID=""
TEAM_NAME=""
TEAM_SLACK=""
TEAM_REPOS=""
TEAM_DOC_TYPES=""
OPEN_PR=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --id)         TEAM_ID="$2";        shift 2 ;;
        --name)       TEAM_NAME="$2";      shift 2 ;;
        --slack)      TEAM_SLACK="$2";     shift 2 ;;
        --repos)      TEAM_REPOS="$2";     shift 2 ;;
        --doc-types)  TEAM_DOC_TYPES="$2"; shift 2 ;;
        --pr)         OPEN_PR=true;        shift ;;
        *) echo "Opção desconhecida: $1"; exit 1 ;;
    esac
done

# Determina o diretório do docs-hub
if [[ -n "$DOCHUB_PATH" && -d "$DOCHUB_PATH/.git" ]]; then
    HUB_DIR="$DOCHUB_PATH"
elif [[ -f "data/teams.yaml" ]]; then
    HUB_DIR="$(pwd)"
else
    echo "Erro: rode dentro do docs-hub ou defina DOCHUB_PATH=/caminho/docs-hub"
    exit 1
fi

TEAMS_FILE="$HUB_DIR/data/teams.yaml"

# --- Coleta interativa ---

echo ""

if [[ -z "$TEAM_ID" ]]; then
    read -rp "ID do time (ex: team-payments): " TEAM_ID
fi
TEAM_ID="${TEAM_ID// /}"
: "${TEAM_ID:?ID do time não pode ser vazio}"

if grep -q "^  - id: ${TEAM_ID}$" "$TEAMS_FILE" 2>/dev/null; then
    echo "Erro: time '${TEAM_ID}' já existe em data/teams.yaml"
    exit 1
fi

if [[ -z "$TEAM_NAME" ]]; then
    read -rp "Nome de exibição (ex: Payments): " TEAM_NAME
fi
: "${TEAM_NAME:?Nome do time não pode ser vazio}"

if [[ -z "$TEAM_SLACK" ]]; then
    read -rp "Canal Slack (ex: #team-payments) [Enter para pular]: " TEAM_SLACK
fi

if [[ -z "$TEAM_REPOS" ]]; then
    read -rp "Repositórios associados, separados por vírgula (ex: payments-api) [Enter para pular]: " TEAM_REPOS
fi

if [[ -z "$TEAM_DOC_TYPES" ]]; then
    read -rp "Tipos de documentação [technical,product,faq]: " input_types
    TEAM_DOC_TYPES="${input_types:-technical,product,faq}"
fi

# Formata doc_types como lista YAML inline: [technical, product, faq]
DOC_TYPES_YAML="["
IFS=',' read -ra DT_LIST <<< "$TEAM_DOC_TYPES"
for dt in "${DT_LIST[@]}"; do
    DOC_TYPES_YAML="${DOC_TYPES_YAML}${dt// /}, "
done
DOC_TYPES_YAML="${DOC_TYPES_YAML%, }]"

# --- Preview e confirmação ---

echo ""
echo "────────────────────────────────────"
echo "  ID:        $TEAM_ID"
echo "  Nome:      $TEAM_NAME"
[[ -n "$TEAM_SLACK" ]] && echo "  Slack:     $TEAM_SLACK"
[[ -n "$TEAM_REPOS" ]] && echo "  Repos:     $TEAM_REPOS"
echo "  Doc types: $TEAM_DOC_TYPES"
echo "────────────────────────────────────"
echo ""
read -rp "Confirma o cadastro? (sim/não): " confirm
if [[ "$confirm" != "sim" && "$confirm" != "s" ]]; then
    echo "Abortado."
    exit 0
fi

# --- Escreve em data/teams.yaml ---

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
} >> "$TEAMS_FILE"

echo ""
echo "✓ Time '${TEAM_ID}' adicionado em data/teams.yaml"

# --- Cria estrutura de conteúdo com página de exemplo ---

TODAY=$(date +%Y-%m-%d)
TEAM_CONTENT_DIR="$HUB_DIR/content/teams/${TEAM_ID}"

# _index.md do time
mkdir -p "$TEAM_CONTENT_DIR"
cat > "$TEAM_CONTENT_DIR/_index.md" <<EOF
---
title: "${TEAM_NAME}"
description: "Documentação do time ${TEAM_NAME}"
---
EOF

# Para cada doc_type: _index.md da seção + página de exemplo
IFS=',' read -ra DT_LIST <<< "$TEAM_DOC_TYPES"
for dt in "${DT_LIST[@]}"; do
    dt="${dt// /}"
    TYPE_DIR="$TEAM_CONTENT_DIR/$dt"
    mkdir -p "$TYPE_DIR"

    dt_title=$(echo "$dt" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
    cat > "$TYPE_DIR/_index.md" <<EOF
---
title: "${dt_title}"
team: "${TEAM_ID}"
---
EOF

    cat > "$TYPE_DIR/sample-${TEAM_ID}.md" <<EOF
---
title: "Exemplo — ${TEAM_NAME}"
date: ${TODAY}
team: "${TEAM_ID}"
project: "${TEAM_REPOS%,*}"
doc_type: "${dt}"
draft: true
---

> Esta é uma página de exemplo gerada automaticamente. Substitua pelo conteúdo real.

## Visão geral

Descreva aqui o que está sendo documentado.

## Detalhes

Adicione as seções relevantes para o tipo \`${dt}\`.
EOF

    echo "  ✓ content/teams/${TEAM_ID}/${dt}/sample-${TEAM_ID}.md"
done

# --- Abre PR se solicitado ---

if [[ "$OPEN_PR" == true ]]; then
    cd "$HUB_DIR"
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

    if [[ -z "$DOCHUB_REPO" ]]; then
        DOCHUB_REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
    fi

    PR_URL=$(gh pr create \
        --repo "$DOCHUB_REPO" \
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
    echo ""
    echo "Para aplicar a mudança, abra um PR com data/teams.yaml ou rode com --pr:"
    echo "  bash register-team.sh --pr"
fi
