# /doc-feature

Gera documentação completa de uma feature — técnica, produto e FAQ — e abre um PR no docs-hub.

## Uso

```
/doc-feature [nome] [--prs <n1,n2>] [--branch <nome>] [--only <tipos>]
```

**Exemplos:**
```
/doc-feature pix-support
/doc-feature sso-auth --prs 138,141,145
/doc-feature new-checkout --branch feature/checkout-v2
/doc-feature pix-support --only technical
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

### 3. Perguntar contexto faltante

Antes de coletar qualquer dado, pergunte ao usuário o que não foi passado no comando:

- Quais PRs fazem parte desta feature? (ou branch)
- Existe um ticket/epic de referência? (link ou número)

### 4. Verificar pré-requisitos

```bash
gh auth status
```

### 5. Coletar contexto

**Se PRs foram informados:**
```bash
# Repita para cada PR
gh pr view $PR --json number,title,body,files,additions,deletions
gh pr diff $PR | head -200
```

**Se branch foi informada:**
```bash
git log main..{branch} --oneline
git diff main...{branch} --stat
git diff main...{branch} | head -400
```

**Sempre leia os arquivos de teste** — revelam comportamento esperado:
```bash
find . -path ./node_modules -prune -o -name "*.test.*" -newer README.md -print | head -20
```

### 6. Gerar os arquivos

Determine os tipos a gerar:
- Default: `technical` e `product` sempre; `faq` se estiver em `DOC_TYPES` do `.dochubrc`
- Se `--only` foi passado, use apenas esses tipos

Se `faq` estiver nos tipos, pergunte antes de gerar:

> Deseja gerar também o FAQ? (sim/não)

Se a resposta for não, remova `faq` da lista.

Determine o caminho de destino dos arquivos:
- Se `DOCHUB_PATH` estiver definido: salve em `$DOCHUB_PATH/content/teams/$TEAM/{doc_type}/feature-{slug}.md`
- Caso contrário: salve em `/tmp/dochub-docs-feature-{slug}/{doc_type}/feature-{slug}.md`

Onde `{slug}` = nome da feature em kebab-case, máximo 50 chars.

### 7. Confirmar antes de abrir o PR

Exiba os caminhos dos arquivos gerados e uma prévia de cada um (título e primeiras seções).

Em seguida, pergunte (padrão **não**):

> Deseja abrir um PR no docs-hub agora, ou prefere revisar os arquivos localmente antes? [PR/local] (padrão: local)

- Se **local**: informe os caminhos dos arquivos gerados e encerre. O usuário pode abrir o PR manualmente depois.
- Se **PR**: pergunte a confirmação final:

  > Posso abrir o PR no docs-hub com esses arquivos? (sim/não)

  Aguarde confirmação. Se não, pergunte o que ajustar, corrija e repita esta etapa.

### 8. Abrir PR no docs-hub

> Execute apenas se o usuário escolheu **PR** na etapa anterior.

```bash
source .dochubrc

if [[ -n "$DOCHUB_PATH" && -f "$DOCHUB_PATH/scripts/open-doc-pr.sh" ]]; then
    OPEN_SCRIPT="$DOCHUB_PATH/scripts/open-doc-pr.sh"
else
    gh api "repos/$DOCHUB_REPO/contents/scripts/open-doc-pr.sh" \
        --jq '.content' | base64 -d > /tmp/open-doc-pr.sh
    chmod +x /tmp/open-doc-pr.sh
    OPEN_SCRIPT="/tmp/open-doc-pr.sh"
fi

DOCS_DIR=""
[[ -z "$DOCHUB_PATH" ]] && DOCS_DIR="/tmp/dochub-docs-feature-$SLUG"

DOCHUB_PATH="$DOCHUB_PATH" DOCHUB_REPO="$DOCHUB_REPO" \
bash "$OPEN_SCRIPT" "$TEAM" "$PROJECT" "feature-$SLUG" "" "$DOCS_DIR"
```

---

## Templates

### technical

```markdown
---
title: "Feature: {nome da feature}"
date: {data ISO 8601 atual}
team: "{TEAM}"
project: "{PROJECT}"
doc_type: "technical"
scope: "feature"
tags: []
draft: false
---

## O que é

[Descrição técnica em 3-5 linhas. O que faz e qual problema resolve do ponto de vista de engenharia.]

## Arquitetura e decisões de design

[Como foi implementada. Padrões usados. Alternativas descartadas e por quê.]

## Componentes e responsabilidades

[Mapa dos módulos/serviços envolvidos e o que cada um faz nesta feature.]

## Fluxo principal

```
[diagrama ASCII ou passo a passo do fluxo de dados/execução]
```

## APIs e contratos

[Endpoints novos ou alterados, payloads, erros esperados. Omitir se não aplicável.]

## Configuração necessária

[Variáveis de ambiente, flags, dependências que precisam estar ativas.]

## Como testar end-to-end

[Roteiro completo de teste da feature.]
```

---

### product

```markdown
---
title: "Feature: {nome da feature}"
date: {data ISO 8601 atual}
team: "{TEAM}"
project: "{PROJECT}"
doc_type: "product"
scope: "feature"
status: "shipped"
draft: false
---

## O que é

[Descrição em linguagem não-técnica, 2-3 linhas.]

## Problema que resolve

[Do ponto de vista do usuário ou do negócio.]

## Como funciona

[Passo a passo funcional. Sem jargão técnico.]

## Quem é impactado

[Times, usuários, integrações, sistemas externos.]

## Disponibilidade

[Feature flag? Rollout gradual? Data de GA?]

## Limitações conhecidas

[O que ainda não é suportado. Omitir se não houver.]

## Próximos passos

[Evoluções planejadas. Omitir se não houver.]
```

---

### faq

```markdown
---
title: "FAQ — {nome da feature}"
date: {data ISO 8601 atual}
team: "{TEAM}"
project: "{PROJECT}"
doc_type: "faq"
scope: "feature"
draft: false
---

[6-10 perguntas: devs integrando, QA, produto, suporte. Casos de borda, erros comuns, migração.]

### P: [pergunta]
**R:** [resposta direta e acionável]
```

---

## Ao finalizar

Mostre ao usuário:
- Os arquivos criados (caminhos no docs-hub)
- O link do PR aberto
