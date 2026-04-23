# /doc-feature

Gera documentação completa de uma feature — técnica, produto e FAQ — a partir de um ou mais PRs, uma branch ou um período.

## Uso

```
/doc-feature [nome-da-feature] [--team <id>] [--project <nome>] [--prs <n1,n2>] [--branch <nome>]
```

**Exemplos:**
```
/doc-feature pix-support
/doc-feature sso-auth --prs 138,141,145
/doc-feature new-checkout --branch feature/checkout-v2
/doc-feature pix-support --team team-payments --project payments-api
```

---

## O que fazer ao receber este comando

### 1. Perguntar ao usuário (antes de qualquer comando)

Se não informado, pergunte:
1. Quais PRs fazem parte desta feature? (ou branch, ou período)
2. Existe um ticket/epic de referência?

### 2. Coletar contexto

**Se PRs foram informados:**
```bash
for pr in $PRS; do
  gh pr view $pr --json number,title,body,files,additions,deletions
  gh pr diff $pr | head -200
done
```

**Se branch foi informada:**
```bash
git log main..{branch} --oneline
git diff main...{branch} --stat
git diff main...{branch} | head -400
```

**Sempre leia também os arquivos de teste** — eles revelam o comportamento esperado:
```bash
find . -path ./node_modules -prune -o -name "*.test.*" -newer README.md -print | head -20
```

### 3. Gerar os arquivos

Sempre gera **technical** e **product**. Gera **faq** se estiver nos `doc_types` do time em `data/teams.yaml`.

**Caminhos:**
```
content/teams/{team}/technical/feature-{slug}.md
content/teams/{team}/product/feature-{slug}.md
content/teams/{team}/faq/faq-{slug}.md        ← se faq estiver ativo
```

---

## Templates

### technical — `content/teams/{team}/technical/feature-{slug}.md`

```markdown
---
title: "Feature: {nome da feature}"
date: {data ISO 8601 atual}
team: "{team}"
project: "{project}"
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

[Endpoints novos ou alterados, payloads, erros esperados. Só se aplicável.]

## Configuração necessária

[Variáveis de ambiente, flags, dependências que precisam estar ativas.]

## Como testar end-to-end

[Roteiro completo de teste da feature.]
```

---

### product — `content/teams/{team}/product/feature-{slug}.md`

```markdown
---
title: "Feature: {nome da feature}"
date: {data ISO 8601 atual}
team: "{team}"
project: "{project}"
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

[O que ainda não é suportado nesta versão. Omitir se não houver.]

## Próximos passos

[Evoluções planejadas. Omitir se não houver.]
```

---

### faq — `content/teams/{team}/faq/faq-{slug}.md`

```markdown
---
title: "FAQ — {nome da feature}"
date: {data ISO 8601 atual}
team: "{team}"
project: "{project}"
doc_type: "faq"
scope: "feature"
draft: false
---

[Gere 6-10 perguntas pensando em: devs que vão integrar, QA, produto, suporte.
Inclua perguntas sobre casos de borda, erros comuns e migração.]

### P: [pergunta]
**R:** [resposta direta e acionável]
```

---

## Ao finalizar

Liste os arquivos criados com seus caminhos relativos e confirme ao usuário.
