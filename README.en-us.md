# DocHub

Centralized documentation for all teams — technical, product, and FAQ.

## Stack

- **Hugo** — static site generation
- **Dochub Theme** — custom theme with full-text search
- **GitHub Actions** — automated build and deploy
- **Netlify** — hosting

## Dependencies

### 🔴 Required

To use any functionality in DocHub, you need:

| Tool | Version | Installation |
|-----------|--------|-----------|
| **Hugo** | extended v0.120+ | [hugo.io](https://gohugo.io/installation/) |
| **Python** | 3.8+ | [python.org](https://www.python.org/downloads/) |
| **PyYAML** | - | `pip install pyyaml` |

### 🟡 Required for Claude Skills

To use `/doc-pr`, `/doc-feature`, `/doc-module`:

| Tool | Version | Installation | Purpose |
|-----------|--------|-----------|---------|
| **ANTHROPIC_API_KEY** | - | [console.anthropic.com](https://console.anthropic.com/keys) | Call Claude API |

### 🟢 Optional (but recommended)

| Tool | Version | Installation | Purpose |
|-----------|--------|-----------|---------|
| **Git** | 2.0+ | [git-scm.com](https://git-scm.com/downloads) | Version control; required for `--pr` |
| **GitHub CLI (gh)** | 2.0+ | [cli.github.com](https://cli.github.com/) | Open PRs automatically with `--pr` |

**Dependency Summary:**
- Without Git/gh: Everything works except automatic PR opening (commit/push manually)
- Without ANTHROPIC_API_KEY: Claude skills and `generate-docs.py` won't work

---

## Initial Setup

```bash
# 1. Install required dependencies
pip install pyyaml
# And have Hugo extended installed

# 2. Copy .env.example to .env and update values
cp .env.example .env
# Edit .env with your organization's data

# 3. (Optional) Configure languages — see Internationalization section
#    LANGUAGE_CODE="pt-br"
#    SUPPORTED_LANGUAGES="pt-br,en-us"

# 4. Run setup
bash scripts/setup.sh

# 5. Done! Run locally
hugo server --buildDrafts
# Access: http://localhost:1313
```

## Internationalization (i18n) 🌍

DocHub natively supports multiple languages. Configure via environment variables in `.env`:

### Quick Configuration

```bash
# 1. Edit .env
LANGUAGE_CODE="pt-br"              # Main language
SUPPORTED_LANGUAGES="pt-br,en-us"  # All supported languages

# 2. Run setup (auto-configures Hugo)
bash scripts/setup.sh

# 3. Done! Hugo generates URLs for each language
# http://localhost:1313/         ← Portuguese (main language)
# http://localhost:1313/en-us/   ← English
```

### Default Supported Languages

| Code | Language |
|--------|--------|
| `pt-br` | Português (Brasil) |
| `pt-pt` | Português (Portugal) |
| `en-us` | English (US) |
| `en-gb` | English (GB) |
| `es-es` | Español (España) |
| `es-mx` | Español (México) |
| `fr` | Français |
| `de` | Deutsch |
| `it` | Italiano |
| `ja-jp` | 日本語 |
| `zh-cn` | 简体中文 |

### Content Structure with i18n

```
content/
├── pt-br/
│   └── teams/{team-id}/*
├── en-us/
│   └── teams/{team-id}/*
└── es-es/
    └── teams/{team-id}/*

i18n/
├── pt-br.yaml    ← Translations
├── en-us.yaml    ← Translations
└── es-es.yaml    ← Translations
```

### Claude Commands with i18n

The commands `/doc-pr`, `/doc-feature`, and `/doc-module` automatically generate in **all languages**:

```bash
# Generates in pt-br and en-us (if configured)
/doc-pr 142

# Or specify languages
/doc-pr 142 --languages pt-br,en-us
/doc-feature pix-support --languages pt-br
/doc-module src/payments --languages en-us
```

Result:
```
content/pt-br/teams/team-payments/technical/pr-142-*.md
content/en-us/teams/team-payments/technical/pr-142-*.md
```

### Add a New Language

1. **Create translation file:**
   ```bash
   cp i18n/pt-br.yaml i18n/es-es.yaml
   # Edit and translate strings
   ```

2. **Update `.env`:**
   ```bash
   SUPPORTED_LANGUAGES="pt-br,en-us,es-es"
   ```

3. **Run configuration:**
   ```bash
   python3 scripts/manage-i18n.py
   ```

### Full Documentation

For advanced configuration, template translation, and more:
👉 **[I18N.md](./I18N.md)** — Detailed internationalization guide

---

## Add a New Team

```bash
# Basic — only creates data and local content
bash scripts/register-team.sh --id team-xyz --name "Team XYZ" [--slack "#team-xyz"]

# With automatic PR (requires Git)
bash scripts/register-team.sh --id team-xyz --name "Team XYZ" --pr
# If Git is not available, the flag will be ignored with a warning
```

**Parameters:**
- `--id` *(required)* — unique identifier (ex: `team-payments`)
- `--name` *(required)* — display name (ex: `Payments`)
- `--slack` *(optional)* — Slack channel (ex: `#team-payments`)
- `--repos` *(optional)* — associated repositories, comma-separated
- `--doc-types` *(optional)* — doc types (default: `technical,product,faq`)
- `--pr` *(optional)* — opens PR automatically (requires Git and GitHub CLI)

## Generate Documentation with Claude

### ✨ Simplified Mode (recommended) — Skills

Use the integrated skills in Claude Code:

```bash
/doc-pr 142              # PR documentation
/doc-feature pix-support # Feature documentation
/doc-module src/payments # Module documentation
```

The skills:
- ✅ Auto-detect project/team
- ✅ Only ask when necessary
- ✅ Generate technical, product, and FAQ documentation
- ✅ **Generate in ALL supported languages** (i18n)
- ✅ Offer to open PR automatically

**Examples with i18n:**
```bash
# Generates in pt-br and en-us (if SUPPORTED_LANGUAGES="pt-br,en-us")
/doc-pr 142

# Specify languages (default: all from SUPPORTED_LANGUAGES)
/doc-pr 142 --languages pt-br,en-us
/doc-feature pix-support --languages pt-br
/doc-module src/payments --languages en-us
```

### Advanced Mode (Direct Python)

For programmatic use or CI/CD:

```bash
export LANGUAGE_CODE="pt-br"
export SUPPORTED_LANGUAGES="pt-br,en-us"

python scripts/generate-docs.py \
  --context context.json \
  --doc-types "technical,product,faq" \
  --project "api-payments" \
  --team "team-payments" \
  --output "content" \
  --pr
```

Automatically generates in `content/{lang}/teams/team-payments/...` for each language.

**Context JSON:**
```json
{
  "pr_number": "123",
  "pr_title": "Title",
  "pr_body": "Description",
  "changed_files": ["src/file.ts"],
  "diff_summary": "Summary",
  "readme": "README (optional)",
  "tags": []
}
```

**Parameters:**
- `--context` — JSON file
- `--doc-types` — types (ex: `technical,product,faq`)
- `--project` — project name
- `--team` — team ID
- `--output` — output directory (generates content/{lang}/...)
- `--pr` *(optional)* — opens PR (requires Git and GitHub CLI)

**Environment variables:**
- `LANGUAGE_CODE` — main language (default: `pt-br`)
- `SUPPORTED_LANGUAGES` — supported languages (default: `pt-br`)
- `ANTHROPIC_API_KEY` — Claude API key (required)

**Requires:** `ANTHROPIC_API_KEY`

## Content Structure

With i18n enabled:

```
content/
├── pt-br/
│   └── teams/{team-id}/
│       ├── _index.md
│       ├── technical/   ← technical docs (by PR or module)
│       ├── product/     ← product docs (by feature)
│       └── faq/         ← frequently asked questions
├── en-us/
│   └── teams/{team-id}/
│       ├── _index.md
│       ├── technical/
│       ├── product/
│       └── faq/
└── es-es/
    └── teams/{team-id}/
        └── ...
```

## Required Frontmatter

```yaml
---
title: ""
date: 2025-01-01T00:00:00-03:00
team: "team-id"
project: "project-name"
doc_type: "technical | product | faq"
scope: "pr | feature | module"
language: "pt-br"  # Language field (added automatically)
draft: false
---
```

**Note:** The `language` field is added automatically by Claude commands.

## Tool Installation

### Install Python and Dependencies

```bash
# Check if Python 3.8+ is installed
python3 --version

# Install PyYAML (required)
pip install pyyaml
```

### Install Hugo Extended

**macOS (Homebrew):**
```bash
brew install hugo
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install hugo
```

**Windows:**
```bash
choco install hugo-extended
# Or: scoop install hugo-extended
```

[More options →](https://gohugo.io/installation/)

### Install GitHub CLI (optional, recommended)

Required only if using `--pr` to automatically open PRs.

```bash
# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Windows
choco install gh
```

[More options →](https://cli.github.com/)

### Configure ANTHROPIC_API_KEY

Required to use `/doc-pr`, `/doc-feature`, `/doc-module` skills:

```bash
# 1. Create an API key at https://console.anthropic.com/keys
# 2. Configure in your environment:
export ANTHROPIC_API_KEY="sk-ant-..."

# Or add to .env (if using dotenv):
echo "ANTHROPIC_API_KEY=sk-ant-..." >> .env
```

### Automatic Protections

DocHub automatically detects available tools:

- ✅ **No Git**: Version control features not offered
- ✅ **Git without gh**: Clear message with installation instructions
- ✅ **Both**: PRs open automatically with `--pr`
- ✅ **No ANTHROPIC_API_KEY**: Claude skills disabled with clear warning

### i18n Scripts

Available in `scripts/`:
- **`manage-i18n.py`** — Updates language configuration in Hugo
- **`i18n_utils.py`** — Python module for managing i18n in scripts
- **`configure-i18n.sh`** — Generates TOML configuration blocks

## Deploy

Push to `main` triggers automatic build and deploy via GitHub Actions + Netlify.

## Required Secrets

| Secret | Description |
|--------|-----------|
| `NETLIFY_AUTH_TOKEN` | Netlify authentication token |
| `NETLIFY_SITE_ID` | Netlify site ID |
