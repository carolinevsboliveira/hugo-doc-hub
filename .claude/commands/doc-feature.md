# /doc-feature

Gera documentação completa de uma feature — técnica, produto e FAQ — a partir de um ou mais PRs, uma branch ou um período.

Suporta geração automática em todos os idiomas configurados via `SUPPORTED_LANGUAGES`.

## Uso

```
/doc-feature <nome-da-feature>
```

**Exemplos:**
```
/doc-feature pix-support
/doc-feature sso-auth
/doc-feature pix-support --languages pt-br,en-us
/doc-feature sso-auth --team team-auth --prs 150,151
```

**Parâmetros opcionais:**
- `--prs <n1,n2,n3>` — números de PRs específicos
- `--branch <nome>` — ou use uma branch em vez de PRs
- `--team <id>` — time (detecta automaticamente se não informado)
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

### 2. Uma pergunta só

Se não informado `--prs` ou `--branch`: **pergunta uma vez apenas**:
- "Quais PRs? (ex: 138,141,145) Ou deixe em branco para usar a branch atual."

### 3. Coletar contexto

**Se PRs foram informados:**
```bash
for pr in $PRS; do
  gh pr view $pr --json number,title,body,files,additions,deletions
  gh pr diff $pr | head -200
done
```

**Se branch foi informada:**
```bash
git log main..{branch} --oneline
git diff main...{branch} --stat
git diff main...{branch} | head -400
```

**Sempre leia também os arquivos de teste** — eles revelam o comportamento esperado:
```bash
find . -path ./node_modules -prune -o -name "*.test.*" -newer README.md -print | head -20
```

### 4. Gerar os arquivos em múltiplos idiomas

Sempre gera **technical** e **product**. Gera **faq** se estiver nos `doc_types` do time em `data/teams.yaml`.

**Para cada idioma suportado:**

```
content/{lang}/teams/{team}/technical/feature-{slug}.md
content/{lang}/teams/{team}/product/feature-{slug}.md
content/{lang}/teams/{team}/faq/faq-{slug}.md        ← se faq estiver ativo
```

**Exemplo:** Feature "pix-support" com 2 idiomas:
```
content/pt-br/teams/team-payments/technical/feature-pix-support.md
content/pt-br/teams/team-payments/product/feature-pix-support.md
content/pt-br/teams/team-payments/faq/faq-pix-support.md

content/en-us/teams/team-payments/technical/feature-pix-support.md
content/en-us/teams/team-payments/product/feature-pix-support.md
content/en-us/teams/team-payments/faq/faq-pix-support.md
```

---

## Templates

### technical — Português (pt-br)

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
✓ Documentação de feature criada em português (pt-br):
  - content/pt-br/teams/{team}/technical/feature-{slug}.md
  - content/pt-br/teams/{team}/product/feature-{slug}.md

✓ Documentação de feature criada em inglês (en-us):
  - content/en-us/teams/{team}/technical/feature-{slug}.md
  - content/en-us/teams/{team}/product/feature-{slug}.md
```

Se apenas um idioma: mostre apenas aquele.
