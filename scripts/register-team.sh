#!/bin/bash
# Registra um novo time no docs-hub
# Uso: ./scripts/register-team.sh --id team-data --name "Data" --slack "#team-data" --doc-types "technical,faq"

set -e

ID=""; NAME=""; SLACK=""; DOC_TYPES="technical"

while [[ $# -gt 0 ]]; do
  case $1 in
    --id)         ID="$2";        shift 2 ;;
    --name)       NAME="$2";      shift 2 ;;
    --slack)      SLACK="$2";     shift 2 ;;
    --doc-types)  DOC_TYPES="$2"; shift 2 ;;
    *) echo "Opção desconhecida: $1"; exit 1 ;;
  esac
done

[ -z "$ID" ]   && echo "Erro: --id é obrigatório"   && exit 1
[ -z "$NAME" ] && echo "Erro: --name é obrigatório" && exit 1

echo "Registrando time: $NAME ($ID)..."

# Cria diretórios de conteúdo
for type in $(echo $DOC_TYPES | tr ',' ' '); do
  mkdir -p "content/teams/$ID/$type"
  if [ ! -f "content/teams/$ID/$type/_index.md" ]; then
    echo -e "---\ntitle: \"$type\"\n---" > "content/teams/$ID/$type/_index.md"
  fi
done

# Cria _index.md do time
cat > "content/teams/$ID/_index.md" << MDEOF
---
title: "$NAME"
description: "Documentação do time de $NAME"
---
MDEOF

# Adiciona ao teams.yaml
DOC_TYPES_YAML=$(echo $DOC_TYPES | sed 's/,/, /g' | sed 's/\([a-z]*\)/"\1"/g')
cat >> teams.yaml << YAMLEOF

  - id: $ID
    name: "$NAME"
    slack: "${SLACK:-#$ID}"
    repos: []
    doc_types: [$DOC_TYPES_YAML]
YAMLEOF

echo "✓ Time '$NAME' registrado com sucesso!"
echo "  Diretório: content/teams/$ID/"
echo ""
echo "Próximo passo: instale o auto-doc-skill nos repos do time."
