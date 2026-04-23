#!/usr/bin/env python3
"""Gera documentação via Claude API a partir do contexto de um PR."""

import anthropic
import json
import os
import argparse
from pathlib import Path
from datetime import datetime

PROMPTS = {
    "technical": """\
Você é um engenheiro de software sênior documentando uma mudança de código.

Analise o contexto abaixo e gere documentação técnica em Markdown com:
- **Resumo** (2-3 linhas objetivas)
- **Motivação e contexto** (por que foi feito)
- **O que foi alterado** (arquivos, funções, endpoints afetados)
- **Impacto técnico** (performance, segurança, breaking changes)
- **Como testar** (comandos e casos relevantes)
- **Dependências** (libs novas, env vars, migrações)

Use linguagem técnica precisa. Seja objetivo. Sem redundâncias.""",

    "product": """\
Você é um Product Manager documentando uma nova funcionalidade.

Analise o contexto abaixo e gere documentação de produto em Markdown com:
- **Nome da feature** (claro e direto)
- **Problema que resolve** (perspectiva do usuário)
- **Como funciona** (descrição funcional, sem jargão técnico)
- **Quem é impactado** (times, usuários, integrações)
- **Status e disponibilidade** (quando disponível, feature flags)
- **Próximos passos** (se houver)

Use linguagem acessível. Foque em valor de negócio.""",

    "faq": """\
Você é um especialista em suporte técnico criando uma FAQ.

Analise o contexto abaixo e gere uma FAQ em Markdown com 5 a 10 perguntas e respostas.
Inclua perguntas que desenvolvedores, QA e produto fariam.
Respostas diretas e acionáveis.

Formato:
### P: [pergunta]
**R:** [resposta]""",
}

FRONTMATTER = {
    "technical": """\
---
title: "{title}"
date: {date}
team: "{team}"
project: "{project}"
doc_type: "technical"
pr: "{pr}"
tags: {tags}
draft: false
---

""",
    "product": """\
---
title: "{title}"
date: {date}
team: "{team}"
project: "{project}"
doc_type: "product"
status: "shipped"
draft: false
---

""",
    "faq": """\
---
title: "FAQ — {title}"
date: {date}
team: "{team}"
project: "{project}"
doc_type: "faq"
draft: false
---

""",
}


def generate_doc(client: anthropic.Anthropic, context: dict, doc_type: str, project: str, team: str) -> str:
    context_text = f"""\
## Projeto: {project} | Time: {team}

### PR / Mudança
Título: {context.get("pr_title", "Push direto para main")}
Descrição: {context.get("pr_body", "Sem descrição")}

### Diff resumido
{context.get("diff_summary", "")}

### Arquivos alterados
{chr(10).join(context.get("changed_files", []))}

### README atual do projeto
{context.get("readme", "Sem README")}
"""

    # Usa prompt caching para o system prompt (economiza tokens em runs repetidos)
    response = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=2048,
        system=[
            {
                "type": "text",
                "text": PROMPTS[doc_type],
                "cache_control": {"type": "ephemeral"},
            }
        ],
        messages=[{"role": "user", "content": context_text}],
    )

    return response.content[0].text


def build_frontmatter(doc_type: str, project: str, team: str, context: dict) -> str:
    pr = context.get("pr_number", "push")
    title = context.get("pr_title", f"Update {project}")
    tags = json.dumps(context.get("tags", []))
    date = datetime.now().strftime("%Y-%m-%dT%H:%M:%S-03:00")

    return FRONTMATTER[doc_type].format(
        title=title, date=date, team=team, project=project, pr=pr, tags=tags
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--context", required=True)
    parser.add_argument("--doc-types", required=True)
    parser.add_argument("--project", required=True)
    parser.add_argument("--team", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    with open(args.context) as f:
        context = json.load(f)

    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    for doc_type in args.doc_types.split(","):
        doc_type = doc_type.strip()
        print(f"Gerando {doc_type}...")

        content = generate_doc(client, context, doc_type, args.project, args.team)
        frontmatter = build_frontmatter(doc_type, args.project, args.team, context)

        pr = context.get("pr_number", "push")
        slug = context.get("pr_title", f"update-{args.project}").lower()
        slug = "".join(c if c.isalnum() else "-" for c in slug).strip("-")[:60]
        filename = f"pr-{pr}-{slug}.md"

        filepath = output_dir / doc_type / filename
        filepath.parent.mkdir(parents=True, exist_ok=True)

        with open(filepath, "w") as f:
            f.write(frontmatter + content)

        print(f"  ✓ {filepath}")


if __name__ == "__main__":
    main()
