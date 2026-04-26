#!/bin/bash
# Cadastra um novo time em data/teams.yaml
# Uso: bash register-team.sh --id team-xyz --name "XYZ" [--slack "#xyz"] [--repos repo1,repo2] [--pr]

set -e

# Helper function to get translations
translate() {
    local key="$1"
    shift
    local lang="${LANGUAGE_CODE:-pt-br}"
    local translation=$(python3 "$(dirname "$0")/get-translation.py" --key "$key" --lang "$lang")
    printf "$translation\n" "$@"
}

# Helper function to initialize teams.yaml with correct YAML structure
init_teams_file() {
    local teams_file="data/teams.yaml"

    # Create file if it doesn't exist
    if [[ ! -f "$teams_file" ]]; then
        cat > "$teams_file" <<EOF
teams:
EOF
        return
    fi

    # Check if file has invalid structure (empty list or malformed)
    if grep -q "^teams: \[\]" "$teams_file" || [[ ! -s "$teams_file" ]]; then
        cat > "$teams_file" <<EOF
teams:
EOF
        return
    fi

    # Check if file starts with 'teams:' key
    if ! grep -q "^teams:" "$teams_file"; then
        # File doesn't have the correct structure, initialize it
        cat > "$teams_file" <<EOF
teams:
EOF
    fi
}

TEAM_ID=""
TEAM_NAME=""
TEAM_SLACK=""
TEAM_REPOS=""
TEAM_DOC_TYPES="technical,product,faq,examples"
OPEN_PR=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --id)         TEAM_ID="$2";        shift 2 ;;
        --name)       TEAM_NAME="$2";      shift 2 ;;
        --slack)      TEAM_SLACK="$2";     shift 2 ;;
        --repos)      TEAM_REPOS="$2";     shift 2 ;;
        --doc-types)  TEAM_DOC_TYPES="$2"; shift 2 ;;
        --pr)         OPEN_PR=true;        shift ;;
        *) translate "register.error_unknown_option" "$1"; exit 1 ;;
    esac
done

# Valida disponibilidade de ferramentas para --pr
if [[ "$OPEN_PR" == true ]]; then
    if ! command -v git &> /dev/null; then
        echo "❌ $(translate "register.error_git_required")"
        exit 1
    fi
    if ! command -v gh &> /dev/null; then
        echo "❌ $(translate "register.error_gh_required")"
        echo ""
        echo "$(translate "register.error_gh_install")"
        echo "  bash register-team.sh --id $TEAM_ID --name '$TEAM_NAME' # sem --pr"
        echo "  $(translate "register.error_gh_manual")"
        exit 1
    fi
fi

# Validação básica
: "${TEAM_ID:?$(translate "register.error_missing_id")}"
: "${TEAM_NAME:?$(translate "register.error_missing_name")}"

# Initialize teams.yaml if needed
if [[ ! -f "data/teams.yaml" ]]; then
    if [[ ! -d "data" ]]; then
        echo "$(translate "register.error_not_in_docs_hub")"
        exit 1
    fi
    init_teams_file
else
    init_teams_file
fi

TEAM_ID="${TEAM_ID// /}"

if grep -q "^  - id: ${TEAM_ID}$" "data/teams.yaml" 2>/dev/null; then
    translate "register.error_team_exists" "${TEAM_ID}"
    exit 1
fi

# Formata doc_types como lista YAML
DOC_TYPES_YAML="["
IFS=',' read -ra DT_LIST <<< "$TEAM_DOC_TYPES"
for dt in "${DT_LIST[@]}"; do
    DOC_TYPES_YAML="${DOC_TYPES_YAML}${dt// /}, "
done
DOC_TYPES_YAML="${DOC_TYPES_YAML%, }]"

# Escreve em data/teams.yaml
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
} >> "data/teams.yaml"

# Cria estrutura de conteúdo em múltiplos idiomas
TODAY=$(date +%Y-%m-%d)

# Obter idiomas suportados
SUPPORTED_LANGS="${SUPPORTED_LANGUAGES:-${LANGUAGE_CODE:-pt-br}}"

