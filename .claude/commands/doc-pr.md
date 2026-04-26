# /doc-pr

Gera documentação técnica, de produto e/ou FAQ a partir de um PR do GitHub.

Suporta geração automática em todos os idiomas configurados via `SUPPORTED_LANGUAGES`.

## Uso

```
/doc-pr <número>
```

**Exemplos:**
```
/doc-pr 142
/doc-pr 142 --languages pt-br,en-us
/doc-pr 142 --team team-payments --only technical
```

**Parâmetros opcionais:**
- `--team <id>` — time (detecta automaticamente se não informado)
- `--only <tipo>` — gera apenas um tipo (technical/product/faq, padrão: todos)
- `--languages <lang1,lang2>` — idiomas específicos (padrão: todos do SUPPORTED_LANGUAGES)

---

## O que fazer ao receber este comando

### 1. Detectar configuração de i18n

Leia variáveis de ambiente ou carregue do `.env`:

```python
from scripts.i18n_utils import load_i18n

i18n = load_i18n()
primary_lang = i18n.get_primary_language()      # "pt-br"
supported_langs = i18n.get_supported_languages() # ["pt-br", "en-us"]
```

Se `--languages` foi passado, use apenas aqueles. Senão, use `SUPPORTED_LANGUAGES`.

### 2. Validar parâmetros

- `número` — obrigatório. Número do PR.
- `--team` — se não informado: tenta detectar do primeiro time em `data/teams.yaml` ou **pergunta uma vez** ao usuário.
- `--only` — se não informado: usa todos os `doc_types` do time.

### 3. Coletar contexto do PR (simplificado)

Se `gh` estiver disponível:
```bash
gh pr view $NUMERO --json number,title,body,changedFiles
gh pr diff $NUMERO | head -300
```

Se não: **pergunta rápida**:
- "Qual é o título do PR?"
- "Qual é a descrição/mudanças principais?" (uma frase)

(Contexto mínimo é suficiente — Claude completa as lacunas.)

### 4. Determinar os tipos a gerar

Consulte `data/teams.yaml` para o time informado e use os `doc_types` registrados.
Se `--only` foi passado, filtre para apenas aqueles tipos.

### 5. Gerar os arquivos em múltiplos idiomas

**Para cada idioma suportado**, gere os arquivos:

```
content/{lang}/teams/{team}/{doc_type}/pr-{número}-{slug}.md
```

**Exemplo:** PR #142 "Add PIX payment support" do team-payments em pt-br e en-us:
```
content/pt-br/teams/team-payments/technical/pr-142-add-pix-payment-support.md
content/pt-br/teams/team-payments/product/pr-142-add-pix-payment-support.md
content/en-us/teams/team-payments/technical/pr-142-add-pix-payment-support.md
content/en-us/teams/team-payments/product/pr-142-add-pix-payment-support.md
```

### 6. Usar tradução de títulos e metadados

Para cada idioma, traduza os títulos de seção usando o módulo i18n:

```python
i18n = load_i18n()
title_technical = i18n.translate("doc.technical", language="en-us")  # "Technical"
title_product = i18n.translate("doc.product", language="pt-br")      # "Produto"
```

---

## Templates por tipo e idioma

### technical — Português (pt-br)

```markdown
---
title: "{título do PR}"
date: {data ISO 8601 atual}
team: "{team}"
project: "{project}"
doc_type: "technical"
scope: "pr"
pr: "{número}"
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

## Dependências

- **Git** — para oferecer opção de PR (obrigatório)
- **GitHub CLI (gh)** — para abrir PR automaticamente (obrigatório se usar PR)
- **i18n_utils.py** — para carregar configuração de idiomas

Se `gh` não estiver instalado mas o usuário escolher PR, mostre:
```
❌ Erro: --pr requer GitHub CLI (gh) instalado
Instale em https://cli.github.com
```

---

## Ao finalizar

Mostre para cada idioma:
```
✓ Documentação criada em português (pt-br):
  - content/pt-br/teams/{team}/technical/...
  - content/pt-br/teams/{team}/product/...

✓ Documentação criada em inglês (en-us):
  - content/en-us/teams/{team}/technical/...
  - content/en-us/teams/{team}/product/...
```

Se apenas um idioma: mostre apenas aquele.
