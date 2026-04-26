# /doc-module

Documents a module or entire project folder. Ideal for onboarding, post-refactor, and legacy code audit.

Supports automatic generation in all languages configured via `SUPPORTED_LANGUAGES`.

⚠️ **CRITICAL:** Generate documentation in **ALL supported languages**. Not doing so is a bug.

## Usage

```
/doc-module <path>
```

**Examples:**
```
/doc-module src/payments
/doc-module .
/doc-module src/payments --languages pt-br,en-us
/doc-module src/auth --team team-auth
```

**Optional parameters:**
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

### 2. Explore the module (essential minimum)

Read:
```bash
find {path} -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) | head -20
```

Then explore the main files (entry points and tests).

### 3. Generate files in multiple languages

Always **technical** type. **For EACH supported language**, create ONE file:

```
content/{lang}/teams/{team}/technical/module-{name}.md
```

Where `{name}` is the last segment of the path (ex: `src/payments` → `payments`).

**MANDATORY EXAMPLE:** Module `src/payments` with SUPPORTED_LANGUAGES="pt-br,en-us":
```
✓ content/pt-br/teams/team-payments/technical/module-payments.md  (Portuguese)
✓ content/en-us/teams/team-payments/technical/module-payments.md  (English)
```

❌ **WRONG:** Generate only in one language:
```
content/teams/go-learning/technical/module-introduction.md  ← MISSING LANGUAGE PATH
```

✓ **CORRECT:** Generate in each language:
```
content/pt-br/teams/go-learning/technical/module-introduction.md
content/en-us/teams/go-learning/technical/module-introduction.md
```

**CRITICAL:** Do not skip this. Every language in SUPPORTED_LANGUAGES gets a file.

---

## Templates

### technical — Portuguese (pt-br)

```markdown
---
title: "Módulo: {nome}"
date: {data ISO 8601 atual}
team: "{team}"
project: "{project}"
doc_type: "technical"
scope: "module"
module_path: "{caminho}"
language: "pt-br"
tags: []
draft: false
---

## Responsabilidade

[Uma frase clara: o que este módulo faz e o que ele NÃO faz.]

## Estrutura

\`\`\`
{caminho}/
├── {arquivo}    ← {responsabilidade em 1 linha}
├── {arquivo}    ← {responsabilidade em 1 linha}
└── {subpasta}/  ← {responsabilidade em 1 linha}
\`\`\`

## Entradas e saídas

[O que o módulo recebe (inputs, eventos, chamadas externas) e o que produz (outputs, efeitos colaterais).]

## Dependências internas

[Outros módulos do projeto que este usa — e para quê.]

## Dependências externas

[Libs e serviços externos — e para quê cada um é usado.]

## Fluxo principal

\`\`\`
[diagrama ASCII ou passo a passo do que acontece quando o módulo é acionado]
\`\`\`

## Casos de borda e comportamentos importantes

[O que acontece em erros, timeouts, dados inválidos, estados inesperados.]

## Como estender

[Como adicionar funcionalidade sem quebrar o existente. Convenções e padrões do módulo.]

## Testes

[Como rodar. O que está coberto e o que não está.]

## Histórico relevante

[Decisões de design do passado que ainda explicam o código atual. Omitir se não houver.]
```

### technical — English (en-us)

```markdown
---
title: "Module: {name}"
date: {current ISO 8601 date}
team: "{team}"
project: "{project}"
doc_type: "technical"
scope: "module"
module_path: "{path}"
language: "en-us"
tags: []
draft: false
---

## Responsibility

[One clear sentence: what this module does and what it does NOT do.]

## Structure

\`\`\`
{path}/
├── {file}       ← {responsibility in 1 line}
├── {file}       ← {responsibility in 1 line}
└── {subfolder}/ ← {responsibility in 1 line}
\`\`\`

## Inputs and outputs

[What the module receives (inputs, events, external calls) and what it produces (outputs, side effects).]

## Internal dependencies

[Other project modules that this one uses — and for what.]

## External dependencies

[External libs and services — and what each one is used for.]

## Main flow

\`\`\`
[ASCII diagram or step-by-step explanation of what happens when the module is triggered]
\`\`\`

## Edge cases and important behaviors

[What happens on errors, timeouts, invalid data, unexpected states.]

## How to extend

[How to add functionality without breaking existing code. Module conventions and patterns.]

## Tests

[How to run them. What is covered and what is not.]

## Relevant history

[Past design decisions that still explain the current code. Omit if there are none.]
```

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

## Validation Checklist (MANDATORY)

Before completing, verify:

- [ ] **Count languages:** How many languages in SUPPORTED_LANGUAGES? (e.g., 2 = pt-br, en-us)
- [ ] **Files created:** Did I create **N files** (one per language)?
  - `content/pt-br/teams/{team}/technical/module-{name}.md`
  - `content/en-us/teams/{team}/technical/module-{name}.md`
  - (... repeat for each language)
- [ ] **Paths correct:** Each file has the language code in the path (e.g., `content/{lang}/`)
- [ ] **Frontmatter:** Each file has correct `language: "{lang}"` metadata
- [ ] **No root-level files:** No files at `content/teams/{team}/technical/` (this is WRONG)

If you create fewer files than languages, **you have a bug**.

## Completion

Show for each language:
```
✓ Module documented in Portuguese (pt-br):
  - content/pt-br/teams/{team}/technical/module-{name}.md

✓ Module documented in English (en-us):
  - content/en-us/teams/{team}/technical/module-{name}.md
```

**REQUIRED:** Show one line per language. If you skip a language, that's a bug.
