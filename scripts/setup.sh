#!/bin/bash
# Setup simplificado com .env — rode uma vez após clonar

set -e

echo "╔══════════════════════════════════════╗"
echo "║       DocHub — Setup Rápido          ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Verifica se estamos na raiz
if [[ ! -f "hugo.toml" || ! -d "content/teams" ]]; then
    echo "Erro: rode este script na raiz do repositório."
    exit 1
fi

# Carrega .env se existir, senão usa defaults
if [[ -f ".env" ]]; then
    set -a
    source .env
    set +a
    echo "✓ Configurações carregadas de .env"
else
    echo "⚠ Arquivo .env não encontrado. Usando defaults..."
    ORG_NAME="${ORG_NAME:-Sua Empresa}"
    SITE_TITLE="${SITE_TITLE:-DocHub}"
    BASE_URL="${BASE_URL:-http://localhost:1313}"
    LANGUAGE_CODE="${LANGUAGE_CODE:-pt-br}"
    SUPPORTED_LANGUAGES="${SUPPORTED_LANGUAGES:-pt-br}"
fi

echo ""
echo "Configurando Hugo..."
echo ""

# Atualiza hugo.toml com os valores do .env
sed -i.bak \
    "s|^baseURL = .*|baseURL = \"$BASE_URL\"|; \
     s|^languageCode = .*|languageCode = \"$LANGUAGE_CODE\"|; \
     s|^title = .*|title = \"$SITE_TITLE\"|; \
     s|org.*= \".*\"|org         = \"$ORG_NAME\"|; \
     s|description.*= \".*\"|description = \"Documentação centralizada de todos os times de $ORG_NAME\"|" \
    hugo.toml && rm -f hugo.toml.bak

echo "✓ Hugo configurado (baseURL, languageCode, title, org, description)"
echo "  - Base URL: $BASE_URL"
echo "  - Idioma principal: $LANGUAGE_CODE"
echo "  - Idiomas suportados: $SUPPORTED_LANGUAGES"

# Limpa conteúdo de exemplo
if [[ -d "content/teams/sample" ]]; then
    rm -rf content/teams/sample
    echo "✓ Removido conteúdo de exemplo"
fi

# Inicializa teams.yaml vazio
cat > data/teams.yaml <<'EOF'
teams: []
EOF

echo "✓ Estrutura de dados resetada"
echo ""

# Configura i18n baseado em variáveis de ambiente
echo "Configurando internacionalização (i18n)..."
python3 scripts/manage-i18n.py
echo ""

# Cria diretórios de conteúdo para cada idioma suportado
IFS=',' read -ra langs <<< "$SUPPORTED_LANGUAGES"
for lang in "${langs[@]}"; do
    lang=$(echo "$lang" | xargs)
    mkdir -p "content/$lang/teams"
    echo "✓ Criado diretório de conteúdo: content/$lang"
done

echo ""
echo "╔══════════════════════════════════════╗"
echo "║         Setup concluído! 🎉          ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Próximos passos:"
echo ""
echo "  1. Criar seu primeiro time:"
echo "     bash scripts/register-team.sh --id team-1 --name 'Time 1'"
echo ""
echo "  2. Rodar localmente:"
echo "     hugo server --buildDrafts"
echo ""
