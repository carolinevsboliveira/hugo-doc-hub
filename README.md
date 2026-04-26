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
- ✅ Oferecem abrir PR automaticamente

### Modo avançado (Python direto)

Para uso programático ou CI/CD:

```bash
python scripts/generate-docs.py \
  --context context.json \
  --doc-types "technical,product,faq" \
  --project "api-payments" \
  --team "team-payments" \
  --output "content/teams/team-payments/docs" \
  --pr
```

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
- `--output` — diretório de saída
- `--pr` *(opcional)* — abre PR (requer Git e GitHub CLI)

**Requer:** `ANTHROPIC_API_KEY`

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
