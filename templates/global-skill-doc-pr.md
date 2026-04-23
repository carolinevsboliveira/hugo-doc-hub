# /doc-pr

Gera documentação a partir de um PR de qualquer repositório e abre um PR no docs-hub.

## Pré-requisitos (configurar uma vez)

```bash
# 1. Instalar gh CLI — https://cli.github.com
# 2. Autenticar
gh auth login

# 3. Definir o repo do docs-hub (adicione ao ~/.zshrc ou ~/.bashrc)
export DOCHUB_REPO="sua-org/docs-hub"
```

## Uso

```
/doc-pr [número] --repo <org/repo> --team <id> [--project <nome>] [--only <tipos>]
```

**Exemplos:**
```
/doc-pr 142 --repo carolinevsboliveira/payments-api --team team-payments
/doc-pr 142 --repo carolinevsboliveira/payments-api --team team-payments --only technical
/doc-pr 142 --repo carolinevsboliveira/payments-api --team team-payments --project payments-api
```

---

## O que fazer ao receber este comando

### 1. Validar pré-requisitos

Verifique se `DOCHUB_REPO` está definido:
```bash
echo $DOCHUB_REPO
```
Se vazio, oriente o usuário a definir e interrompa.

Verifique se `gh` está autenticado:
```bash
gh auth status
```

### 2. Coletar contexto do PR

```bash
gh pr view $NUMERO --repo $REPO --json number,title,body,author,additions,deletions,files
gh pr diff $NUMERO --repo $REPO | head -400
gh pr view $NUMERO --repo $REPO --json commits --jq '.commits[].messageHeadline'
```

Extraia também o `team` e `project` de `$REPO` caso não sejam passados explicitamente.

### 3. Determinar team e project

- `--team` é obrigatório. Se não passado, pergunte ao usuário.
- `--project` é opcional. Default: parte final de `--repo` (ex: `org/payments-api` → `payments-api`).
- `--only` é opcional. Default: `technical,product,faq`.

### 4. Gerar os arquivos de documentação

Escreva os arquivos em `/tmp/dochub-docs-{número}/`:

```
/tmp/dochub-docs-{número}/
├── technical/pr-{número}-{slug}.md
├── product/pr-{número}-{slug}.md
└── faq/pr-{número}-{slug}.md
```

Onde `{slug}` é o título do PR em kebab-case, máximo 50 chars.

Use os templates abaixo para cada tipo.

### 5. Abrir o PR no docs-hub

Após gerar todos os arquivos, execute:

```bash
# Baixe o script do próprio docs-hub
gh api repos/$DOCHUB_REPO/contents/scripts/open-doc-pr.sh \
  --jq '.content' | base64 -d > /tmp/open-doc-pr.sh
chmod +x /tmp/open-doc-pr.sh

SOURCE_PR_URL="https://github.com/$REPO/pull/$NUMERO"

bash /tmp/open-doc-pr.sh \
  "$TEAM" \
  "$PROJECT" \
  "$NUMERO" \
  "$SOURCE_PR_URL" \
  "/tmp/dochub-docs-$NUMERO"
```

Mostre o link do PR gerado ao usuário.

---

## Templates

### technical

```markdown
---
title: "{título do PR}"
date: {data ISO 8601 atual}
team: "{team}"
project: "{project}"
doc_type: "technical"
scope: "pr"
pr: "{número}"
tags: []
draft: false
---

## Resumo

[2-3 linhas. O que mudou e por quê.]

## Contexto

[Problema que motivou o PR. Link para issue se existir no corpo.]

## O que foi alterado

[Para cada arquivo relevante: o porquê da mudança, não só o quê.]

## Impacto

- **Breaking change?** Sim/Não — [detalhe se sim]
- **Performance:** [se relevante]
- **Segurança:** [se relevante]
- **Dependências novas:** [se relevante]

## Como testar

```bash
[comandos reais do PR ou README]
```

## Observações

[Débito técnico, decisões de design, próximos passos — só se existirem]
```

---

### product

```markdown
---
title: "{título do PR em linguagem de produto}"
date: {data ISO 8601 atual}
team: "{team}"
project: "{project}"
doc_type: "product"
scope: "pr"
pr: "{número}"
status: "shipped"
draft: false
---

## O que muda

[2-3 linhas sem jargão técnico. Foque em valor.]

## Problema que resolve

[Do ponto de vista do usuário ou do negócio.]

## Como funciona agora

[Passo a passo funcional.]

## Quem é impactado

[Times, usuários, integrações.]

## Disponibilidade

[Em produção? Feature flag? Rollout?]
```

---

### faq

```markdown
---
title: "FAQ — {título do PR}"
date: {data ISO 8601 atual}
team: "{team}"
project: "{project}"
doc_type: "faq"
scope: "pr"
pr: "{número}"
draft: false
---

[5-8 perguntas: devs integrando, QA, produto, suporte. Casos de borda e erros comuns.]

### P: [pergunta]
**R:** [resposta direta]
```

---

## Ao finalizar

Mostre ao usuário:
- Os arquivos gerados (caminhos no docs-hub)
- O link do PR aberto no docs-hub
