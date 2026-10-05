# Security

## Reporting a problem

Please **do not open a public issue** for a security problem. Use GitHub's private reporting instead: open the **Security** tab of this repository and choose **Report a vulnerability**. We reply as soon as we can, usually within a few days.

Examples of what to report:

- a signature or a fixture that could make the Tickwise agent misbehave (for example a regular expression that is very slow on some input);
- personal data, a secret or a token that slipped into a fixture or into the repository history;
- a flaw in the validation scripts or in the CI workflows of this repository.

For personal data in a fixture, tell us which file and which line. We will remove it and, if needed, rewrite the history.

## What a contribution can and cannot do

A pull request in this repository does not change anything for Tickwise users by itself. Accepted signatures are copied by a maintainer into the private Tickwise repository, built into a **Signature Pack**, and **signed offline** with a key that never leaves the maintainer's machine. Agents verify that signature and refuse a pack that does not match. Signatures contain data only, no code, and they cannot run commands on a server.

The CI workflow runs with a read-only token and no secrets, so it is safe for pull requests from forks. It never uses `pull_request_target`.
