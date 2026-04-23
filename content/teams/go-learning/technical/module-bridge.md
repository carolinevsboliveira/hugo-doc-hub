---
title: "Módulo: Bridge"
date: 2026-04-23
team: "go-learning"
project: "Learning"
doc_type: "technical"
scope: "module"
module_path: "Concepts/Bridge"
tags: []
draft: false
---

## Responsabilidade

Explorar o padrão Bridge em Go — separar hierarquias de abstração de hierarquias de implementação para que ambas possam variar de forma independente. O módulo **não** cobre variantes funcionais nem uso de generics.

## Estrutura

```
Concepts/Bridge/
├── Bridge.go      ← Exemplo canônico: DrawShape/DrawContour com ponte explícita
├── sample-ex.go   ← Exemplo-modelo didático: Renderer (SVG/Console) + Shape/Circle
├── ex-1.go        ← Exercício 1: sistema de notificações (Email/SMS/Push)
├── ex-3.go        ← Exercício 3: renderização de sprites de jogo (Terminal/OpenGL)
└── ex-5.go        ← Exercício 5: autenticação com fallback, rate limiting e goroutines
```

## Entradas e saídas

Não há ponto de entrada executável (`main`). Cada arquivo declara tipos e funções dentro do pacote `Bridge`. A exceção é `ex-5.go`, que expõe `TestImplementation()` — uma função autossuficiente que demonstra o fluxo completo de autenticação e imprime resultados no stdout.

## Dependências internas

Nenhuma. O módulo não importa outros pacotes do projeto.

## Dependências externas

| Pacote       | Uso                                                               |
|--------------|-------------------------------------------------------------------|
| `fmt`        | Impressão de output nas implementações simuladas                  |
| `strconv`    | Conversão de `int` para `string` no ex-3 (HP de inimigo)         |
| `strings`    | Parsing de token JWT simulado no ex-5                             |
| `sync`       | `sync.Mutex` para proteger o map de tentativas no ex-5            |
| `time`       | Delay simulado em goroutines e janela de rate limiting no ex-5    |

Todos são da biblioteca padrão Go — sem dependências externas.

## Fluxo principal

O padrão Bridge é aplicado de três formas progressivamente mais complexas:

### Forma 1 — Referência direta (Bridge.go + sample-ex.go)

```
[Abstração]          [Implementação]
DrawContour  ──────► DrawShape.drawShape()
Circle       ──────► Renderer.RenderCircle() / RenderSquare()
```

A abstração guarda uma referência à interface de implementação. Trocar a implementação é substituir o campo sem alterar a abstração.

### Forma 2 — Composição com enriquecimento (ex-1.go)

```
NotificationSender (interface)
    ├── EmailSender
    ├── SMSSender
    └── PushSender

Notification (abstração base)
    ├── UrgentNotification  → prefixo "[URGENTE]" no subject
    └── ScheduledNotification → sufixo "[Agendado: <at>]" no body
```

Cada variante da abstração delega para `Notification.Send()`, que por sua vez delega para o `NotificationSender` concreto.

### Forma 3 — Ponte com concorrência e fallback (ex-3.go + ex-5.go)

```
ex-3:
Entity.Backend (RenderBackend)
    ├── TerminalBackend
    └── OpenGLBackend
Player/Enemy ──► Entity.Render() ──► Backend.DrawSprite() + Backend.DrawText()

ex-5:
AuthFlow
    ├── primary   AuthProvider  ──► goroutine → <-chan AuthResult
    └── secondary AuthProvider  ──► goroutine → <-chan AuthResult (fallback)
MFAFlow ──► AuthFlow.Authenticate() + validação de TOTP
```

No ex-5, `AuthFlow.Authenticate` bloqueia nos channels de resultado, verifica rate limit com mutex e tenta o provider secundário se o primário falhar.

## Casos de borda e comportamentos importantes

- **Rate limiting (ex-5):** a janela deslizante é implementada filtrando tentativas mais antigas que `window`. Se `maxRetries` for atingido, o erro retorna imediatamente sem chamar nenhum provider.
- **Fallback assimétrico (ex-5):** cada falha (primária e secundária) adiciona uma entrada ao contador de tentativas do usuário, ou seja, um ciclo completo de fallback consome 2 slots de rate limit.
- **SMS truncado (ex-1):** `SMSSender` silenciosamente corta o body em 50 caracteres sem sinalizar ao caller.
- **Substituição de backend em runtime (sample-ex.go):** o campo `renderer` em `Shape` é exportável via embed, permitindo troca em runtime sem recriar a abstração — o comentário no arquivo demonstra isso explicitamente.
- **`ResizeByFactor` em Bridge.go:** o método opera sobre um receiver por valor, então o campo `Factor` nunca é persistido na struct original — efeito colateral silencioso.

## Como estender

1. **Novo canal de notificação (ex-1):** implemente `NotificationSender` e injete no campo `Sender` de `Notification`. Nenhum código das abstrações precisa mudar.
2. **Novo backend de renderização (ex-3):** implemente `RenderBackend` e passe-o ao construir `Entity`/`Player`/`Enemy`.
3. **Novo provider de autenticação (ex-5):** implemente `AuthProvider` (dois métodos: `Authenticate` e `Name`) e passe como `primary` ou `secondary` em `AuthFlow`.
4. **Nova abstração de auth:** embute `*AuthFlow` na nova struct e sobrescreve `Authenticate` para adicionar lógica antes/depois da delegação (padrão seguido por `MFAFlow`).

Convenção do módulo: a implementação é injetada por campo (composição), não por construtor dedicado.

## Testes

Não há arquivos `_test.go` no módulo. A verificação é feita manualmente via `TestImplementation()` em `ex-5.go` e pelos blocos `main` comentados nos demais arquivos.

Para exercitar localmente:

```bash
# descomente o bloco main desejado e execute
cd "Concepts/Bridge"
go run .
```

O que está coberto informalmente: happy path de autenticação, fallback JWT, rate limiting, MFA com e sem segundo fator. O que não está coberto: timeouts, cancelamento de context, concorrência sob alta carga.

## Histórico relevante

Os arquivos seguem uma progressão pedagógica: `Bridge.go` → `sample-ex.go` introduzem o padrão; `ex-1`, `ex-3` e `ex-5` aplicam em domínios reais com crescente complexidade. O exercício 5 introduz goroutines e mutex deliberadamente para mostrar que a ponte pode encapsular complexidade assíncrona sem expô-la à abstração.
