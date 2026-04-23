# /doc-pr

Gera documentação a partir de um PR deste repositório e abre um PR no docs-hub.

## Uso

```
/doc-pr [número] [--only <tipos>]
```

**Exemplos:**
```
/doc-pr 142
/doc-pr 142 --only technical
/doc-pr 142 --only technical,product
```

---

## O que fazer ao receber este comando

### 1. Ler a configuração local

Leia o arquivo `.dochubrc` na raiz do repo:

```bash
cat .dochubrc
```

Ele contém:
```
DOCHUB_REPO=org/docs-hub
TEAMS=team-payments,team-checkout
PROJECT=payments-api
DOC_TYPES=technical,product,faq
```

Se `.dochubrc` não existir, informe ao usuário que precisa rodar o `install-skill.sh` e interrompa.

Se `--only` foi passado, use esses tipos em vez de `DOC_TYPES`.

### 2. Determinar o time

Leia `TEAMS` do `.dochubrc` e divida por vírgula.

- **Se houver apenas um time:** use-o diretamente, sem perguntar.
- **Se houver mais de um time:** pergunte ao usuário antes de continuar:

  > Este repo está associado aos times: `team-payments`, `team-checkout`.
  > Para qual time é esta documentação?

  Aguarde a resposta antes de prosseguir. Use o time escolhido como `TEAM` no restante do fluxo.

### 3. Verificar pré-requisitos

```bash
gh auth status
```

Se não autenticado, oriente o usuário a rodar `gh auth login` e interrompa.

### 4. Coletar contexto do PR

O repo atual é o repo de origem — não precisa de `--repo`.

```bash
gh pr view $NUMERO --json number,title,body,author,additions,deletions,files
gh pr diff $NUMERO | head -400
gh pr view $NUMERO --json commits --jq '.commits[].messageHeadline'
```

### 5. Gerar os arquivos de documentação

Para cada tipo em `DOC_TYPES` (ou `--only`), gere o arquivo usando o template correspondente abaixo.

Salve em `/tmp/dochub-docs-{número}/{doc_type}/pr-{número}-{slug}.md`

Onde `{slug}` = título do PR em kebab-case, máximo 50 chars.

### 6. Abrir o PR no docs-hub

```bash
source .dochubrc

# Usa script local se disponível, senão baixa via gh
if [[ -n "$DOCHUB_PATH" && -f "$DOCHUB_PATH/scripts/open-doc-pr.sh" ]]; then
    OPEN_SCRIPT="$DOCHUB_PATH/scripts/open-doc-pr.sh"
else
    gh api "repos/$DOCHUB_REPO/contents/scripts/open-doc-pr.sh" \
        --jq '.content' | base64 -d > /tmp/open-doc-pr.sh
    chmod +x /tmp/open-doc-pr.sh
    OPEN_SCRIPT="/tmp/open-doc-pr.sh"
fi

CURRENT_REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
SOURCE_PR_URL="https://github.com/$CURRENT_REPO/pull/$NUMERO"

DOCHUB_PATH="$DOCHUB_PATH" DOCHUB_REPO="$DOCHUB_REPO" \
bash "$OPEN_SCRIPT" "$TEAM" "$PROJECT" "$NUMERO" "$SOURCE_PR_URL" "/tmp/dochub-docs-$NUMERO"
```

---

## Templates

### technical

```markdown
---
title: "{título do PR}"
date: {data ISO 8601 atual}
team: "{TEAM}"
project: "{PROJECT}"
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

[Para cada arquivo relevante: o porquê da mudança, não apenas o quê.]

## Impacto

- **Breaking change?** Sim/Não — [detalhe se sim]
- **Performance:** [se relevante]
- **Segurança:** [se relevante]
- **Dependências novas:** [se relevante]

## Como testar

```bash
[comandos reais extraídos do PR ou do README]
```

## Observações

[Débito técnico, decisões de design, próximos passos — omitir se não houver]
```

---

### product

```markdown
---
title: "{título do PR em linguagem de produto}"
date: {data ISO 8601 atual}
team: "{TEAM}"
project: "{PROJECT}"
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

[Em produção? Feature flag? Rollout gradual?]
```

---

### faq

```markdown
---
title: "FAQ — {título do PR}"
date: {data ISO 8601 atual}
team: "{TEAM}"
project: "{PROJECT}"
doc_type: "faq"
scope: "pr"
pr: "{número}"
draft: false
---

[5-8 perguntas: devs integrando, QA, produto, suporte. Casos de borda e erros comuns.]

### P: [pergunta]
**R:** [resposta direta e acionável]
```

---

## Ao finalizar

Mostre ao usuário:
- Os arquivos criados (caminhos no docs-hub)
- O link do PR aberto