IFS=',' read -ra LANGS <<< "$SUPPORTED_LANGS"
for lang in "${LANGS[@]}"; do
    lang="${lang// /}"

    # Criar diretório base do time para este idioma
    mkdir -p "content/${lang}/teams/${TEAM_ID}"

    # Criar _index.md
    DOC_DESC=$(python3 "$(dirname "$0")/get-translation.py" --key "register.doc_description" --lang "$lang")
    # Safely format the description string
    DOC_DESC=${DOC_DESC//"%s"/${TEAM_NAME}}

    cat > "content/${lang}/teams/${TEAM_ID}/_index.md" <<TEAM_EOF
---
title: "${TEAM_NAME}"
description: "${DOC_DESC}"
language: "${lang}"
---
TEAM_EOF

    # Cria seções por doc_type
    IFS=',' read -ra DT_LIST <<< "$TEAM_DOC_TYPES"
    for dt in "${DT_LIST[@]}"; do
        dt="${dt// /}"
        mkdir -p "content/${lang}/teams/${TEAM_ID}/$dt"

        # Traduzir o título do doc_type
        dt_title=$(python3 "$(dirname "$0")/get-translation.py" --key "doc.${dt}" --lang "$lang")

        # Preparar conteúdo do arquivo _index.md
        if [[ "$dt" == "examples" ]]; then
            section_description=$(python3 "$(dirname "$0")/get-translation.py" --key "register.examples_description" --lang "$lang")
            cat > "content/${lang}/teams/${TEAM_ID}/$dt/_index.md" <<DOC_TYPE_EOF
---
title: "${dt_title}"
team: "${TEAM_ID}"
language: "${lang}"
description: "${section_description}"
---
DOC_TYPE_EOF
        else
            cat > "content/${lang}/teams/${TEAM_ID}/$dt/_index.md" <<DOC_TYPE_EOF
---
title: "${dt_title}"
team: "${TEAM_ID}"
language: "${lang}"
---
DOC_TYPE_EOF
        fi
    done
done

translate "register.success" "${TEAM_ID}"
echo "  $(translate "register.success_file")"
translate "register.success_folder" "${TEAM_ID}"
echo "  $(translate "register.success_note")"

# Abre PR se solicitado e git está disponível
if [[ "$OPEN_PR" == true ]]; then
    BRANCH="register-team/${TEAM_ID}"

    git fetch origin --quiet
    git checkout main --quiet
    git reset --hard origin/main --quiet
    git branch -D "$BRANCH" 2>/dev/null || true
    git checkout -b "$BRANCH"

    git config user.name "DocHub Bot"
    git config user.email "dochub-bot@noreply.github.com"

    # Adicionar arquivos de configuração
    git add data/teams.yaml

    # Adicionar conteúdo em todos os idiomas
    SUPPORTED_LANGS="${SUPPORTED_LANGUAGES:-${LANGUAGE_CODE:-pt-br}}"
    IFS=',' read -ra LANGS <<< "$SUPPORTED_LANGS"
    for lang in "${LANGS[@]}"; do
        lang="${lang// /}"
        git add "content/${lang}/teams/${TEAM_ID}" 2>/dev/null || true
    done

    COMMIT_MSG=$(python3 "$(dirname "$0")/get-translation.py" --key "register.pr_title" --lang "${LANGUAGE_CODE:-pt-br}" | xargs printf)
    COMMIT_MSG=$(printf "$COMMIT_MSG" "${TEAM_ID}")
    git commit -m "$COMMIT_MSG"

    if command -v gh &> /dev/null; then
        PR_BODY_TEMPLATE=$(python3 "$(dirname "$0")/get-translation.py" --key "register.pr_body" --lang "${LANGUAGE_CODE:-pt-br}")
        PR_BODY=$(printf "$PR_BODY_TEMPLATE" "${TEAM_ID}" "${TEAM_NAME}" "${TEAM_SLACK:----}" "${TEAM_REPOS:----}" "${TEAM_DOC_TYPES}")
        PR_URL=$(gh pr create \
            --head "$BRANCH" \
            --base main \
            --title "$COMMIT_MSG" \
            --body "$PR_BODY")

        translate "register.success_pr" "${PR_URL}"
    else
        translate "register.success_commit" "${BRANCH}"
        echo "  $(translate "register.pr_help")"
    fi
else
    echo ""
    echo "$(translate "register.pr_help")"
fi
