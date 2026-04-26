# /doc-feature

Generates complete feature documentation — technical, product, and FAQ — from one or more PRs, a branch, or a time period.

Supports automatic generation in all languages configured via `SUPPORTED_LANGUAGES`.

## Usage

```
/doc-feature <feature-name>
```

**Examples:**
```
/doc-feature pix-support
/doc-feature sso-auth
/doc-feature pix-support --languages pt-br,en-us
/doc-feature sso-auth --team team-auth --prs 150,151
```

**Optional parameters:**
- `--prs <n1,n2,n3>` — specific PR numbers
- `--branch <name>` — or use a branch instead of PRs
- `--team <id>` — team (auto-detected if not provided)
- `--languages <lang1,lang2>` — specific languages (default: all from SUPPORTED_LANGUAGES)

---

## What to do when receiving this command

### 1. Detect i18n configuration

Read environment variables or load from `.env`:

```python
from scripts.i18n_utils import load_i18n

i18n = load_i18n()
primary_lang = i18n.get_primary_language()      # "pt-br"
supported_langs = i18n.get_supported_languages() # ["pt-br", "en-us"]
```

If `--languages` was passed, use only those. Otherwise, use `SUPPORTED_LANGUAGES`.

### 2. Ask once only

If `--prs` or `--branch` not provided: **ask once only**:
- "Which PRs? (ex: 138,141,145) Or leave blank to use current branch."

### 3. Collect context

**If PRs were provided:**
```bash
for pr in $PRS; do
  gh pr view $pr --json number,title,body,files,additions,deletions
  gh pr diff $pr | head -200
done
```

**If branch was provided:**
```bash
git log main..{branch} --oneline
git diff main...{branch} --stat
git diff main...{branch} | head -400
```

**Always read test files too** — they reveal expected behavior:
```bash
find . -path ./node_modules -prune -o -name "*.test.*" -newer README.md -print | head -20
```

### 4. Generate files in multiple languages

Always generates **technical** and **product**. Generates **faq** if it's in the team's `doc_types` in `data/teams.yaml`.

**For each supported language:**

```
content/{lang}/teams/{team}/technical/feature-{slug}.md
content/{lang}/teams/{team}/product/feature-{slug}.md
content/{lang}/teams/{team}/faq/faq-{slug}.md        ← if faq is active
```

**Example:** Feature "pix-support" in 2 languages:
```
content/pt-br/teams/team-payments/technical/feature-pix-support.md
content/pt-br/teams/team-payments/product/feature-pix-support.md
content/pt-br/teams/team-payments/faq/faq-pix-support.md

content/en-us/teams/team-payments/technical/feature-pix-support.md
content/en-us/teams/team-payments/product/feature-pix-support.md
content/en-us/teams/team-payments/faq/faq-pix-support.md
```

**IMPORTANT:** Each document type is generated in ALL specified languages.

---

## Templates

### technical — Portuguese (pt-br)

```markdown
---
title: "Feature: {nome da feature}"
date: {data ISO 8601 atual}
team: "{team}"
project: "{project}"
doc_type: "technical"
scope: "feature"
language: "pt-br"
tags: []
draft: false
---

## O que é

[Descrição técnica em 3-5 linhas. O que faz e qual problema resolve do ponto de vista de engenharia.]

## Arquitetura e decisões de design

[Como foi implementada. Padrões usados. Alternativas descartadas e por quê.]

## Componentes e responsabilidades

[Mapa dos módulos/serviços envolvidos e o que cada um faz nesta feature.]

## Fluxo principal

\`\`\`
[diagrama ASCII ou passo a passo do fluxo de dados/execução]
\`\`\`

## APIs e contratos

[Endpoints novos ou alterados, payloads, erros esperados. Só se aplicável.]

## Configuração necessária

[Variáveis de ambiente, flags, dependências que precisam estar ativas.]

## Como testar end-to-end

[Roteiro completo de teste da feature.]
```

### technical — English (en-us)

```markdown
---
title: "Feature: {feature name}"
date: {current ISO 8601 date}
team: "{team}"
project: "{project}"
doc_type: "technical"
scope: "feature"
language: "en-us"
tags: []
draft: false
---

## What is it

[Technical description in 3-5 lines. What it does and what problem it solves from an engineering perspective.]

## Architecture and design decisions

[How it was implemented. Patterns used. Alternatives considered and why they were discarded.]

## Components and responsibilities

[Map of modules/services involved and what each one does in this feature.]

## Main flow

\`\`\`
[ASCII diagram or step-by-step explanation of data/execution flow]
\`\`\`

## APIs and contracts

[New or altered endpoints, payloads, expected errors. Only if applicable.]

## Required configuration

[Environment variables, flags, dependencies that need to be active.]

## How to test end-to-end

[Complete feature test roadmap.]
```

### product — Similar structure, translated for each language

### faq — Similar structure, translated for each language

---

## Dependencies

- **Git** — to offer PR option (optional)
- **GitHub CLI (gh)** — to open PR automatically (required if using --pr)
- **i18n_utils.py** — to load language configuration

If `gh` is not installed but the user chooses PR, show:
```
❌ Error: --pr requires GitHub CLI (gh) to be installed
Install at https://cli.github.com
```

---

## Completion

Show for each language:
```
✓ Feature documentation created in Portuguese (pt-br):
  - content/pt-br/teams/{team}/technical/feature-{slug}.md
  - content/pt-br/teams/{team}/product/feature-{slug}.md

✓ Feature documentation created in English (en-us):
  - content/en-us/teams/{team}/technical/feature-{slug}.md
  - content/en-us/teams/{team}/product/feature-{slug}.md
```

If only one language: show only that one.
