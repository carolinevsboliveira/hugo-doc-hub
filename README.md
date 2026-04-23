# DocHub

Documentação centralizada de todos os times — técnico, produto e FAQ.

## Stack

- **Hugo** — geração de site estático
- **Tema dochub** — tema customizado com busca full-text
- **GitHub Actions** — build e deploy automático
- **Netlify** — hospedagem

## Desenvolvimento local

```bash
# Pré-requisito: Hugo extended instalado
# https://gohugo.io/installation/

hugo server --buildDrafts
# Acesse: http://localhost:1313
```

## Adicionar um novo time

```bash
./scripts/register-team.sh \
  --id team-nome \
  --name "Nome do Time" \
  --slack "#team-nome" \
  --doc-types "technical,product,faq"
```

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

## Deploy

Push para `main` dispara o build e deploy automático via GitHub Actions + Netlify.

## Secrets necessários

| Secret | Descrição |
|--------|-----------|
| `NETLIFY_AUTH_TOKEN` | Token de autenticação Netlify |
| `NETLIFY_SITE_ID` | ID do site no Netlify |
