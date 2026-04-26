# DocHub

Documentação centralizada de todos os times — técnico, produto e FAQ.

## Stack

- **Hugo** — geração de site estático
- **Tema dochub** — tema customizado com busca full-text
- **GitHub Actions** — build e deploy automático
- **Netlify** — hospedagem

## Setup inicial

```bash
# 1. Copiar .env.example para .env e atualizar valores
cp .env.example .env
# Edite .env com os dados da sua organização

# 2. (Opcional) Configurar idiomas — ver seção de Internacionalização
#    LANGUAGE_CODE="pt-br"
#    SUPPORTED_LANGUAGES="pt-br,en-us"

# 3. Rodar setup
bash scripts/setup.sh

# 4. Pronto! Rode localmente
hugo server --buildDrafts
# Acesse: http://localhost:1313
```

## Internacionalização (i18n) 🌍

DocHub suporta múltiplos idiomas nativamente. Configure via variáveis de ambiente no `.env`:

### Configuração Rápida

```bash
# 1. Editar .env
LANGUAGE_CODE="pt-br"              # Idioma principal
SUPPORTED_LANGUAGES="pt-br,en-us"  # Todos os idiomas suportados

# 2. Rodar setup (auto-configura Hugo)
bash scripts/setup.sh

# 3. Pronto! Hugo gera URLs para cada idioma
# http://localhost:1313/         ← Português (idioma principal)
# http://localhost:1313/en-us/   ← Inglês
```

### Idiomas Suportados por Padrão

| Código | Idioma |
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

### Estrutura de Conteúdo com i18n

```
content/
├── pt-br/
│   └── teams/{team-id}/*
├── en-us/
│   └── teams/{team-id}/*
└── es-es/
    └── teams/{team-id}/*

i18n/
├── pt-br.yaml    ← Traduções
├── en-us.yaml    ← Traduções
└── es-es.yaml    ← Traduções
```

### Comandos Claude com i18n

Os comandos `/doc-pr`, `/doc-feature` e `/doc-module` geram automaticamente em **todos os idiomas**:

```bash
# Gera em pt-br e en-us (se configurados)
/doc-pr 142

# Ou especificar idiomas
/doc-pr 142 --languages pt-br,en-us
/doc-feature pix-support --languages pt-br
/doc-module src/payments --languages en-us
```

Resultado:
```
content/pt-br/teams/team-payments/technical/pr-142-*.md
content/en-us/teams/team-payments/technical/pr-142-*.md
```

### Adicionar Novo Idioma

1. **Criar arquivo de tradução:**
   ```bash
   cp i18n/pt-br.yaml i18n/es-es.yaml
   # Editar e traduzir strings
   ```

2. **Atualizar `.env`:**
   ```bash
   SUPPORTED_LANGUAGES="pt-br,en-us,es-es"
   ```

3. **Rodar configuração:**
   ```bash
   python3 scripts/manage-i18n.py
   ```

### Documentação Completa

Para configuração avançada, tradução de templates e mais:
👉 **[I18N.md](./I18N.md)** — Guia detalhado de internacionalização

---

## Adicionar um novo time

```bash
# Básico — apenas cria dados e conteúdo local
bash scripts/register-team.sh --id team-xyz --name "Time XYZ" [--slack "#team-xyz"]

# Com PR automático (requer Git)
bash scripts/register-team.sh --id team-xyz --name "Time XYZ" --pr
# Se Git não estiver disponível, a flag será ignorada com aviso
```

**Parâmetros:**
- `--id` *(obrigatório)* — identificador único (ex: `team-payments`)
- `--name` *(obrigatório)* — nome de exibição (ex: `Payments`)
- `--slack` *(opcional)* — canal Slack (ex: `#team-payments`)
- `--repos` *(opcional)* — repositórios associados, separados por vírgula
- `--doc-types` *(opcional)* — tipos de doc (padrão: `technical,product,faq`)
- `--pr` *(opcional)* — abre PR automaticamente (requer Git e GitHub CLI)

## Gerar documentação com Claude

### ✨ Modo simplificado (recomendado) — Skills

Use as skills integradas no Claude Code:

```bash
/doc-pr 142              # Documentação de um PR
/doc-feature pix-support # Documentação de uma feature
/doc-module src/payments # Documentação de um módulo
```

