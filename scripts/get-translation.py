#!/usr/bin/env python3
"""
Helper script to get translations from i18n files.
Usage: python3 scripts/get-translation.py --key "nav.home" [--lang "pt-br"] [--default "Home"]
"""

import sys
import os
from pathlib import Path
import yaml
import argparse


def load_translations(language: str) -> dict:
    """Load translations for a specific language."""
    i18n_dir = Path("i18n")
    lang_file = i18n_dir / f"{language}.yaml"

    if not lang_file.exists():
        return {}

    try:
        with open(lang_file, "r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    except Exception:
        return {}


def get_translation(key: str, language: str = None, default: str = None) -> str:
    """Get a translation for a key in a specific language."""
    # Determine language
    if language is None:
        language = os.environ.get("LANGUAGE_CODE", "pt-br").lower()

    lang = language.lower()

    # Load translations
    translations = load_translations(lang)

    # Try the requested language
    if key in translations:
        return translations[key]

    # Try primary language if different
    primary_lang = os.environ.get("LANGUAGE_CODE", "pt-br").lower()
    if lang != primary_lang:
        primary_translations = load_translations(primary_lang)
        if key in primary_translations:
            return primary_translations[key]

    # Return default or the key itself
    return default or key


def main():
    parser = argparse.ArgumentParser(description="Get translation from i18n files")
    parser.add_argument("--key", required=True, help="Translation key")
    parser.add_argument("--lang", help="Language code (default: LANGUAGE_CODE env var)")
    parser.add_argument("--default", help="Default value if translation not found")

    args = parser.parse_args()

    translation = get_translation(args.key, args.lang, args.default)
    print(translation)


if __name__ == "__main__":
    main()
