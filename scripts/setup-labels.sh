#!/usr/bin/env bash
# Creates (or updates) the labels of this repository. Needs the GitHub CLI and write access:
#   GH_TOKEN=... bash scripts/setup-labels.sh   (or just `gh auth login` once)
set -eu

label() { gh label create "$1" --color "$2" --description "$3" --force; }

label "beta-access"      "0E8A16" "Merged contribution worth access to the closed beta (set by a maintainer)"
label "signature"        "1D76DB" "New or changed error signature"
label "fixture"          "5319E7" "Log fixtures for an existing signature"
label "docs"             "0075CA" "Documentation"
label "needs-sanitizing" "D93F0B" "Logs contain personal data and must be sanitized before review"
label "needs-sources"    "FBCA04" "Please add first-party sources (issue, source code, docs)"
label "new-error"        "C5DEF5" "A real error that has no signature yet"
label "good first issue" "7057FF" "Good for a first contribution"
label "wontfix"          "FFFFFF" "Out of scope"
