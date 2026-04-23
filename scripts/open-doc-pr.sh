#!/bin/bash
# Abre um PR no docs-hub com os arquivos de documentação gerados.
# Chamado pela skill /doc-pr ao final da geração.
#
# Variáveis de ambiente necessárias:
#   DOCHUB_REPO   — ex: carolinevsboliveira/docs-hub
#   DOCHUB_TOKEN  — GitHub PAT com permissão de repo (ou usa gh auth)
#
# Uso:
#   bash open-doc-pr.sh <team> <project> <pr_number> <source_pr_url> <docs_dir>
#
# Exemplo:
#   bash open-doc-pr.sh team-payments payments-api 142 https://github.com/org/payments-api/pull/142 /tmp/docs

set -e

TEAM="$1"
PROJECT="$2"
SOURCE_PR="$3"
SOURCE_PR_URL="$4"
DOCS_DIR="$5"

: "${TEAM:?Argumento 1 (team) obrigatório}"
: "${PROJECT:?Argumento 2 (project) obrigatório}"
: "${SOURCE_PR:?Argumento 3 (pr_number) obrigatório}"
: "${DOCS_DIR:?Argumento 5 (docs_dir) obrigatório}"

if [[ -z "$DOCHUB_PATH" && -z "$DOCHUB_REPO" ]]; then
    echo "Erro: defina DOCHUB_PATH ou DOCHUB_REPO"
    exit 1
fi

BRANCH="docs/${TEAM}/${PROJECT}/pr-${SOURCE_PR}"
DEST="content/teams/${TEAM}"

# Usa path local se disponível, clona se não
if [[ -n "$DOCHUB_PATH" && -d "$DOCHUB_PATH/.git" ]]; then
    echo "→ Usando repo local: ${DOCHUB_PATH}"
    HUB_DIR="$DOCHUB_PATH"
    cd "$HUB_DIR"

    # Garante estado limpo antes de qualquer operação
    git fetch origin --quiet
    git checkout main --quiet
    git reset --hard origin/main --quiet

    # Deriva DOCHUB_REPO do remote caso não tenha sido passado
    if [[ -z "$DOCHUB_REPO" ]]; then
        DOCHUB_REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
    fi
else
    echo "→ Clonando ${DOCHUB_REPO}..."
    HUB_DIR=$(mktemp -d)
    gh repo clone "$DOCHUB_REPO" "$HUB_DIR" -- --quiet
    cd "$HUB_DIR"
    # Clone já traz o estado mais recente — fetch implícito
fi

# Valida se o time existe em data/teams.yaml
TEAMS_FILE="data/teams.yaml"
if [[ ! -f "$TEAMS_FILE" ]]; then
    echo "Erro: $TEAMS_FILE não encontrado no docs-hub."
    exit 1
fi

VALID_TEAMS=$(grep "^  - id:" "$TEAMS_FILE" | sed 's/  - id: //')
if ! echo "$VALID_TEAMS" | grep -qx "$TEAM"; then
    echo "Erro: time '$TEAM' não está cadastrado no docs-hub."
    echo ""
    echo "Times disponíveis:"
    echo "$VALID_TEAMS" | sed 's/^/  - /'
    echo ""
    echo "Para adicionar o time, edite $TEAMS_FILE no docs-hub e abra um PR."
    exit 1
fi

# Recria a branch do zero caso já exista de um run anterior
git branch -D "$BRANCH" 2>/dev/null || true
git checkout -b "$BRANCH"

if [[ -n "$DOCS_DIR" ]]; then
    echo "→ Copiando arquivos de ${DOCS_DIR}..."
    for type_dir in "${DOCS_DIR}"/*/; do
        doc_type=$(basename "$type_dir")
        target="${DEST}/${doc_type}"
        mkdir -p "$target"
        cp "$type_dir"*.md "$target/" 2>/dev/null || true
    done
else
    echo "→ Arquivos já em ${DEST} (DOCHUB_PATH local)"
fi

echo "→ Commitando..."
git config user.name "DocHub Bot"
git config user.email "dochub-bot@noreply.github.com"
git add .

if git diff --cached --quiet; then
    echo "Nenhuma mudança detectada. Abortando."
    exit 0
fi

git commit -m "docs(${TEAM}): auto-doc ${PROJECT} PR #${SOURCE_PR}"

echo "→ Abrindo PR no ${DOCHUB_REPO}..."
PR_URL=$(gh pr create \
    --repo "$DOCHUB_REPO" \
    --head "$BRANCH" \
    --base main \
    --title "docs(${TEAM}): ${PROJECT} PR #${SOURCE_PR}" \
    --body "Documentação gerada automaticamente a partir de ${SOURCE_PR_URL:-PR #$SOURCE_PR}.

**Time:** \`${TEAM}\`
**Projeto:** \`${PROJECT}\`
**PR de origem:** ${SOURCE_PR_URL:-#$SOURCE_PR}

---
*Gerado pela skill \`/doc-pr\` do DocHub*")

echo ""
echo "✓ PR de documentação aberto: ${PR_URL}"
echo "$PR_URL"
