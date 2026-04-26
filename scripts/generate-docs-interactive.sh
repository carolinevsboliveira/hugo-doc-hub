#!/bin/bash
# Script interativo simplificado para gerar documentação via Claude
# Coleta informações e gera docs com um fluxo amigável

set -e

echo "╔══════════════════════════════════════╗"
echo "║   Gerador de Documentação DocHub     ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Tenta inferir projeto do git
INFERRED_PROJECT=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    INFERRED_PROJECT=$(git config --get remote.origin.url | sed 's|.*/||' | sed 's|\.git$||' | sed 's|-docs||')
fi

# Pergunta pelo tipo de documentação
echo "📝 Qual tipo de documentação deseja gerar?"
echo "   1) Técnica (arquitetura, APIs, padrões)"
echo "   2) Produto (features, funcionalidades)"
echo "   3) FAQ (perguntas frequentes)"
echo "   4) Todos os três (padrão)"
read -rp "Escolha [1-4, padrão=4]: " doc_choice

case "$doc_choice" in
    1) DOC_TYPES="technical" ;;
    2) DOC_TYPES="product" ;;
    3) DOC_TYPES="faq" ;;
    *) DOC_TYPES="technical,product,faq" ;;
esac

echo ""
echo "📋 Informações do projeto:"
echo ""

# Projeto
read -rp "Nome do projeto${INFERRED_PROJECT:+ [$INFERRED_PROJECT]}: " PROJECT
PROJECT="${PROJECT:-$INFERRED_PROJECT}"
: "${PROJECT:?Projeto é obrigatório}"

# Time
read -rp "ID do time (ex: team-payments): " TEAM
: "${TEAM:?Time é obrigatório}"

echo ""
echo "📄 Contexto da mudança:"
echo ""

# Título
read -rp "Título da mudança: " TITLE
: "${TITLE:?Título é obrigatório}"

echo ""
echo "Descrição (pode ser multilinhas. Digite '.' sozinho em uma linha para terminar):"
DESCRIPTION=""
while IFS= read -r line; do
    [[ "$line" == "." ]] && break
    DESCRIPTION+="$line"$'\n'
done
DESCRIPTION="${DESCRIPTION%$'\n'}"

# Arquivos alterados
echo ""
echo "Arquivos alterados (separados por vírgula):"
echo "Ex: src/api.ts, src/db.ts, README.md"
read -rp "> " CHANGED_FILES

# Resumo do diff
echo ""
echo "Resumo das alterações (breve):"
read -rp "> " DIFF_SUMMARY

# README do projeto (opcional)
echo ""
echo "README atual do projeto (opcional, Enter para pular):"
read -rp "> " README

# Número do PR (opcional)
echo ""
read -rp "Número do PR (opcional, Enter para 'push'): " PR_NUMBER
PR_NUMBER="${PR_NUMBER:-push}"

# Tags (opcional)
echo ""
read -rp "Tags (separadas por vírgula, opcional): " TAGS

# Montar JSON de contexto
CONTEXT_FILE="/tmp/docgen-context-$RANDOM.json"
cat > "$CONTEXT_FILE" <<EOF
{
  "pr_number": "$PR_NUMBER",
  "pr_title": "$TITLE",
  "pr_body": "$DESCRIPTION",
  "changed_files": [$(echo "$CHANGED_FILES" | sed 's/, /\n/g' | sed 's/^/"/; s/$/"/' | paste -sd ',' -)],
  "diff_summary": "$DIFF_SUMMARY",
  "readme": "$README",
  "tags": [$(echo "$TAGS" | sed 's/, /\n/g' | sed 's/^/"/; s/$/"/' | paste -sd ',' -)]
}
EOF

# Diretório de saída
OUTPUT_DIR="content/teams/${TEAM}/docs"

echo ""
echo "────────────────────────────────────"
echo "  📦 Projeto:       $PROJECT"
echo "  👥 Time:          $TEAM"
echo "  📚 Doc types:     $DOC_TYPES"
echo "  📂 Saída:         $OUTPUT_DIR"
echo "────────────────────────────────────"
echo ""

# Pergunta se quer abrir PR
OPEN_PR=false
if command -v git &> /dev/null; then
    read -rp "Abrir PR automaticamente? (s/n, padrão=n): " pr_choice
    [[ "$pr_choice" == "s" || "$pr_choice" == "sim" ]] && OPEN_PR=true
fi

echo ""
echo "⏳ Gerando documentação..."
echo ""

# Executa generate-docs.py
GENERATE_CMD="python scripts/generate-docs.py \
  --context '$CONTEXT_FILE' \
  --doc-types '$DOC_TYPES' \
  --project '$PROJECT' \
  --team '$TEAM' \
  --output '$OUTPUT_DIR'"

if [[ "$OPEN_PR" == true ]]; then
    GENERATE_CMD="$GENERATE_CMD --pr"
fi

eval "$GENERATE_CMD"

# Limpa arquivo temporário
rm -f "$CONTEXT_FILE"

echo ""
echo "✅ Documentação gerada com sucesso!"
echo ""
echo "Próximos passos:"
if [[ "$OPEN_PR" == false ]]; then
    echo "  1. Revisar arquivos em: $OUTPUT_DIR"
    echo "  2. Fazer commit: git add content/teams/$TEAM"
    echo "  3. Push: git push origin sua-branch"
    echo "  4. Abrir PR no GitHub"
else
    echo "  1. Revisar PR no GitHub"
    echo "  2. Merge quando aprovado"
fi
echo ""
