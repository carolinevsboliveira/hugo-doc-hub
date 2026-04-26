# /doc-pr

Generates technical, product, and/or FAQ documentation from a GitHub PR.

Supports automatic generation in all languages configured via `SUPPORTED_LANGUAGES`.

## Usage

```
/doc-pr <number>
```

**Examples:**
```
/doc-pr 142
/doc-pr 142 --languages pt-br,en-us
/doc-pr 142 --team team-payments --only technical
```

**Optional parameters:**
- `--team <id>` — team (auto-detected if not provided)
- `--only <type>` — generate only one type (technical/product/faq, default: all)
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

### 2. Validate parameters

- `number` — required. PR number.
- `--team` — if not provided: try to detect from the first team in `data/teams.yaml` or **ask once**.
- `--only` — if not provided: use all `doc_types` for the team.

### 3. Collect PR context (simplified)

If `gh` is available:
```bash
gh pr view $NUMBER --json number,title,body,changedFiles
gh pr diff $NUMBER | head -300
```

If not: **quick questions**:
- "What is the PR title?"
- "What is the description/main changes?" (one phrase)

(Minimal context is sufficient — Claude completes the gaps.)

### 4. Determine doc types to generate

Check `data/teams.yaml` for the specified team and use the registered `doc_types`.
If `--only` was passed, filter to only those types.

### 5. Generate files in multiple languages

**For each supported language**, generate files:

```
content/{lang}/teams/{team}/{doc_type}/pr-{number}-{slug}.md
```

**Example:** PR #142 "Add PIX payment support" from team-payments in pt-br and en-us:
```
content/pt-br/teams/team-payments/technical/pr-142-add-pix-payment-support.md
content/pt-br/teams/team-payments/product/pr-142-add-pix-payment-support.md
content/en-us/teams/team-payments/technical/pr-142-add-pix-payment-support.md
content/en-us/teams/team-payments/product/pr-142-add-pix-payment-support.md
```

**IMPORTANT:** Each document type is generated in ALL specified languages. One Claude API call generates the content once, then it's included in all language versions.

### 6. Use translation for section titles and metadata

For each language, translate section titles using the i18n module:

```python
i18n = load_i18n()
title_technical = i18n.translate("doc.technical", language="en-us")  # "Technical"
title_product = i18n.translate("doc.product", language="pt-br")      # "Produto"
```

---

## Templates by type and language

### technical — Portuguese (pt-br)

```markdown
---
title: "{PR title}"
date: {current ISO 8601 date}
team: "{team}"
project: "{project}"
doc_type: "technical"
scope: "pr"
pr: "{number}"
language: "pt-br"
tags: []
draft: false
---

## Resumo

[2-3 linhas. O que mudou e por quê. Não repita o título.]

## Contexto

[Problema que motivou o PR. Link para issue/ticket se existir no corpo do PR.]

## O que foi alterado

[Para cada arquivo ou grupo relevante, uma linha explicando o porquê da mudança.
Foque na intenção, não na listagem mecânica de arquivos.]

## Impacto

- **Breaking change?** Sim/Não — [detalhe se sim]
- **Performance:** [se relevante]
- **Segurança:** [se relevante]
- **Dependências novas:** [se relevante]

## Como testar

\`\`\`bash
[comandos reais extraídos do PR ou do README]
\`\`\`

[Casos de teste relevantes a cobrir]

## Observações

[Débito técnico gerado, decisões de design, próximos passos — só se existirem]
```

### technical — English (en-us)

```markdown
---
title: "{PR title}"
date: {current ISO 8601 date}
team: "{team}"
project: "{project}"
doc_type: "technical"
scope: "pr"
pr: "{number}"
language: "en-us"
tags: []
draft: false
---

## Summary

[2-3 lines. What changed and why. Don't repeat the title.]

## Context

[Problem that motivated the PR. Link to issue/ticket if it exists in the PR body.]

## What was changed

[For each file or relevant group, one line explaining why the change was made.
Focus on intent, not mechanical file listing.]

## Impact

- **Breaking change?** Yes/No — [detail if yes]
- **Performance:** [if relevant]
- **Security:** [if relevant]
- **New dependencies:** [if relevant]

## How to test

\`\`\`bash
[real commands extracted from PR or README]
\`\`\`

[Relevant test cases to cover]

## Notes

[Technical debt generated, design decisions, next steps — only if they exist]
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
✓ Documentation created in Portuguese (pt-br):
  - content/pt-br/teams/{team}/technical/...
  - content/pt-br/teams/{team}/product/...

✓ Documentation created in English (en-us):
  - content/en-us/teams/{team}/technical/...
  - content/en-us/teams/{team}/product/...
```

If only one language: show only that one.
