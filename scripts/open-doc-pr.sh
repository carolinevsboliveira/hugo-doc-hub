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

: "${DOCHUB_REPO:?Defina a variável DOCHUB_REPO (ex: export DOCHUB_REPO=org/docs-hub)}"
: "${TEAM:?Argumento 1 (team) obrigatório}"
: "${PROJECT:?Argumento 2 (project) obrigatório}"
: "${SOURCE_PR:?Argumento 3 (pr_number) obrigatório}"
: "${DOCS_DIR:?Argumento 5 (docs_dir) obrigatório}"

BRANCH="docs/${TEAM}/${PROJECT}/pr-${SOURCE_PR}"
DEST="content/teams/${TEAM}"

echo "→ Clonando ${DOCHUB_REPO}..."
CLONE_DIR=$(mktemp -d)
gh repo clone "$DOCHUB_REPO" "$CLONE_DIR" -- --quiet

cd "$CLONE_DIR"
git checkout -b "$BRANCH"

echo "→ Copiando arquivos gerados..."
for type_dir in "${DOCS_DIR}"/*/; do
    doc_type=$(basename "$type_dir")
    target="${DEST}/${doc_type}"
    mkdir -p "$target"
    cp "$type_dir"*.md "$target/" 2>/dev/null || true
done

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
