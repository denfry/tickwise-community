# Writing signatures

The reference for the format of signatures and fixtures, and for the checks they must pass. For a step-by-step guide to your first contribution read [CONTRIBUTING.md](../CONTRIBUTING.md). A file template is in [`templates/signature.yml`](templates/signature.yml).

🇷🇺 [Русская версия](writing-signatures.ru.md)

A signature is a declarative rule: RE2 regular expressions and predicates, plus the text of the cause and the fix. The Tickwise agent runs signatures locally; the cloud takes the title, the cause and the steps from the signed pack for incident cards. A signature **cannot run code**, it is data only.

## 1. Layout

```
kb/
  signatures/<category>/SIG-XX-000.yml     one signature per file
  fixtures/SIG-XX-000/pos-*.log, neg-*.log fixtures
  config-schema.yml                         allowlist of config keys (maintainers change it)
  pack.yml                                  pack metadata (maintainers only)
```

The built and signed pack (`kb/dist/`) lives in Tickwise's private repository. The signature is made offline on the maintainer's machine, so a pull request never touches it.

## 2. The `kb-tools` command line

Download `kb-tools.zip` from the [`tools` release](../../../releases/tag/tools) and unzip it. Java 21 is required. Run `kb-tools-<version>/bin/kb-tools <command> [--option value]...` (`kb-tools.bat` on Windows). Every option needs a value: there are no bare flags.

| Command | What it does |
|---|---|
| `validate --kb kb` | schema and RE2 of every signature, at least 3 positive and 3 negative fixtures |
| `test --kb kb` | `validate`, then runs every fixture through the real agent pipeline and computes precision. **CI runs this command** |
| `sanitize --in <file> --out <file> [--grep <text>] [--context 30]` | a sanitized log fragment for a fixture (see section 7) |
| `corpus --kb kb --dir <dir> [--examples 3] [--signature <ID>]` | shows what fires on your own logs (`.log`, `.log.gz`, `.txt`): the way to check precision on real data |

## 3. Signature format

File: `kb/signatures/<category>/<id>.yml`; the file name must equal the `id`. Example: [`kb/signatures/database/SIG-DB-001.yml`](../kb/signatures/database/SIG-DB-001.yml).

| Field | Req. | Rules |
|---|---|---|
| `id` | yes | `SIG-[A-Z]{2,4}-\d{3}`, unique |
| `version` | yes | integer; increase it when the logic or the text changes |
| `title` | yes | up to 256 characters |
| `category` | yes | up to 32 characters; today `auth`, `database`, `disk`, `memory`, `network`, `performance`, `plugin`, `startup`, `velocity`, `world` |
| `severity` | yes | `info`, `warning`, `error` or `critical`. For `error` and `critical` the agent sends a diagnosis right away |
| `scope` | | `server` (default) or `network` |
| `platforms` | yes | a list of `paper`, `purpur`, `velocity`; on other platforms the signature is not checked. The first one is the default platform of the fixtures |
| `rule_ref` | | an internal Tickwise rule code (up to 16). Contributors leave it empty |
| `symptoms` | yes | a list of strings |
| `match` | yes | a tree of predicates (section 4); it must contain a log predicate as proof |
| `threshold` | | `{ count: N, window: <number><s\|m\|h\|d> }`: how many matches in the window are needed. One match is enough by default |
| `cause` | yes | the main cause, up to 8192 characters |
| `possible_causes` | | `[{ text, weight }]` |
| `fix` | yes | `instructions_md` (required, Markdown, up to 8192; its first line is shown in `/tickwise diagnose`), `risk` (`low` by default; `low`/`medium`/`high`), `action` which **must be `null`** (Tickwise does not run commands on servers) |
| `confidence` | yes | a number in (0, 1] |
| `verification` | yes | `verified`, `community` or `candidate`. **A new community signature is `candidate`**; a maintainer raises the level after review |
| `last_verified` | | a date |
| `sources` | yes | links to first-party material (source code, issues, documentation); they reach the pack as `references` |
| `tests` | yes | `positive: [...]`, `negative: [...]`: paths to fixtures relative to `kb/`, inside `kb/` |

The YAML is read with a safe loader: duplicate keys are forbidden and there are at most 10 aliases.

## 4. `match` predicates

Every node has exactly one key. The nesting depth is at most 8.

| Predicate | Parameters | True when |
|---|---|---|
| `log` | `regex` (required, RE2, up to 2048), `literal` (a substring pre-filter, up to 256), `level` (minimum level), `target` (`message`, `exception` or `text`, default `text`), `logger` (RE2 on the logger name) | a log event matches |
| `all` | a list | all children are true |
| `any` | a list | at least one child is true |
| `not` | a predicate | the child is false |
| `platform` | `name` (string or list), `versions` (range) | the platform and version match; if the version is unknown, `versions` is not checked |
| `java` | `versions` (required) | the Java version is in the range |
| `plugin` | `name` (required), `versions`, `present` (default `true`) | the plugin is installed (and in the range); with `present: false`, it is not installed |
| `config` | `file`, `key`, `eq` | the key equals `eq`, case-insensitively |

`target` of `log`:

- `message`: the first line of the event;
- `exception`: the lines of the exception chain as `Class: message`;
- `text`: the whole event, including stack trace frames.

`level` accepts `TRACE`, `DEBUG`, `INFO`, `WARN`/`WARNING`, `ERROR`/`SEVERE`, `FATAL`. A typo silently becomes `INFO`. RE2 has no backreferences and no lookaround. Always give a `literal`: RE2 only runs on lines where the literal is found.

