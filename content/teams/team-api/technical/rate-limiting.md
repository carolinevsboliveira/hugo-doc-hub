---
title: "Rate Limiting Implementation"
date: 2025-02-05T10:00:00-03:00
team: "team-api"
doc_type: "technical"
draft: false
---

## Rate Limiting

Implementado via Redis com sliding window.

### Limites
- 1000 requests/min por autenticado
- 100 requests/min por IP anônimo
