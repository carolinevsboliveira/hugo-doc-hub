# /doc-pr

Gera documentação técnica, de produto e/ou FAQ a partir de um PR do GitHub.

## Uso

```
/doc-pr <número>
```

**Exemplos:**
```
/doc-pr 142
```

**Parâmetros opcionais:**
- `--team <id>` — time (detecta automaticamente se não informado)
- `--only <tipo>` — gera apenas um tipo (technical/product/faq, padrão: todos)

---

## O que fazer ao receber este comando

### 1. Validar parâmetros

- `número` — obrigatório. Número do PR.
- `--team` — se não informado: tenta detectar do primeiro time em `data/teams.yaml` ou **pergunta uma vez** ao usuário.
- `--only` — se não informado: usa todos os `doc_types` do time.

### 2. Coletar contexto do PR (simplificado)

Se `gh` estiver disponível:
```bash
gh pr view $NUMERO --json number,title,body,changedFiles
gh pr diff $NUMERO | head -300
```

Se não: **pergunta rápida**:
- "Qual é o título do PR?"
- "Qual é a descrição/mudanças principais?" (uma frase)

(Contexto mínimo é suficiente — Claude completa as lacunas.)

### 3. Determinar os tipos a gerar

Consulte `data/teams.yaml` para o time informado e use os `doc_types` registrados.
Se `--only` foi passado, filtre para apenas aqueles tipos.

### 4. Gerar os arquivos

Para cada tipo, gere o arquivo correspondente e salve em:

```
content/teams/{team}/{doc_type}/pr-{número}-{slug}.md
```

Onde `{slug}` é o título do PR em kebab-case, máximo 50 caracteres.

**Exemplo:** PR #142 "Add PIX payment support" do team-payments →
```
content/teams/team-payments/technical/pr-142-add-pix-payment-support.md
content/teams/team-payments/product/pr-142-add-pix-payment-support.md
content/teams/team-payments/faq/pr-142-add-pix-payment-support.md
```

---

## Templates por tipo

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

[2-3 linhas. O que mudou e por quê. Não repita o título.]

## Contexto

[Problema que motivou o PR. Link para issue/ticket se existir no corpo do PR.]

## O que foi alterado

[Para cada arquivo ou grupo relevante, uma linha explicando o porquê da mudança.
Foque na intenção, não na listagem mecânica de arquivos.]

## Impacto

- **Breaking change?** Sim/Não — [detalhe se sim]
- **Performance:** [se relevante]
- **Segurança:** [se relevante]
- **Dependências novas:** [se relevante]

## Como testar

```bash
[comandos reais extraídos do PR ou do README]
```

[Casos de teste relevantes a cobrir]

## Observações

[Débito técnico gerado, decisões de design, próximos passos — só se existirem]
```

---

### product

```markdown
---
title: "{título do PR — reformulado para linguagem de produto}"
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

[2-3 linhas em linguagem não-técnica. Foque em valor, não em implementação.]

## Problema que resolve

[Do ponto de vista do usuário ou do negócio.]

## Como funciona agora

[Passo a passo funcional. Sem jargão técnico.]

## Quem é impactado

[Times, usuários, integrações, sistemas externos.]

## Disponibilidade

[Já em produção? Feature flag? Rollout gradual?]
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

[Gere 5-8 perguntas pensando em: devs que vão integrar, QA, produto, suporte.
Inclua perguntas sobre casos de borda e erros comuns visíveis no diff.]

### P: [pergunta]
**R:** [resposta direta e acionável]
```

---

## Ao finalizar

Mostre: ✓ Documentação criada em `content/teams/{team}/...`
