#!/bin/bash
# Setup simplificado com .env — rode uma vez após clonar

set -e

# Helper function to trim whitespace
trim() {
    local var="$1"
    var="${var#"${var%%[![:space:]]*}"}"   # Remove leading whitespace
    var="${var%"${var##*[![:space:]]}"}"   # Remove trailing whitespace
    printf '%s' "$var"
}

echo "╔══════════════════════════════════════╗"
echo "║       DocHub — Setup Rápido          ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Verifica se estamos na raiz
if [[ ! -f "hugo.toml" || ! -d "content" || ! -d "data" ]]; then
    echo "Erro: rode este script na raiz do repositório."
    exit 1
fi

# Carrega .env se existir, senão pergunta ao usuário
if [[ -f ".env" ]]; then
    set -a
    source .env
    set +a
    echo "✓ Configurações carregadas de .env"
else
    echo "⚠ Arquivo .env não encontrado. Configure os idiomas:"
    echo ""
    read -rp "Idioma principal (pt-br/en-us/outro) [pt-br]: " LANGUAGE_CODE
    LANGUAGE_CODE="${LANGUAGE_CODE:-pt-br}"

    read -rp "Idiomas suportados (separados por vírgula) [pt-br,en-us]: " SUPPORTED_LANGUAGES
    SUPPORTED_LANGUAGES="${SUPPORTED_LANGUAGES:-pt-br,en-us}"
    # Remove spaces after commas for consistency
    SUPPORTED_LANGUAGES="${SUPPORTED_LANGUAGES// /}"

    read -rp "Nome da organização [Sua Empresa]: " ORG_NAME
    ORG_NAME="${ORG_NAME:-Sua Empresa}"

    read -rp "Título do site [DocHub]: " SITE_TITLE
    SITE_TITLE="${SITE_TITLE:-DocHub}"

    read -rp "URL base [http://localhost:1313]: " BASE_URL
    BASE_URL="${BASE_URL:-http://localhost:1313}"

    # Salva em .env para próximas execuções
    cat > .env <<EOF
ORG_NAME="$ORG_NAME"
SITE_TITLE="$SITE_TITLE"
BASE_URL="$BASE_URL"
LANGUAGE_CODE="$LANGUAGE_CODE"
SUPPORTED_LANGUAGES="$SUPPORTED_LANGUAGES"
EOF
    echo "✓ Configurações salvas em .env"
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
    lang=$(trim "$lang")
    [[ -z "$lang" ]] && continue
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
