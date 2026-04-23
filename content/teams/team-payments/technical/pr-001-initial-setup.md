---
title: "Setup inicial da payments-api"
date: 2025-01-15T10:00:00-03:00
team: "team-payments"
project: "payments-api"
doc_type: "technical"
scope: "pr"
pr: "001"
tags: ["setup", "api", "initial"]
draft: false
---

## Resumo

Configuração inicial do serviço de pagamentos com estrutura base, autenticação e integração com o gateway principal.

## Contexto

Criação do repositório e estrutura inicial do serviço responsável por processar transações financeiras.

## O que foi alterado

- `src/api/` — Endpoints REST base para criação e consulta de transações
- `src/auth/` — Middleware de autenticação via JWT
- `src/gateway/` — Adapter para o gateway de pagamentos externo
- `config/` — Variáveis de ambiente e configuração de ambiente

## Impacto

- **Breaking change?** Não — serviço novo
- **Dependências novas:** `stripe-sdk`, `jsonwebtoken`

## Como testar

```bash
cp .env.example .env
npm install
npm run dev
curl -X POST http://localhost:3000/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"amount": 100, "currency": "BRL"}'
```
