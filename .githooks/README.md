# Hooks

Versionados aqui em vez de `.git/hooks` para virem junto com o clone.

Ative uma vez por clone:

```sh
git config core.hooksPath .githooks
```

O `pre-commit` roda formatação, análise estática e a suíte de testes — a
mesma coisa que a CI faz, só que antes de você empurrar. Leva alguns
segundos. Para pular num commit pontual, `git commit --no-verify`.
