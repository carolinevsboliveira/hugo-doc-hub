---
title: "FAQ — Integração PIX"
date: 2025-01-20T10:00:00-03:00
team: "team-payments"
project: "payments-api"
doc_type: "faq"
scope: "feature"
draft: false
---

### P: Qual o tempo de expiração do QR Code?
**R:** 30 minutos por padrão. Configurável via `PIX_EXPIRY_MINUTES` no `.env`.

### P: Como recebo a confirmação do pagamento?
**R:** Via webhook no endpoint `POST /webhooks/pix`. Configure a URL no painel do banco.

### P: O PIX funciona em sandbox?
**R:** Sim. Use as credenciais de teste do arquivo `.env.example`. Transações de sandbox têm prefixo `test_`.

### P: O que acontece se o webhook falhar?
**R:** O sistema retenta por até 24h com backoff exponencial. Após isso, a transação fica com status `webhook_failed`.

### P: Como consultar o status de uma transação PIX?
**R:** `GET /transactions/:id` — o campo `payment_method` virá como `pix` e `status` como `pending`, `paid` ou `expired`.
