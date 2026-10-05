# Contributing to Tickwise Community

🇷🇺 [По-русски](CONTRIBUTING.ru.md)

Thank you for helping. This guide takes you from "I saw an error" to "my pull request is merged" and tells you what happens next. If something here is unclear, that is a bug in this guide: please open an issue.

**Contents**

1. [Pick a kind of contribution](#1-pick-a-kind-of-contribution)
2. [The 5-minute way: report an error](#2-the-5-minute-way-report-an-error)
3. [Write a signature, step by step](#3-write-a-signature-step-by-step)
4. [Real logs and privacy](#4-real-logs-and-privacy)
5. [Open the pull request](#5-open-the-pull-request)
6. [What reviewers look at](#6-what-reviewers-look-at)
7. [What earns beta access](#7-what-earns-beta-access)
8. [After your PR is merged](#8-after-your-pr-is-merged)
9. [Troubleshooting](#9-troubleshooting)
10. [Rules](#10-rules)

## 1. Pick a kind of contribution

| I want to... | Do this |
|---|---|
| tell you about an error and how I fixed it | [open an issue](../../issues/new?template=new-error.yml), see [section 2](#2-the-5-minute-way-report-an-error) |
| say that a signature fires when it should not | [open an issue](../../issues/new?template=signature-problem.yml), better: add a negative fixture in a pull request |
| write a new signature | [section 3](#3-write-a-signature-step-by-step) |
| add fixtures to an existing signature | put the logs in `kb/fixtures/SIG-XX-000/` and list them under `tests:` of that signature |
| improve the text of a signature | edit the YAML, increase `version` by 1 |
| fix documentation | edit the file and open a pull request |

You do **not** have to write signatures to help: a good issue with a sanitized log and a source that explains the error is already half of the work, and a maintainer can finish it.

**Language.** Signature text (`title`, `symptoms`, `cause`, `fix`) is shown to server owners in the bot, which is Russian today. Write it in Russian or in English; maintainers translate. Issues and pull requests can be in either language.

## 2. The 5-minute way: report an error

Use the [new error form](../../issues/new?template=new-error.yml). It asks for the platform, the plugin, a sanitized log fragment, and the cause if you know it. The best proof of a cause is a link: the plugin's source code, an upstream issue, or the official documentation.

## 3. Write a signature, step by step

You need Java 21, Git, and a text editor. Download the validator once:

```bash
# from the "tools" release of this repository
unzip kb-tools.zip          # gives kb-tools-<version>/bin/kb-tools (kb-tools.bat on Windows)
```

### Step 1. Understand the error

Find out why it happens. Look for **first-party** sources: the plugin's source code where the message is printed, an upstream issue, the server software documentation. You will list them under `sources:`. A signature without sources will not be merged: "it worked for me" is a hint, not a proof.

### Step 2. Get a log and sanitize it

Take the fragment of `latest.log` with the error: the line, its stack trace, and about 10 to 30 lines around it. Then **remove personal data** (section 4). The validator can do most of it for you:

```bash
kb-tools sanitize --in latest.log --out kb/fixtures/SIG-DB-099/pos-my-case.log \
  --grep "Communications link failure" --context 30
```

and you read the result yourself afterwards.

### Step 3. Choose the id and the category

The id is `SIG-<PREFIX>-<number>`, and the file lives in the matching category folder:

| Category (folder) | Prefix | What goes there |
|---|---|---|
| `auth` | `AU` | player authentication, Mojang session, forwarding secrets |
| `database` | `DB` | MySQL/MariaDB/Redis connections, pools, grants |
| `disk` | `DI` | disk space, I/O errors, permissions |
| `memory` | `MEM` | OutOfMemory, GC, heap, native memory |
| `network` | `NW` | ports, DNS, TLS, timeouts between servers |
| `performance` | `PA` | lag, tick time, watchdog |
| `plugin` | `PL` | plugin failed to load or enable, dependencies, API versions |
| `startup` | `ST` | the server does not start, Java version, flags |
| `velocity` | `VE` | the proxy and its backends |
| `world` | `WO` | world, chunks, region files, datapacks |

Take the next free number in the category (look at the folder). If two people take the same number, a maintainer renumbers one of them while merging; do not worry about it.

### Step 4. Write the signature file

Copy [`docs/templates/signature.yml`](docs/templates/signature.yml) to `kb/signatures/<category>/SIG-XX-NNN.yml` (the file name must equal the `id`) and fill it in. The key rules:

- **`verification: candidate`** for a new signature. Maintainers raise it after review.
- **`match` needs proof from the log.** At least one `log` predicate. Give every `log` predicate a `literal` of 8 or more characters: it is a fast pre-filter, the regex only runs on lines that contain it.
- **Be specific.** Anchor the regex on the exception class, the plugin name, or a 16+ character literal. "Error" or "Exception" alone would fire on half the internet.
- **`action: null`.** Tickwise does not run commands on servers; a signature only explains and advises.
- **`fix.instructions_md`** is numbered steps a tired admin can follow at 3 a.m. The first line is shown in short form, so make it count. Never ask the reader to paste a whole config: it may hold passwords.
- **`sources`** are the links from Step 1.

The complete field reference is in [docs/writing-signatures.md](docs/writing-signatures.md).

### Step 5. Write the fixtures

For every signature you need **at least three positive and three negative** fixtures, in `kb/fixtures/<ID>/`:

- `pos-<description>.log`: the signature **must** fire. Vary what you can: another plugin, another platform (Paper and Velocity), another driver, another wording of the same error.
- `neg-<description>.log`: the signature **must stay silent**. The most useful negatives are *look-alikes*: the same word in a normal INFO line, another cause of a similar error, a neighbouring exception type. They are what catches a regex that is too wide.

Start each fixture with a header and name its origin honestly:

```
# platform: paper 1.21.11
# plugins: LuckPerms 5.5.17
# source: my own server, sanitized (2026-10-04)
[09:20:00] [ForkJoinPool.commonPool-worker-3/WARN]: ...
```

`source:` is `synthetic` (you made the log by hand from a real message format), `upstream-issue <url>`, or a description of your own server. Synthetic fixtures are fine, but a signature that rests only on synthetic positives stays at `community` at best.

### Step 6. Test

```bash
kb-tools/bin/kb-tools test --kb kb
bash scripts/lint-fixtures.sh
```

You want `KB TEST PASSED` and `Privacy lint passed.` The test runs **every** signature against **every** fixture in the repository, so it also tells you if your signature fires on someone else's log, or if their signature fires on yours. Fix it by making your regex more specific or by adding the right line to the `# expect:` header of the fixture (only if both signatures really should fire).

## 4. Real logs and privacy

A log is full of things that must not be published. Before a log becomes a fixture, **you** must remove:

| Remove | Replace with |
|---|---|
| player names and UUIDs | `Player`, `Steve`, `00000000-0000-0000-0000-000000000000` |
| IP addresses (players, your server, your database) | `203.0.113.5` (documentation range) or `10.0.0.5` |
| your domain names and hosts | `db.example.net`, `play.example.com` |
| e-mails | `user@example.com` |
| passwords, tokens, keys, webhooks, RCON | delete the value or write `<redacted>` |
| absolute paths with your user name | `/home/minecraft/...` |
| chat messages of players | delete the lines |

`kb-tools sanitize` does most of this, and the CI privacy lint catches the common leaks (real-looking IP addresses, e-mails, secrets). It is a safety net. **It is not a guarantee**, so read your fixture line by line. If you find a leaked name after merging, tell us in a private message and we will rewrite the history.

Use only logs from servers **you own or administer**, or public issues with the owner's logs. Never submit logs from another person's server without their permission.

## 5. Open the pull request

1. Fork the repository and create a branch: `signature/db-pool-timeout` or `fixtures/sig-db-001`.
2. Commit: one logical change per pull request is easiest to review. A message like `signature: SIG-DB-099 Hikari pool timeout` is perfect.
3. Do **not** touch `kb/pack.yml` and do not add `kb/dist/`: they belong to the maintainers because the pack is signed.
4. Open the pull request and fill in the template.
5. CI runs two checks: the privacy lint and the full fixture test. Fix red checks in the same branch; the PR updates itself.

## 6. What reviewers look at

- **Is the cause right,** and is it proven by a first-party source?
- **Is the signature narrow enough?** We look at the regex and at your negatives.
- **Are the fixtures honest** and sanitized, and do they cover different variants?
- **Is the advice safe and useful?** Steps that risk data loss, or that need a `chmod 777`, are rejected.
- **Is the text clear** for a non-expert?

Expect comments: they are normal and mean someone is reading. We try to answer within a few days.

## 7. What earns beta access

A maintainer adds the **`beta-access`** label when merging a contribution that makes Tickwise better. As a guide, these usually earn it:

- a new signature with 3+3 fixtures, first-party sources, and a real, recurring error;
- a fix of a false positive or false negative together with the fixtures that prove it;
- a set of several useful fixtures that expose real gaps in existing signatures;
- a substantial documentation improvement or translation.

These are welcome and merged, but usually **do not** earn the label on their own: typo and formatting fixes, whitespace, renames, duplicates of existing signatures, and changes without tests or sources. Unchecked machine-generated pull requests are closed. Using an assistant is fine if you verified the cause, the sources and the fixtures yourself.

The final decision is the maintainer's. If your pull request was merged without the label and you think it should have it, ask politely in the comments.

One GitHub account gets one grant, and one messenger account holds one grant. Access is personal and not transferable, and it can be revoked for abuse. It comes without an SLA: the beta is a beta.

## 8. After your PR is merged

If the PR got the `beta-access` label, claim access in the Tickwise bot:

1. `/beta github` (Discord: `/tickwise beta github`). The bot shows a link and a code.
2. Open the link, enter the code, and confirm in GitHub. **No permissions are requested.**
3. `/beta check`. The bot confirms and you can link servers with `/link`.

The code is valid for 15 minutes; if it expires, start again. Tickwise reads your GitHub account id and login, looks for your merged labelled pull request in this repository, and forgets the GitHub token right away.

Your signature goes to users in the next **signed pack**, after a maintainer moves it to the private repository and signs the build. This can take a few days.

## 9. Troubleshooting

| Problem | What to do |
|---|---|
| `Privacy lint failed` | read the listed lines; replace IPs, e-mails, secrets as in section 4 |
| `precision` is lower than required, or `FALSE-POSITIVE` is printed | your signature fires on a log it should not, or another signature fires on your fixture. Narrow the regex, add a `literal`, or add `# expect:` if both are right |
| `signature X has fewer than 3 positive/negative fixtures` | add more fixtures and list them under `tests:` |
| `no log predicate` / "proof" error | the `match` tree needs a `log` predicate that must be true. A `not` does not count as proof |
| the regex is "invalid" | the engine is RE2: no backreferences, no lookahead or lookbehind |
| the fixture does not match although the log looks right | the validator matches the **sanitized** text: nicknames, IPs and hosts are already replaced by placeholders such as `<ip:1a2b3c4d>` or `<secret:high_entropy>` |
| `/beta check` says "no merged pull request with the label" | the PR is not merged, has no `beta-access` label yet, or was opened from another GitHub account |
| something else | open an issue; we will help |

## 10. Rules

- Be kind. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
- You must have the right to submit what you submit. By opening a pull request you agree that it is published under the repository [license](LICENSE).
- Security problems: [SECURITY.md](SECURITY.md), not a public issue.
