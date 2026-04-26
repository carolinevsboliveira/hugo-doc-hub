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

# 2. Rodar setup
bash scripts/setup.sh

# 3. Pronto! Rode localmente
hugo server --buildDrafts
# Acesse: http://localhost:1313
```

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

```bash
# Gera docs (técnica, produto, FAQ) via Claude API
python scripts/generate-docs.py \
  --context context.json \
  --doc-types "technical,product,faq" \
  --project "api-payments" \
  --team "team-payments" \
  --output "content/teams/team-payments/docs"

# Com PR automático (requer Git e GitHub CLI)
python scripts/generate-docs.py \
  --context context.json \
  --doc-types "technical,product,faq" \
  --project "api-payments" \
  --team "team-payments" \
  --output "content/teams/team-payments/docs" \
  --pr
```

**Parâmetros:**
- `--context` *(obrigatório)* — arquivo JSON com contexto do PR
- `--doc-types` *(obrigatório)* — tipos a gerar (ex: `technical,product,faq`)
- `--project` *(obrigatório)* — nome do projeto
- `--team` *(obrigatório)* — ID do time
- `--output` *(obrigatório)* — diretório de saída
- `--pr` *(opcional)* — abre PR com docs geradas (requer Git e GitHub CLI)

**Requer:**
- `ANTHROPIC_API_KEY` — variável de ambiente com chave da API Claude

## Estrutura de conteúdo

```
content/teams/
└── {team-id}/
    ├── _index.md
    ├── technical/   ← docs técnicas (por PR ou módulo)
    ├── product/     ← docs de produto (por feature)
    └── faq/         ← perguntas frequentes
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
draft: false
---
```

## Dependências opcionais

Estas ferramentas são **opcionais** e habilitam funcionalidades de automação:

| Ferramenta | Funcionalidade | Comando |
|-----------|---|---|
| **Git** | Necessário para usar `--pr` em scripts | `git --version` |
| **GitHub CLI** | Necessário para criar PR automaticamente | `gh --version` |
| **Hugo extended** | Build local com SCSS/SASS | `hugo version` |

Se Git não estiver disponível, a flag `--pr` será ignorada com um aviso e você precisará fazer commit/push manualmente.

## Deploy

Push para `main` dispara o build e deploy automático via GitHub Actions + Netlify.

## Secrets necessários

| Secret | Descrição |
|--------|-----------|
| `NETLIFY_AUTH_TOKEN` | Token de autenticação Netlify |
| `NETLIFY_SITE_ID` | ID do site no Netlify |
