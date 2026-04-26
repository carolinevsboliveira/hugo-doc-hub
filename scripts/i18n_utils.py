#!/usr/bin/env python3
"""
Internationalization utilities for DocHub.
Helps with loading translations and managing language-specific content.
"""

import os
from pathlib import Path
from typing import Dict, Optional
import yaml


class I18n:
    """Handle internationalization for DocHub."""

    def __init__(self):
        self.primary_language = os.environ.get("LANGUAGE_CODE", "pt-br").lower()
        self.supported_languages = [
            lang.strip()
            for lang in os.environ.get("SUPPORTED_LANGUAGES", self.primary_language).split(",")
        ]
        self.translations: Dict[str, Dict[str, str]] = {}
        self._load_translations()

    def _load_translations(self) -> None:
        """Load translations from i18n directory."""
        i18n_dir = Path("i18n")

        if not i18n_dir.exists():
            return

        for lang in self.supported_languages:
            lang_file = i18n_dir / f"{lang}.yaml"
            if lang_file.exists():
                try:
                    with open(lang_file, "r", encoding="utf-8") as f:
                        self.translations[lang] = yaml.safe_load(f) or {}
                except Exception as e:
                    print(f"Warning: Could not load translations for {lang}: {e}")
                    self.translations[lang] = {}
            else:
                self.translations[lang] = {}

    def translate(self, key: str, language: Optional[str] = None, default: Optional[str] = None) -> str:
        """
        Get a translation for a key in a specific language.
        Falls back to primary language, then default value.
        """
        lang = (language or self.primary_language).lower()

        # Try the requested language
        if lang in self.translations and key in self.translations[lang]:
            return self.translations[lang][key]

        # Fall back to primary language
        if lang != self.primary_language:
            if (
                self.primary_language in self.translations
                and key in self.translations[self.primary_language]
            ):
                return self.translations[self.primary_language][key]

        # Return default or the key itself
        return default or key

    def get_supported_languages(self) -> list:
        """Get list of supported languages."""
        return self.supported_languages

    def get_primary_language(self) -> str:
        """Get primary language code."""
        return self.primary_language

    def get_content_path(self, language: Optional[str] = None) -> Path:
        """Get content directory path for a language."""
        lang = language or self.primary_language
        return Path("content") / lang

    def create_language_frontmatter(
        self, base_frontmatter: str, language: str, **kwargs
    ) -> str:
        """Add language information to frontmatter."""
        lines = base_frontmatter.strip().split("\n")

        # Find closing --- if it exists
        if lines[-1] == "---":
            lines.pop()

        # Add language field
        lines.append(f'language: "{language}"')

        # Add any additional fields
        for key, value in kwargs.items():
            if isinstance(value, str):
                lines.append(f'{key}: "{value}"')
            elif isinstance(value, list):
                lines.append(f"{key}: {value}")
            else:
                lines.append(f"{key}: {value}")

        return "---\n" + "\n".join(lines) + "\n---\n"


def load_i18n() -> I18n:
    """Factory function to load i18n configuration."""
    return I18n()