**The proof rule.** `match` must "use the log". In `all`, at least one child contains `log`. In `any`, **every** branch contains `log`. `not` is never proof. A signature without proof from the log does not build.

**The `config` limit.** The agent only knows values of keys listed in `kb/config-schema.yml` with `send: value` that are not caught by the secrets denylist (no `pass|secret|token|key|webhook|rcon|auth|credential` in the name). For any other key `config` is always false.

The parser supports `platform`, `java`, `plugin` and `config`, but the current signatures do not use them. A predicate the agent does not know makes the signature invalid for `kb-tools` (the agent would skip it).

### Version ranges

Space or comma separated comparators act as AND: `>=1.21 <1.22`, `=26.2`, `>1.20.4`, `<=3.4`. A prefix: `1.21.x` or `1.21.*`. Any version: `*` or empty. The comparison goes by numeric segments; suffixes such as `-SNAPSHOT` and `+build` are ignored. A version that cannot be parsed never satisfies a range.

## 5. Fixtures

A fixture is a piece of log text in the `latest.log` format with an optional header. The header is the lines `# key: value` at the very start; it ends at the first line that does not start with `# `.

```
# platform: velocity 3.5.1
# java: 21.0.4
# plugins: LuckPerms 5.5.17, Vault 1.7.3
# config: server.properties:online-mode=false
# expect: SIG-DB-002
# source: own-server-sanitized (proxy, 2026-09-20; database host replaced by db.example.net)
[09:20:00] [LuckPerms - Task Executor #34/ERROR] ...
```

| Key | Value | Default |
|---|---|---|
| `platform` | `<name> [version]` | the first platform of the signature; version `1.21.11` (`3.5.1` for `velocity`) |
| `java` | version | `21.0.4` |
| `plugins` | `Name version, Name version` | no plugins |
| `config` | `<file>:<key>=<value>`; there may be several lines | none |
| `expect` | ids of **other** signatures that legitimately fire on this fixture (comma separated) | none |
| `source` | where it came from: `synthetic`, `own-server-sanitized`, `upstream-issue <url>` and so on. Not interpreted, but required for review | none |

Layout: `kb/fixtures/<ID>/pos-<description>.log` and `neg-<description>.log`. One fixture can be positive for one signature and negative for another.

Fixtures go through the same pipeline as in the agent: the parser, stack trace assembly, the sanitizer with a fixed salt, the signature engine. So the regex must match the **sanitized** text: nicknames, IPs and hosts are already replaced in it.

## 6. Quality requirements (`kb-tools test`)

The test passes only when all of this holds:

1. Every signature has at least 3 positive and 3 negative fixtures.
2. Every signature fires on all its positive fixtures.
3. No signature fires on its negative fixtures.
4. Precision over the whole base is at least 0.95. A true match is a signature firing on its own positive fixture or on a fixture where it is named in `# expect:`. A false one is a signature firing on any other fixture (`FALSE-POSITIVE` in the output).
5. The base holds at least 30 signatures (it does today).

The result is a line `signatures=… fixtures=… true_positives=… false_positives=… precision=…` followed by `KB TEST PASSED` or `KB TEST FAILED`.

How to choose negative fixtures: take neighbouring scenarios that are easy to confuse with the target (another cause of the same error, normal INFO lines with the same word, a neighbouring exception type). Those are what catch a regex that is too wide.

## 7. Fixtures from real logs

Allowed sources: logs of **your own** servers, public issues (with the logs of their authors), and synthetic logs assembled from the real message format. Never submit logs from someone else's server without the owner's permission.

```bash
kb-tools sanitize --in /path/latest.log --out kb/fixtures/SIG-XX-000/pos-case.log --grep "Communications link failure" --context 30
```

- The sanitizer first reads the whole file and "learns" nicknames from join and leave lines, then writes ±`context` lines around the first line with `--grep` (the whole file without `--grep`).
- The salt is fixed, so the pseudonyms are reproducible. Chat lines (`Async Chat Thread`, `<nick> …`) are removed.
- Directory mode: `--in <dir> --out <dir>` processes every `.log`/`.gz` with one shared nickname dictionary.
- **Read the result line by line** before you commit. Replace database hosts, domains, paths and project names with `example` values, as the existing fixtures do (see [section 4 of CONTRIBUTING.md](../CONTRIBUTING.md#4-real-logs-and-privacy)).
- Add the header (`# platform`, `# source`, ...) by hand: `sanitize` does not write it.
- CI also runs `scripts/lint-fixtures.sh`, which catches real-looking IP addresses, e-mails and secrets. It is a safety net, not a replacement for your own reading.

## 8. Trust levels (`verification`)

| Level | Meaning | Set by |
|---|---|---|
| `candidate` | a hypothesis or a new signature. Its fixtures run in CI, but it is **not included in the signed pack** and never reaches users | the author of the contribution |
| `community` | accepted after review, the cause is backed by sources, but the positive fixtures may be synthetic | a maintainer |
| `verified` | confirmed on real logs and first-party sources | a maintainer |

For `candidate` the validator requires: every `log` predicate has a `literal` of at least 8 characters, and the anchor is `target: exception`, a `plugin` predicate, or a `literal` of at least 16 characters. A `verified` signature cannot rest on positive fixtures with `synthetic` in the file name.
