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
fi

echo ""
echo "Configurando Hugo..."
echo ""

# Atualiza hugo.toml com os valores do .env
sed -i.bak \
    "s|^baseURL = .*|baseURL = \"$BASE_URL\"|; \
     s|^title = .*|title = \"$SITE_TITLE\"|; \
     s|org.*= \".*\"|org         = \"$ORG_NAME\"|; \
     s|description.*= \".*\"|description = \"Documentação centralizada de todos os times de $ORG_NAME\"|" \
    hugo.toml && rm -f hugo.toml.bak

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
