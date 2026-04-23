---
title: "Feature: Suporte a PIX"
date: 2025-01-20T10:00:00-03:00
team: "team-payments"
project: "payments-api"
doc_type: "product"
scope: "feature"
status: "shipped"
draft: false
---

## O que é

Suporte nativo ao PIX como método de pagamento, permitindo transações instantâneas 24/7.

## Problema que resolve

Clientes precisavam de uma alternativa ao cartão de crédito para pagamentos rápidos e sem taxas de processamento elevadas.

## Como funciona

1. Usuário seleciona PIX como forma de pagamento
2. Sistema gera um QR Code com validade de 30 minutos
3. Usuário escaneia e confirma no app do banco
4. Confirmação é recebida via webhook em tempo real

## Quem é impactado

- Time de Checkout (integração no frontend)
- Time de Suporte (novos tipos de disputas)
- Usuários finais (nova opção de pagamento)

## Disponibilidade

Disponível em produção desde 20/01/2025. Sem feature flag.
