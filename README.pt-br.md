# DocHub

Documentação centralizada de todos os times — técnico, produto e FAQ.

## Stack

- **Hugo** — geração de site estático
- **Tema dochub** — tema customizado com busca full-text
- **GitHub Actions** — build e deploy automático
- **Netlify** — hospedagem

## Dependências

### 🔴 Obrigatórias

Para usar qualquer funcionalidade do DocHub, você precisa:

| Ferramenta | Versão | Instalação |
|-----------|--------|-----------|
| **Hugo** | extended v0.120+ | [hugo.io](https://gohugo.io/installation/) |
| **Python** | 3.8+ | [python.org](https://www.python.org/downloads/) |
| **PyYAML** | - | `pip install pyyaml` |

### 🟡 Obrigatórias (para usar skills do Claude)

Para usar `/doc-pr`, `/doc-feature`, `/doc-module`:

| Ferramenta | Versão | Instalação | Por quê |
|-----------|--------|-----------|---------|
| **ANTHROPIC_API_KEY** | - | [console.anthropic.com](https://console.anthropic.com/keys) | Necessário para chamar Claude API |

### 🟢 Opcionais (mas recomendadas)

| Ferramenta | Versão | Instalação | Por quê |
|-----------|--------|-----------|---------|
| **Git** | 2.0+ | [git-scm.com](https://git-scm.com/downloads) | Versionamento; necessário para `--pr` |
| **GitHub CLI (gh)** | 2.0+ | [cli.github.com](https://cli.github.com/) | Abrir PRs automaticamente com `--pr` |

**Resumo das dependencies:**
- Sem Git/gh: Funciona tudo exceto abrir PRs (faça commit/push manualmente)
- Sem ANTHROPIC_API_KEY: As skills e `generate-docs.py` não funcionam

---

## Setup inicial

```bash
# 1. Instalar dependências obrigatórias
pip install pyyaml
# E ter Hugo extended instalado

# 2. Copiar .env.example para .env e atualizar valores
cp .env.example .env
# Edite .env com os dados da sua organização

# 3. (Opcional) Configurar idiomas — ver seção de Internacionalização
#    LANGUAGE_CODE="pt-br"
#    SUPPORTED_LANGUAGES="pt-br,en-us"

# 4. Rodar setup
bash scripts/setup.sh

# 5. Pronto! Rode localmente
hugo server --buildDrafts
# Acesse: http://localhost:1313
```

## Internacionalização (i18n) 🌍

DocHub suporta múltiplos idiomas nativamente. Configure via variáveis de ambiente no `.env`:

### Configuração Rápida

```bash
# 1. Editar .env
LANGUAGE_CODE="pt-br"              # Idioma principal
SUPPORTED_LANGUAGES="pt-br,en-us"  # Todos os idiomas suportados

# 2. Rodar setup (auto-configura Hugo)
bash scripts/setup.sh

# 3. Pronto! Hugo gera URLs para cada idioma
# http://localhost:1313/         ← Português (idioma principal)
# http://localhost:1313/en-us/   ← Inglês
```

### Idiomas Suportados por Padrão

| Código | Idioma |
|--------|--------|
| `pt-br` | Português (Brasil) |
| `pt-pt` | Português (Portugal) |
| `en-us` | English (US) |
| `en-gb` | English (GB) |
| `es-es` | Español (España) |
| `es-mx` | Español (México) |
| `fr` | Français |
| `de` | Deutsch |
| `it` | Italiano |
| `ja-jp` | 日本語 |
| `zh-cn` | 简体中文 |

### Estrutura de Conteúdo com i18n

```
content/
├── pt-br/
│   └── teams/{team-id}/*
├── en-us/
│   └── teams/{team-id}/*
└── es-es/
    └── teams/{team-id}/*

i18n/
├── pt-br.yaml    ← Traduções
├── en-us.yaml    ← Traduções
└── es-es.yaml    ← Traduções
```

### Comandos Claude com i18n

Os comandos `/doc-pr`, `/doc-feature` e `/doc-module` geram automaticamente em **todos os idiomas**:

```bash
# Gera em pt-br e en-us (se configurados)
/doc-pr 142

# Ou especificar idiomas
/doc-pr 142 --languages pt-br,en-us
/doc-feature pix-support --languages pt-br
/doc-module src/payments --languages en-us
```

Resultado:
```
content/pt-br/teams/team-payments/technical/pr-142-*.md
content/en-us/teams/team-payments/technical/pr-142-*.md
```

### Adicionar Novo Idioma

1. **Criar arquivo de tradução:**
   ```bash
   cp i18n/pt-br.yaml i18n/es-es.yaml
   # Editar e traduzir strings
   ```

2. **Atualizar `.env`:**
   ```bash
   SUPPORTED_LANGUAGES="pt-br,en-us,es-es"
   ```

3. **Rodar configuração:**
   ```bash
   python3 scripts/manage-i18n.py
   ```

### Documentação Completa

Para configuração avançada, tradução de templates e mais:
👉 **[I18N.md](./I18N.md)** — Guia detalhado de internacionalização

---

## Adicionar um novo time

```bash
# Básico — apenas cria dados e conteúdo local
bash scripts/register-team.sh --id team-xyz --name "Time XYZ" [--slack "#team-xyz"]

# Com PR automático (requer Git)
bash scripts/register-team.sh --id team-xyz --name "Time XYZ" --pr
# Se Git não estiver disponível, a flag será ignorada com aviso
```

**Parâmetros:**
- `--id` *(obrigatório)* — identificador único (ex: `team-payments`)
- `--name` *(obrigatório)* — nome de exibição (ex: `Payments`)
- `--slack` *(opcional)* — canal Slack (ex: `#team-payments`)
- `--repos` *(opcional)* — repositórios associados, separados por vírgula
- `--doc-types` *(opcional)* — tipos de doc (padrão: `technical,product,faq`)
- `--pr` *(opcional)* — abre PR automaticamente (requer Git e GitHub CLI)

## Gerar documentação com Claude

### ✨ Modo simplificado (recomendado) — Skills

As skills integradas no Claude Code permitem gerar documentação com um comando:

```bash
/doc-pr 142              # Documentação de um PR
/doc-feature pix-support # Documentação de uma feature
/doc-module src/payments # Documentação de um módulo
```

**O que as skills fazem:**
- ✅ Detectam projeto/time automaticamente
- ✅ Fazem perguntas apenas quando necessário
- ✅ Geram documentação técnica, produto e FAQ
- ✅ **Geram em TODOS os idiomas suportados** (i18n)
- ✅ Oferecem abrir PR automaticamente

#### 🔧 Como usar em outro repositório

As skills estão disponíveis **automaticamente** quando você abre o Claude Code em qualquer repositório, desde que o **DocHub esteja clonado** na sua máquina.

**Pré-requisito:** Clone o DocHub em um local acessível:
```bash
git clone https://github.com/carolinevsboliveira/hugo-doc-hub.git ~/projects/hugo-doc-hub
# Ou em qualquer outro local que preferir
```

**Depois, ao abrir outro repositório no Claude Code:**
1. Os comandos `/doc-pr`, `/doc-feature` e `/doc-module` estarão disponíveis
2. As skills funcionam normalmente, independente do repositório
3. A documentação gerada é salva no repositório DocHub (conforme configuração de `--team` e `--output`)

**Exemplo em outro repositório:**
```bash
# Abrir outro repositório no Claude Code
cd ~/projects/meu-app

# Usar os comandos do DocHub
/doc-pr 142              # Gera docs no DocHub para o PR #142
/doc-feature pix-support # Gera docs de feature
/doc-module src/payments # Gera docs de módulo
```

#### Exemplos com opções

```bash
# Gera em pt-br e en-us (se SUPPORTED_LANGUAGES="pt-br,en-us")
/doc-pr 142

# Especificar idiomas (padrão: todos do SUPPORTED_LANGUAGES)
/doc-pr 142 --languages pt-br,en-us
/doc-feature pix-support --languages pt-br
/doc-module src/payments --languages en-us

# Especificar time e projeto
/doc-pr 142 --team team-payments --project api-payments
```

### Modo avançado (Python direto)

Para uso programático ou CI/CD:

```bash
export LANGUAGE_CODE="pt-br"
export SUPPORTED_LANGUAGES="pt-br,en-us"

python scripts/generate-docs.py \
  --context context.json \
  --doc-types "technical,product,faq" \
  --project "api-payments" \
  --team "team-payments" \
  --output "content" \
  --pr
```

Gera automaticamente em `content/{lang}/teams/team-payments/...` para cada idioma.

**Contexto JSON:**
```json
{
  "pr_number": "123",
  "pr_title": "Titulo",
  "pr_body": "Descrição",
  "changed_files": ["src/file.ts"],
  "diff_summary": "Resumo",
  "readme": "README (opcional)",
  "tags": []
}
```

**Parâmetros:**
- `--context` — arquivo JSON
- `--doc-types` — tipos (ex: `technical,product,faq`)
- `--project` — nome do projeto
- `--team` — ID do time
- `--output` — diretório de saída (gera content/{lang}/...)
- `--pr` *(opcional)* — abre PR (requer Git e GitHub CLI)

**Variáveis de ambiente:**
- `LANGUAGE_CODE` — idioma principal (padrão: `pt-br`)
- `SUPPORTED_LANGUAGES` — idiomas suportados (padrão: `pt-br`)
- `ANTHROPIC_API_KEY` — API key do Claude (obrigatório)

**Requer:** `ANTHROPIC_API_KEY`

## Estrutura de conteúdo

Com i18n habilitado:

```
content/
├── pt-br/
│   └── teams/{team-id}/
│       ├── _index.md
│       ├── technical/   ← docs técnicas (por PR ou módulo)
│       ├── product/     ← docs de produto (por feature)
│       └── faq/         ← perguntas frequentes
├── en-us/
│   └── teams/{team-id}/
│       ├── _index.md
│       ├── technical/
│       ├── product/
│       └── faq/
└── es-es/
    └── teams/{team-id}/
        └── ...
```

## Frontmatter obrigatório

```yaml
---
title: ""
date: 2025-01-01T00:00:00-03:00
team: "team-id"
project: "nome-do-projeto"
doc_type: "technical | product | faq"
scope: "pr | feature | module"
language: "pt-br"  # Campo de idioma (adicionado automaticamente)
draft: false
---
```

**Nota:** O campo `language` é adicionado automaticamente pelos comandos Claude.

## Instalação de ferramentas

### Instalar Python e dependências

```bash
# Verificar se Python 3.8+ está instalado
python3 --version

# Instalar PyYAML (obrigatório)
pip install pyyaml
```

### Instalar Hugo extended

**macOS (Homebrew):**
```bash
brew install hugo
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install hugo
```

**Windows:**
```bash
choco install hugo-extended
# Ou: scoop install hugo-extended
```

[Mais opções →](https://gohugo.io/installation/)

### Instalar GitHub CLI (opcional, recomendado)

Necessário apenas se usar `--pr` para abrir PRs automaticamente.

```bash
# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Windows
choco install gh
```

[Mais opções →](https://cli.github.com/)

### Configurar ANTHROPIC_API_KEY

Necessário para usar as skills `/doc-pr`, `/doc-feature`, `/doc-module`:

```bash
# 1. Crie uma API key em https://console.anthropic.com/keys
# 2. Configure no seu ambiente:
export ANTHROPIC_API_KEY="sk-ant-..."

# Ou adicione ao .env (se estiver usando dotenv):
echo "ANTHROPIC_API_KEY=sk-ant-..." >> .env
```

### Proteções automáticas

O DocHub detecta automaticamente quais ferramentas estão disponíveis:

- ✅ **Sem Git**: Funcionalidades de versionamento não são oferecidas
- ✅ **Git sem gh**: Mensagem clara com instruções para instalar
- ✅ **Com ambos**: PRs abrem automaticamente com `--pr`
- ✅ **Sem ANTHROPIC_API_KEY**: Skills do Claude desabilitadas com aviso claro

### Como usar os comandos em outros repositórios

Para que as skills `/doc-pr`, `/doc-feature` e `/doc-module` funcionem em **qualquer repositório**, o DocHub deve estar disponível localmente.

**Opção 1: Clone global (recomendado)**

```bash
# Clone uma vez em um local fixo
git clone https://github.com/carolinevsboliveira/hugo-doc-hub.git ~/projects/hugo-doc-hub

# Agora os comandos /doc-* funcionam em qualquer repositório
cd ~/projects/meu-outro-app
/doc-pr 123
```

**Opção 2: Abra o DocHub no Claude Code**

Abra o repositório DocHub primeiro no Claude Code, e as skills estarão disponíveis para usar em outros repositórios também.

**Opção 3: Configure um alias (avançado)**

Para usar com projeto específico, configure no `.env` do seu repositório:
```bash
export DOCHUB_PATH="~/projects/hugo-doc-hub"
export DOCHUB_TEAM="seu-time"
export DOCHUB_LANGUAGES="pt-br,en-us"
```

### Scripts de i18n

Disponíveis em `scripts/`:
- **`manage-i18n.py`** — Atualiza configuração de idiomas no Hugo
- **`i18n_utils.py`** — Módulo Python para gerenciar i18n em scripts
- **`configure-i18n.sh`** — Gera blocos de configuração TOML

## Deploy

Push para `main` dispara o build e deploy automático via GitHub Actions + Netlify.

## Secrets necessários

| Secret | Descrição |
|--------|-----------|
| `NETLIFY_AUTH_TOKEN` | Token de autenticação Netlify |
| `NETLIFY_SITE_ID` | ID do site no Netlify |
