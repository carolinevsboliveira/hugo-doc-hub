#!/bin/bash
# Coleta contexto do PR/projeto e emite JSON para generate-docs.py
set -e

DIFF=$(git diff HEAD~1 HEAD --stat 2>/dev/null | head -50 || echo "Primeiro commit")
CHANGED=$(git diff HEAD~1 HEAD --name-only 2>/dev/null | head -30 || echo "")
README=$(cat README.md 2>/dev/null | head -100 || echo "")

python3 - <<EOF
import json, os

changed = """$CHANGED""".strip().split("\n")
changed = [f for f in changed if f.strip()]

print(json.dumps({
    "pr_number":    os.environ.get("PR_NUMBER", "push"),
    "pr_title":     os.environ.get("PR_TITLE", ""),
    "pr_body":      os.environ.get("PR_BODY", ""),
    "diff_summary": """$DIFF""",
    "changed_files": changed,
    "readme":       """$README""",
    "tags":         []
}))
EOF