As skills:
- ✅ Detectam projeto/time automaticamente
- ✅ Fazem perguntas apenas quando necessário
- ✅ Geram documentação técnica, produto e FAQ
- ✅ **Geram em TODOS os idiomas suportados** (i18n)
- ✅ Oferecem abrir PR automaticamente

**Exemplos com i18n:**
```bash
# Gera em pt-br e en-us (se SUPPORTED_LANGUAGES="pt-br,en-us")
/doc-pr 142

# Especificar idiomas (padrão: todos do SUPPORTED_LANGUAGES)
/doc-pr 142 --languages pt-br,en-us
/doc-feature pix-support --languages pt-br
/doc-module src/payments --languages en-us
```

### Modo avançado (Python direto)

Para uso programático ou CI/CD:

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

Gera automaticamente em `content/{lang}/teams/team-payments/...` para cada idioma.

**Contexto JSON:**
```json
{
  "pr_number": "123",
  "pr_title": "Titulo",
  "pr_body": "Descrição",
  "changed_files": ["src/file.ts"],
  "diff_summary": "Resumo",
  "readme": "README (opcional)",
  "tags": []
}
```

**Parâmetros:**
- `--context` — arquivo JSON
- `--doc-types` — tipos (ex: `technical,product,faq`)
- `--project` — nome do projeto
- `--team` — ID do time
- `--output` — diretório de saída (gera content/{lang}/...)
- `--pr` *(opcional)* — abre PR (requer Git e GitHub CLI)

**Variáveis de ambiente:**
- `LANGUAGE_CODE` — idioma principal (padrão: `pt-br`)
- `SUPPORTED_LANGUAGES` — idiomas suportados (padrão: `pt-br`)
- `ANTHROPIC_API_KEY` — API key do Claude (obrigatório)

**Requer:** `ANTHROPIC_API_KEY`

## Estrutura de conteúdo

Com i18n habilitado:

```
content/
├── pt-br/
│   └── teams/{team-id}/
│       ├── _index.md
│       ├── technical/   ← docs técnicas (por PR ou módulo)
│       ├── product/     ← docs de produto (por feature)
│       └── faq/         ← perguntas frequentes
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

## Frontmatter obrigatório

```yaml
---
title: ""
date: 2025-01-01T00:00:00-03:00
team: "team-id"
project: "nome-do-projeto"
doc_type: "technical | product | faq"
scope: "pr | feature | module"
language: "pt-br"  # Campo de idioma (adicionado automaticamente)
draft: false
---
```

**Nota:** O campo `language` é adicionado automaticamente pelos comandos Claude.

## Dependências opcionais

| Ferramenta | Para quê | Obrigatório? |
|-----------|----------|--------------|
| **Git** | Versionamento e PRs | Opcional, mas recomendado |
| **GitHub CLI (gh)** | Abrir PR automaticamente | Requerido se usar `--pr` |
| **Hugo extended** | Build local com SCSS/SASS | Opcional (para desenvolvimento) |
| **Python 3.8+** | Scripts de i18n e geração de docs | Opcional (se usar modo Python) |
| **PyYAML** | Carregar traduções de i18n | Instalado automaticamente |

### Proteções automáticas:

- ✅ **Sem Git**: Funcionalidades de PR não são oferecidas
- ✅ **Git mas sem gh**: Mensagem clara com instruções para instalar
- ✅ **Com ambos**: Tudo funciona normalmente
- ✅ **i18n**: Funciona mesmo com um único idioma (sem configuração extra)

Se não tiver `gh` instalado, você pode:
1. Instalar: https://cli.github.com
2. Ou fazer commit/push manualmente e abrir PR no GitHub

### Scripts de i18n

Disponíveis em `scripts/`:
- **`manage-i18n.py`** — Atualiza configuração de idiomas no Hugo
- **`i18n_utils.py`** — Módulo Python para gerenciar i18n em scripts
- **`configure-i18n.sh`** — Gera blocos de configuração TOML

## Deploy

Push para `main` dispara o build e deploy automático via GitHub Actions + Netlify.

## Secrets necessários

| Secret | Descrição |
|--------|-----------|
| `NETLIFY_AUTH_TOKEN` | Token de autenticação Netlify |
| `NETLIFY_SITE_ID` | ID do site no Netlify |
