#!/bin/bash
# Configure i18n for Hugo based on environment variables
# This script generates language configuration in hugo.toml dynamically

set -e

# Parse environment variables
LANGUAGE_CODE="${LANGUAGE_CODE:-pt-br}"
SUPPORTED_LANGUAGES="${SUPPORTED_LANGUAGES:-pt-br}"

# Create a temporary TOML config for languages
generate_languages_config() {
    local primary_lang="$1"
    local supported_langs="$2"

    # Start with the primary language
    cat <<EOF

[languages."${primary_lang}"]
  languageName = "$(get_language_name "${primary_lang}")"
  weight = 1
  contentDir = "content/${primary_lang}"

EOF

    # Add supported languages (excluding the primary)
    local weight=2
    IFS=',' read -ra langs <<< "$supported_langs"
    for lang in "${langs[@]}"; do
        lang=$(echo "$lang" | xargs) # trim whitespace
        if [[ "$lang" != "$primary_lang" ]]; then
            cat <<EOF
[languages."${lang}"]
  languageName = "$(get_language_name "${lang}")"
  weight = $weight
  contentDir = "content/${lang}"

EOF
            ((weight++))
        fi
    done
}

# Map language code to friendly name
get_language_name() {
    case "$1" in
        pt-br|pt-BR) echo "Português (Brasil)" ;;
        pt|pt-pt|pt-PT) echo "Português (Portugal)" ;;
        en-us|en-US|en) echo "English" ;;
        es-es|es-ES|es) echo "Español" ;;
        fr|fr-fr|fr-FR) echo "Français" ;;
        de|de-de|de-DE) echo "Deutsch" ;;
        it|it-it|it-IT) echo "Italiano" ;;
        ja|ja-jp|ja-JP) echo "日本語" ;;
        zh|zh-cn|zh-CN) echo "简体中文" ;;
        *) echo "$(echo "$1" | tr '[:lower:]' '[:upper:]')" ;;
    esac
}

# Generate the language configuration
generate_languages_config "$LANGUAGE_CODE" "$SUPPORTED_LANGUAGES"
