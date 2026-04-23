# /doc-module

Documenta um módulo ou pasta inteira do projeto. Ideal para onboarding, pós-refactor e auditoria de código legado.

## Uso

```
/doc-module [caminho] [--only <tipos>]
```

**Exemplos:**
```
/doc-module src/payments
/doc-module src/services/webhook
/doc-module .
/doc-module src/payments --only technical
```

---

## O que fazer ao receber este comando

### 1. Ler a configuração local

```bash
cat .dochubrc
```

Se `.dochubrc` não existir, oriente o usuário a rodar `install-skill.sh` e interrompa.

### 2. Determinar o time

Leia `TEAMS` do `.dochubrc` e divida por vírgula.

- **1 time:** use-o diretamente.
- **2+ times:** pergunte antes de continuar:

  > Este repo está associado aos times: `team-payments`, `team-checkout`.
  > Para qual time é esta documentação?

  Aguarde resposta antes de prosseguir.

### 3. Ler os arquivos do módulo

**Nunca documente o que não leu.** Execute na ordem:

```bash
# Estrutura
find {caminho} -type f \
  | grep -v node_modules | grep -v ".git" | grep -v "__pycache__" \
  | sort

# Histórico recente
git log --oneline --since="90 days ago" -- {caminho} | head -30

# Principais contribuidores
git shortlog --summary --since="180 days ago" -- {caminho}
```

Leia os arquivos priorizando:
1. Entry points: `index.ts`, `index.py`, `main.go`, `__init__.py`
2. Arquivos com mais imports
3. Arquivos de configuração
4. Arquivos de teste (revelam comportamento esperado)

### 4. Verificar pré-requisitos

```bash
gh auth status
```

### 5. Gerar os arquivos

Tipo gerado: sempre **technical**. Se `faq` estiver em `DOC_TYPES` do `.dochubrc`, gere também.
Se `--only` foi passado, use apenas esses tipos.

`{nome}` = último segmento do caminho (ex: `src/payments` → `payments`).
`{slug}` = `{nome}` em kebab-case.

Salve em `/tmp/dochub-docs-module-{slug}/`:
```
/tmp/dochub-docs-module-{slug}/
├── technical/module-{slug}.md
└── faq/faq-module-{slug}.md    ← se faq estiver em DOC_TYPES
```

### 6. Abrir PR no docs-hub

```bash
gh api "repos/$DOCHUB_REPO/contents/scripts/open-doc-pr.sh" \
    --jq '.content' | base64 -d > /tmp/open-doc-pr.sh
chmod +x /tmp/open-doc-pr.sh

bash /tmp/open-doc-pr.sh \
    "$TEAM" \
    "$PROJECT" \
    "module-$SLUG" \
    "" \
    "/tmp/dochub-docs-module-$SLUG"
```

---

## Templates

### technical

```markdown
---
title: "Módulo: {nome}"
date: {data ISO 8601 atual}
team: "{TEAM}"
project: "{PROJECT}"
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

[O que o módulo recebe (inputs, eventos, chamadas) e o que produz (outputs, efeitos colaterais).]

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

### faq

```markdown
---
title: "FAQ — Módulo {nome}"
date: {data ISO 8601 atual}
team: "{TEAM}"
project: "{PROJECT}"
doc_type: "faq"
scope: "module"
module_path: "{caminho}"
draft: false
---

[5-8 perguntas: devs que vão usar ou estender o módulo, QA, novos membros do time.
Foque em comportamentos não óbvios, casos de borda e armadilhas comuns.]

### P: [pergunta]
**R:** [resposta direta e acionável]
```

---

## Ao finalizar

Mostre ao usuário:
- Os arquivos criados (caminhos no docs-hub)
- O link do PR aberto
