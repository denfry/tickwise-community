<!-- Thanks for contributing! / Спасибо за вклад! Read CONTRIBUTING.md first (CONTRIBUTING.ru.md — по-русски). -->

## What does this change? / Что меняет

<!-- One or two sentences. Which error, which plugin or platform, what the fix is. -->

## Type / Тип

- [ ] New signature / новая сигнатура
- [ ] More fixtures for an existing signature / фикстуры к существующей
- [ ] Fix of an existing signature (false positive / false negative) / исправление
- [ ] Documentation / документация

## Checklist / Чек-лист

- [ ] `kb-tools test --kb kb` prints `KB TEST PASSED` (or CI is green) / проверка проходит
- [ ] Every new signature has **≥ 3 positive and ≥ 3 negative** fixtures / не меньше 3 + 3 фикстур
- [ ] Fixtures contain no real IPs, player names, domains, e-mails, passwords or tokens, and I read them myself / логи очищены и я их прочитал(а)
- [ ] Each fixture has a `# source:` line (synthetic, public issue URL, or my own server) / указан источник
- [ ] `sources:` of the signature link to first-party material (source code, issue, docs) / есть первоисточники
- [ ] I did not touch `kb/pack.yml` or anything signed / не трогал(а) `pack.yml`

## Evidence / Доказательства

<!-- Link to the issue or source code that explains the error, and what you tested on. -->

<!-- Maintainers: add the `beta-access` label when merging if the contribution is worth access to the closed beta. -->
