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
You are a senior software engineer documenting a code change.

Analyze the context below and generate technical documentation in Markdown with:
- **Summary** (2-3 objective lines)
- **Motivation and context** (why it was done)
- **What was changed** (files, functions, endpoints affected)
- **Technical impact** (performance, security, breaking changes)
- **How to test** (commands and relevant test cases)
- **Dependencies** (new libs, env vars, migrations)

Use precise technical language. Be objective. No redundancies.

NOTE: This document will be generated in all specified languages.""",

    "product": """\
You are a Product Manager documenting a new feature.

Analyze the context below and generate product documentation in Markdown with:
- **Feature name** (clear and direct)
- **Problem it solves** (user perspective)
- **How it works** (functional description, no technical jargon)
- **Who is impacted** (teams, users, integrations)
- **Status and availability** (when available, feature flags)
- **Next steps** (if any)

Use accessible language. Focus on business value.

NOTE: This document will be generated in all specified languages.""",

    "faq": """\
You are a technical support expert creating a FAQ.

Analyze the context below and generate a FAQ in Markdown with 5 to 10 questions and answers.
Include questions that developers, QA, and product teams would ask.
Direct and actionable answers.

Format:
### Q: [question]
**A:** [answer]

NOTE: This FAQ will be generated in all specified languages.""",
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
