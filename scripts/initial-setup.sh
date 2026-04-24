#!/bin/bash
# Configura o docs-hub para uso pela sua organização.
# Rode uma vez após clonar o repositório.
#
# O que faz:
#   1. Pergunta os dados da organização
#   2. Atualiza hugo.toml com baseURL, título e org
#   3. Limpa o conteúdo de exemplo (content/teams/sample)
#   4. Reseta data/teams.yaml para a estrutura mínima
#   5. Registra o primeiro time interativamente (opcional)

set -e

echo ""
echo "╔══════════════════════════════════════╗"
echo "║       DocHub — Configuração Inicial  ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Garante que estamos na raiz do docs-hub
if [[ ! -f "hugo.toml" || ! -d "content/teams" ]]; then
    echo "Erro: rode este script na raiz do repositório docs-hub."
    exit 1
fi

# --- 1. Dados da organização ---

echo "Vamos configurar o docs-hub para a sua organização."
echo ""

read -rp "Nome da organização (ex: Acme Corp): " ORG_NAME
: "${ORG_NAME:?Nome da organização não pode ser vazio}"

read -rp "URL base do site (ex: https://docs.acmecorp.com) [Enter para http://localhost:1313]: " BASE_URL
BASE_URL="${BASE_URL:-http://localhost:1313}"

read -rp "Título do site [DocHub]: " SITE_TITLE
SITE_TITLE="${SITE_TITLE:-DocHub}"

read -rp "URL do repositório no GitHub (ex: https://github.com/acme/docs-hub) [Enter para pular]: " GITHUB_URL

# --- 2. Atualiza hugo.toml ---

echo ""
echo "→ Atualizando hugo.toml..."

# Usa sed para substituir os campos inline
sed -i '' \
    "s|^baseURL = .*|baseURL = \"${BASE_URL}\"|" \
    "s|^title = .*|title = \"${SITE_TITLE}\"|" \
    hugo.toml

# Atualiza params.org e params.description
sed -i '' \
    "s|org.*=.*\".*\"|org         = \"${ORG_NAME}\"|" \
    "s|description.*=.*\"Documentação centralizada.*\"|description = \"Documentação centralizada de todos os times de ${ORG_NAME}\"|" \
    hugo.toml

if [[ -n "$GITHUB_URL" ]]; then
    sed -i '' "s|github.*=.*\".*\"|github      = \"${GITHUB_URL}\"|" hugo.toml
fi

# --- 3. Remove conteúdo de exemplo ---

echo "→ Removendo conteúdo de exemplo..."

if [[ -d "content/teams/sample" ]]; then
    rm -rf "content/teams/sample"
    echo "  ✓ content/teams/sample removido"
fi

# Remove outras pastas de exemplo se existirem
for demo_team in go-learning team-payments team-checkout team-platform; do
    if [[ -d "content/teams/$demo_team" ]]; then
        rm -rf "content/teams/$demo_team"
        echo "  ✓ content/teams/$demo_team removido"
    fi
done

# --- 4. Reseta data/teams.yaml ---

echo "→ Resetando data/teams.yaml..."

cat > data/teams.yaml <<'EOF'
teams: []
EOF

echo "  ✓ data/teams.yaml limpo"

# --- 5. Registrar primeiro time ---

echo ""
echo "────────────────────────────────────────"
echo "Configuração base concluída."
echo ""
read -rp "Deseja cadastrar o primeiro time agora? (sim/não) [não]: " add_team
if [[ "$add_team" == "sim" || "$add_team" == "s" ]]; then
    bash scripts/register-team.sh
fi

# --- Resumo final ---

echo ""
echo "╔══════════════════════════════════════╗"
echo "║         DocHub pronto para uso!      ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  Organização : ${ORG_NAME}"
echo "  URL base    : ${BASE_URL}"
echo "  Título      : ${SITE_TITLE}"
echo ""
echo "Próximos passos:"
echo ""
echo "  1. Cadastre os times:"
echo "     bash scripts/register-team.sh"
echo ""
echo "  2. Instale as skills nos repos dos times:"
echo "     bash scripts/install-skill.sh   (rodar de dentro do repo-alvo)"
echo ""
echo "  3. Suba para o GitHub e configure o deploy:"
echo "     git add . && git commit -m 'chore: initial setup'"
echo "     git push"
echo ""
echo "  4. Rode localmente:"
echo "     hugo server"
echo ""
