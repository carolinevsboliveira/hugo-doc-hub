#!/usr/bin/env python3
"""Gera documentação via Claude API a partir do contexto de um PR."""

import anthropic
import json
import os
import argparse
import subprocess
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


def is_git_available() -> bool:
    """Verifica se Git está disponível no sistema."""
    try:
        subprocess.run(["git", "--version"], capture_output=True, check=True)
        return True
    except (FileNotFoundError, subprocess.CalledProcessError):
        return False


def is_gh_available() -> bool:
    """Verifica se GitHub CLI está disponível no sistema."""
    try:
        subprocess.run(["gh", "--version"], capture_output=True, check=True)
        return True
    except (FileNotFoundError, subprocess.CalledProcessError):
        return False


def open_pr(context: dict, output_dir: Path, project: str, team: str) -> None:
    """Abre um PR com a documentação gerada (Git e gh já validados upfront)."""
    pr_number = context.get("pr_number", "push")
    pr_title = context.get("pr_title", f"docs: {project}")

    branch = f"docs/{project}/{pr_number}".replace("/push", f"/{int(datetime.now().timestamp())}")

    try:
        subprocess.run(["git", "fetch", "origin", "--quiet"], check=True)
        subprocess.run(["git", "checkout", "main", "--quiet"], check=True)
        subprocess.run(["git", "reset", "--hard", "origin/main", "--quiet"], check=True)
        subprocess.run(["git", "branch", "-D", branch], stderr=subprocess.DEVNULL)
        subprocess.run(["git", "checkout", "-b", branch], check=True)

        subprocess.run(["git", "config", "user.name", "DocHub Bot"], check=True)
        subprocess.run(["git", "config", "user.email", "dochub-bot@noreply.github.com"], check=True)

        subprocess.run(["git", "add", str(output_dir)], check=True)
        subprocess.run(["git", "commit", "-m", f"docs: {project} — {pr_title}"], check=True)

        # Abre PR com GitHub CLI (já validado upfront)
        result = subprocess.run(
            ["gh", "pr", "create",
             "--head", branch,
             "--base", "main",
             "--title", f"docs: {pr_title}",
             "--body", f"Documentação automática gerada para {project}\n\nTimes: {team}"],
            capture_output=True,
            text=True,
            check=True
        )
        print(f"✓ PR aberto: {result.stdout.strip()}")
    except subprocess.CalledProcessError as e:
        print(f"✗ Erro ao abrir PR: {e}")
        raise


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--context", required=True)
    parser.add_argument("--doc-types", required=True)
    parser.add_argument("--project", required=True)
    parser.add_argument("--team", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--pr", action="store_true", help="Abrir PR com a documentação gerada")
    args = parser.parse_args()

    # Valida --pr cedo, antes de gerar docs
    if args.pr:
        if not is_git_available():
            print("❌ Erro: --pr requer Git instalado")
            exit(1)
        if not is_gh_available():
            print("❌ Erro: --pr requer GitHub CLI (gh) instalado")
            print()
            print("Instale em https://cli.github.com ou execute sem --pr:")
            print("  python scripts/generate-docs.py ... (sem --pr)")
            print("  Depois faça commit e push manualmente")
            exit(1)

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

    # Abre PR se solicitado e git está disponível
    if args.pr:
        open_pr(context, output_dir, args.project, args.team)


if __name__ == "__main__":
    main()
