# /doc-module

Documenta um módulo ou pasta inteira do projeto. Ideal para onboarding, pós-refactor e auditoria de código legado.

## Uso

```
/doc-module [caminho] [--team <id>] [--project <nome>]
```

**Exemplos:**
```
/doc-module src/payments
/doc-module src/services/webhook
/doc-module .
```

---

## O que fazer ao receber este comando

### 1. Ler os arquivos do módulo

Nunca documente o que não leu. Execute na ordem:

```bash
# Estrutura do módulo
find {caminho} -type f | grep -v node_modules | grep -v ".git" | grep -v "__pycache__" | sort

# Histórico recente
git log --oneline --since="90 days ago" -- {caminho} | head -30

# Principais contribuidores
git shortlog --summary --since="180 days ago" -- {caminho}
```

Depois leia os arquivos priorizando:
1. Entry points: `index.ts`, `index.py`, `main.go`, `__init__.py`
2. Arquivos com mais imports
3. Arquivos de configuração
4. Arquivos de teste (revelam comportamento esperado)

### 2. Gerar o arquivo

Tipo sempre **technical**. Caminho:
```
content/teams/{team}/technical/module-{nome}-{slug}.md
```

Onde `{nome}` é o último segmento do caminho (ex: `src/payments` → `payments`).

---

## Template

### `content/teams/{team}/technical/module-{nome}.md`

```markdown
---
title: "Módulo: {nome}"
date: {data ISO 8601 atual}
team: "{team}"
project: "{project}"
doc_type: "technical"
scope: "module"
module_path: "{caminho}"
tags: []
draft: false
---

## Responsabilidade

[Uma frase clara: o que este módulo faz e o que ele NÃO faz.]

## Estrutura

```
{caminho}/
├── {arquivo}    ← {responsabilidade em 1 linha}
├── {arquivo}    ← {responsabilidade em 1 linha}
└── {subpasta}/  ← {responsabilidade em 1 linha}
```

## Entradas e saídas

[O que o módulo recebe (inputs, eventos, chamadas externas) e o que produz (outputs, efeitos colaterais).]

## Dependências internas

[Outros módulos do projeto que este usa — e para quê.]

## Dependências externas

[Libs e serviços externos — e para quê cada um é usado.]

## Fluxo principal

```
[diagrama ASCII ou passo a passo do que acontece quando o módulo é acionado]
```

## Casos de borda e comportamentos importantes

[O que acontece em erros, timeouts, dados inválidos, estados inesperados.]

## Como estender

[Como adicionar funcionalidade sem quebrar o existente. Convenções e padrões do módulo.]

## Testes

[Como rodar. O que está coberto e o que não está.]

## Histórico relevante

[Decisões de design do passado que ainda explicam o código atual. Omitir se não houver.]
```

---

## Ao finalizar

Liste o arquivo criado com seu caminho relativo e confirme ao usuário.
