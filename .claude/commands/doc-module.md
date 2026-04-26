# /doc-module

Documenta um módulo ou pasta inteira do projeto. Ideal para onboarding, pós-refactor e auditoria de código legado.

Suporta geração automática em todos os idiomas configurados via `SUPPORTED_LANGUAGES`.

## Uso

```
/doc-module <caminho>
```

**Exemplos:**
```
/doc-module src/payments
/doc-module .
/doc-module src/payments --languages pt-br,en-us
/doc-module src/auth --team team-auth
```

**Parâmetros opcionais:**
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

### 2. Explorar o módulo (mínimo essencial)

Leia:
```bash
find {caminho} -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) | head -20
```

Depois explore os principais arquivos (entry points e testes).

### 3. Gerar os arquivos em múltiplos idiomas

Tipo sempre **technical**. Para cada idioma suportado:

```
content/{lang}/teams/{team}/technical/module-{nome}-{slug}.md
```

Onde `{nome}` é o último segmento do caminho (ex: `src/payments` → `payments`).

**Exemplo:** Módulo `src/payments` em pt-br e en-us:
```
content/pt-br/teams/team-payments/technical/module-payments.md
content/en-us/teams/team-payments/technical/module-payments.md
```

---

## Templates

### technical — Português (pt-br)

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
✓ Módulo documentado em português (pt-br):
  - content/pt-br/teams/{team}/technical/module-{nome}.md

✓ Módulo documentado em inglês (en-us):
  - content/en-us/teams/{team}/technical/module-{nome}.md
```

Se apenas um idioma: mostre apenas aquele.
