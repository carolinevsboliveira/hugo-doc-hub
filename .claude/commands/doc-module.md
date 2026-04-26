# /doc-module

Documenta um módulo ou pasta inteira do projeto. Ideal para onboarding, pós-refactor e auditoria de código legado.

## Uso

```
/doc-module <caminho>
```

**Exemplos:**
```
/doc-module src/payments
/doc-module .
```

**Parâmetros opcionais:**
- `--team <id>` — time (detecta automaticamente se não informado)

---

## O que fazer ao receber este comando

### 1. Explorar o módulo (mínimo essencial)

Leia:
```bash
find {caminho} -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) | head -20
```

Depois explore os principais arquivos (entry points e testes).

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

## Dependências

- **Git** — para oferecer opção de PR (obrigatório)
- **GitHub CLI (gh)** — para abrir PR automaticamente (obrigatório se usar PR)

Se `gh` não estiver instalado mas o usuário escolher PR, mostre:
```
❌ Erro: --pr requer GitHub CLI (gh) instalado
Instale em https://cli.github.com
```

---

## Ao finalizar

Mostre: ✓ Módulo documentado em `content/teams/{team}/technical/module-{nome}.md`
