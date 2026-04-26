#!/usr/bin/env python3
"""
Manage internationalization configuration for Hugo.
Reads LANGUAGE_CODE and SUPPORTED_LANGUAGES from environment and updates hugo.toml.
"""

import os
import sys
import re
from pathlib import Path
from typing import List, Dict

LANGUAGE_NAMES = {
    "pt-br": "Português (Brasil)",
    "pt": "Português",
    "pt-pt": "Português (Portugal)",
    "en": "English",
    "en-us": "English (US)",
    "en-gb": "English (GB)",
    "es": "Español",
    "es-es": "Español (España)",
    "es-mx": "Español (México)",
    "fr": "Français",
    "de": "Deutsch",
    "it": "Italiano",
    "ja": "日本語",
    "zh": "简体中文",
    "zh-cn": "简体中文",
}


def get_language_name(lang_code: str) -> str:
    """Get friendly name for a language code."""
    normalized = lang_code.lower()
    if normalized in LANGUAGE_NAMES:
        return LANGUAGE_NAMES[normalized]
    return normalized.upper()


def parse_languages(languages_str: str) -> List[str]:
    """Parse comma-separated language codes."""
    return [lang.strip() for lang in languages_str.split(",") if lang.strip()]


def read_hugo_config(config_path: Path) -> str:
    """Read hugo.toml content."""
    return config_path.read_text(encoding="utf-8")


def write_hugo_config(config_path: Path, content: str) -> None:
    """Write hugo.toml content."""
    config_path.write_text(content, encoding="utf-8")


def remove_language_section(content: str, lang_code: str) -> str:
    """Remove a language section from hugo.toml."""
    pattern = rf'\[languages\."{lang_code}".*?\].*?(?=\n\[|$)'
    return re.sub(pattern, "", content, flags=re.DOTALL).rstrip() + "\n"


def extract_language_sections(content: str) -> Dict[str, str]:
    """Extract all language sections from hugo.toml."""
    languages = {}
    pattern = r'\[languages\.(["\']?)(\w+(?:-\w+)?)\1\](.*?)(?=\n\[|$)'

    for match in re.finditer(pattern, content, re.DOTALL):
        lang_code = match.group(2)
        lang_section = match.group(0)
        languages[lang_code] = lang_section

    return languages


def generate_language_config(lang_code: str, weight: int) -> str:
    """Generate language configuration block for hugo.toml."""
    lang_name = get_language_name(lang_code)

    return f'''
[languages."{lang_code}"]
  languageName = "{lang_name}"
  weight = {weight}
  contentDir = "content/{lang_code}"
'''


def update_hugo_config(primary_lang: str, supported_langs: List[str]) -> str:
    """Update language configuration in hugo.toml content."""
    config_path = Path("hugo.toml")

    if not config_path.exists():
        print("Error: hugo.toml not found in current directory")
        sys.exit(1)

    content = read_hugo_config(config_path)

    # Remove old language sections
    existing_langs = extract_language_sections(content)
    for lang_code in existing_langs:
        content = remove_language_section(content, lang_code)

    # Remove old language config from [params]
    content = re.sub(
        r'(\[params\].*?)supportedLanguages.*?\n',
        r'\1',
        content,
        flags=re.DOTALL
    )
    content = re.sub(
        r'(\[params\].*?)defaultLanguage.*?\n',
        r'\1',
        content,
        flags=re.DOTALL
    )

    # Update defaultContentLanguage
    if f'defaultContentLanguage = "{primary_lang}"' not in content:
        content = content.replace(
            'enableGitInfo = true',
            f'enableGitInfo = true\n\ndefaultContentLanguage = "{primary_lang}"\ndefaultContentLanguageInSubdir = false'
        )
    else:
        content = re.sub(
            r'defaultContentLanguage = "[^"]*"',
            f'defaultContentLanguage = "{primary_lang}"',
            content
        )

    # Add new language sections before [outputs]
    new_languages = "\n".join([
        generate_language_config(lang, i + 1)
        for i, lang in enumerate(supported_langs)
    ])

    # Insert before [outputs] if it exists, otherwise at end
    if "[outputs]" in content:
        content = content.replace("[outputs]", new_languages + "\n[outputs]")
    else:
        content = content.rstrip() + "\n" + new_languages

    write_hugo_config(config_path, content)
    return content


def verify_language_files(supported_langs: List[str]) -> None:
    """Verify that language files exist in i18n directory."""
    i18n_dir = Path("i18n")

    if not i18n_dir.exists():
        print("Warning: i18n directory does not exist")
        return

    missing_languages = []
    for lang in supported_langs:
        lang_file = i18n_dir / f"{lang}.yaml"
        if not lang_file.exists():
            missing_languages.append(lang)

    if missing_languages:
        print(f"Warning: Missing i18n files for: {', '.join(missing_languages)}")
        print("  Create these files in the i18n/ directory or they will use defaults")


def main():
    # Get configuration from environment
    primary_lang = os.environ.get("LANGUAGE_CODE", "pt-br").lower()
    supported_langs_str = os.environ.get("SUPPORTED_LANGUAGES", primary_lang).lower()
    supported_langs = parse_languages(supported_langs_str)

    # Ensure primary language is in supported languages
    if primary_lang not in supported_langs:
        supported_langs.insert(0, primary_lang)

    print("Configuring i18n for Hugo...")
    print(f"  Primary language: {primary_lang} ({get_language_name(primary_lang)})")
    print(f"  Supported languages: {', '.join(supported_langs)}")

    # Update hugo.toml
    try:
        update_hugo_config(primary_lang, supported_langs)
        print("✓ hugo.toml updated successfully")
    except Exception as e:
        print(f"✗ Error updating hugo.toml: {e}")
        sys.exit(1)

    # Verify language files
    verify_language_files(supported_langs)

    print("\nNext steps:")
    print(f"  1. Create content directories for each language:")
    for lang in supported_langs:
        print(f"     mkdir -p content/{lang}")
    print("  2. Copy your content to each language directory")
    print("  3. Or use: hugo server --buildDrafts")


if __name__ == "__main__":
    main()
