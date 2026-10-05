# Tickwise Community

**Help Minecraft server admins fix errors faster, and get early access to the Tickwise closed beta.**

🇷🇺 [Читать по-русски](README.ru.md)

[![Discord](https://img.shields.io/badge/Discord-Join%20the%20community-5865F2?logo=discord&logoColor=white)](https://discord.gg/mVZcNUAGZt)

[Tickwise](https://tickwise.politernal.ru) is a diagnostics assistant for Minecraft servers and networks (Paper, Purpur, Velocity). A small plugin reads the server log, recognises known problems **locally** using a signed knowledge base, and, once the owner links the server, sends sanitized data to the cloud. The cloud turns it into one clear message in Telegram or Discord: what broke, why, and what to do.

The quality of that message depends on the knowledge base: **error signatures**. This repository is where the community writes them.

> Tickwise is in **closed beta**. A merged contribution here is one of the ways in, see [Get beta access](#get-beta-access).
>
> NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.

## What is a signature?

A signature is a small declarative rule (a YAML file): *"if the log contains this error, the cause is X and the fix is Y"*. There is no code in it, only regular expressions, conditions, and the text a server owner will read.

```yaml
id: SIG-DB-001
title: "Database unreachable (MySQL: Communications link failure / MariaDB: Socket fail to connect)"
match:
  log:
    regex: 'Socket fail to connect to \S+'
    literal: "Socket fail to connect to"
cause: "The JDBC driver could not open a TCP connection to the database server: ..."
fix:
  instructions_md: |
    1. Look at the tail of the message in the evidence: `Connection refused` means nobody listens on that address ...
```

Each signature is proven by **log fixtures**: at least three logs where it must fire and three similar-looking logs where it must stay silent. A test runs all of them on every pull request, so a wrong signature cannot be merged.

Today the base has **42 signatures and 280 fixtures**: databases, plugins, memory, performance, startup, Velocity forwarding and more. Look at [`kb/signatures/`](kb/signatures) for real examples.

## How you can help

| Contribution | Effort | Great for |
|---|---|---|
| **Report an error with no signature** ([new error form](../../issues/new?template=new-error.yml)) | 5 minutes | anyone who saw an error and found the fix |
| **Add fixtures** to an existing signature | 15 minutes | finding logs where a signature wrongly fires, or misses |
| **Write a new signature** | 1-3 hours | plugin authors, admins who solved a nasty problem |
| **Improve the wording or the steps** of a signature | 10 minutes | anyone who tried the fix and knows a better way |
| **Fix the documentation** | any | anyone who got stuck while reading it |

Start with [CONTRIBUTING.md](CONTRIBUTING.md). The full format of a signature is in [docs/writing-signatures.md](docs/writing-signatures.md).

## Get beta access

Tickwise is in a closed beta. You can come in through any of these doors:

1. **Contribute.** Open a pull request here. When a maintainer merges it **and adds the `beta-access` label**, your GitHub account is the key:
   1. In the Tickwise bot send `/beta github` (Discord: `/tickwise beta github`).
   2. Open the link, enter the code shown by the bot, and confirm. GitHub asks for **no permissions**: Tickwise only reads your account id and login.
   3. Send `/beta check` in the bot. Done: you can link your servers.
2. **Invite code.** If a maintainer gave you a code like `TW-XXXX-XXXX`, send `/beta code TW-XXXX-XXXX`.
3. **Ask.** Not everyone writes code. Tell us about your server on the website.

Not every merged pull request gets the label: a fixed typo is very welcome and merged, but the label is for a contribution that makes Tickwise better, for example a verified signature with fixtures. The details are in [CONTRIBUTING.md](CONTRIBUTING.md#7-what-earns-beta-access).

## What happens to your contribution

1. You open a pull request. A robot checks the format, runs every fixture, and looks for personal data.
2. A maintainer reviews it. We check the cause, the sources, and that the signature is not too broad.
3. After merging, a maintainer moves the accepted files into the private Tickwise repository, bumps the version, builds the **Signature Pack** and **signs it offline**.
4. Agents download and verify the signed pack. A signature from this repository **never reaches a server without that review and signature**, and new community signatures start with the lowest trust level (`candidate` / `community`).

So you cannot break anyone's server by contributing, and a pull request alone changes nothing for users.

## Repository layout

| Path | What it is |
|---|---|
| `kb/signatures/<category>/SIG-XX-000.yml` | one signature per file |
| `kb/fixtures/SIG-XX-000/pos-*.log`, `neg-*.log` | log fixtures: must fire / must stay silent |
| `kb/config-schema.yml` | which config keys the agent may read |
| `kb/pack.yml` | pack metadata, **maintainers only** |
| `docs/writing-signatures.md` | the full format and the quality rules |
| `scripts/lint-fixtures.sh` | the privacy lint that CI runs |
| `tools/` | the checksum of the validator that CI downloads |

## Check your work locally

You need Java 21. Download `kb-tools.zip` from the [`tools` release](../../releases/tag/tools), unzip it, and run:

```bash
kb-tools/bin/kb-tools test --kb kb         # on Windows: kb-tools\bin\kb-tools.bat
bash scripts/lint-fixtures.sh              # personal data check
```

You should see `KB TEST PASSED`. CI runs the same two commands.

## License and conduct

Signatures, fixtures and documentation are published under [Creative Commons Attribution 4.0](LICENSE) (CC BY 4.0). You may use and share them, also commercially, if you give credit, for example *"Tickwise Community signatures, https://github.com/denfry/tickwise-community"*. By opening a pull request you agree that your contribution is published under the same license and that Tickwise may include it in its signed Signature Packs. Please follow the [code of conduct](CODE_OF_CONDUCT.md). Found a security problem? See [SECURITY.md](SECURITY.md).
