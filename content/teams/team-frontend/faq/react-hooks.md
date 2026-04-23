---
title: "React Hooks Best Practices"
date: 2025-02-07T10:00:00-03:00
team: "team-frontend"
doc_type: "faq"
draft: false
---

## Q: Quando usar useCallback?

Use quando passa callbacks como deps de outro hook ou memo props.

## Q: Qual a diferença entre useEffect e useLayoutEffect?

useLayoutEffect roda antes de pintar, useEffect depois. Use useLayoutEffect para DOM updates visíveis.

## Q: Como evitar dependency hell?

Mantenha as dependencies mínimas, não inclua objetos/funções criadas inline.
