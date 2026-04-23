#!/bin/bash
# Copia docs gerados para o docs-hub e faz push
set -e

: "${HUB_REPO:?HUB_REPO não definido}"
: "${TEAM:?TEAM não definido}"
: "${PROJECT:?PROJECT não definido}"
: "${GH_TOKEN:?GH_TOKEN não definido}"
: "${DOCS_PATH:?DOCS_PATH não definido}"

git clone "https://x-access-token:${GH_TOKEN}@github.com/${HUB_REPO}.git" /tmp/docs-hub

DEST="content/teams/${TEAM}"

for doc_type_dir in "${DOCS_PATH}"*/; do
    doc_type=$(basename "$doc_type_dir")
    target="/tmp/docs-hub/${DEST}/${doc_type}/${PROJECT}"
    mkdir -p "$target"
    cp "$doc_type_dir"*.md "$target/" 2>/dev/null || true
done

cd /tmp/docs-hub
git config user.name "DocHub Bot"
git config user.email "dochub-bot@noreply.github.com"
git add .

if git diff --cached --quiet; then
    echo "Sem mudanças, pulando commit."
    exit 0
fi

git commit -m "docs(${TEAM}): auto-doc ${PROJECT} [skip ci]"
git push origin main
echo "✓ Docs enviados para docs-hub"
