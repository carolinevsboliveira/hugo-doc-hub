---
title: "Problemas Comuns de Build"
date: 2025-02-03T10:00:00-03:00
team: "team-mobile"
doc_type: "faq"
draft: false
---

## Q: Build falha com "pod install"

Tente limpar cache:
```bash
rm -rf Pods
rm Podfile.lock
pod install
```

## Q: Android Studio não reconhece imports

Faça Invalidate Cache and Restart (File > Invalidate Caches).
