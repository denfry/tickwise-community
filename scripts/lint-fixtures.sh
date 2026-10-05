#!/usr/bin/env bash
# Privacy lint for fixtures and signatures: fails when a file contains something that looks like personal
# data. It is a safety net, not a replacement for reading your own fixture before you commit it.
#
#   bash scripts/lint-fixtures.sh            # whole kb/
#   bash scripts/lint-fixtures.sh kb/fixtures/SIG-XX-001   # one directory or file
set -u

target=("${@:-kb}")
status=0

fail() {
  echo "::error file=$1,line=$2::$3"
  echo "  $1:$2: $3"
  status=1
}

# 1. IPv4 addresses outside private and documentation ranges (a real address of a server or a player).
#    Allowed: 0.0.0.0, 127.x, 10.x, 192.168.x, 172.16-31.x and the documentation ranges 192.0.2/198.51.100/203.0.113.
#    A version such as v5.2.6.2 is not an address: matches glued to a letter, digit or dot are skipped.
while IFS=: read -r file line match; do
  ip="${match%%[^0-9.]*}"
  case "$ip" in
    0.0.0.0 | 127.* | 10.* | 192.168.* | 192.0.2.* | 198.51.100.* | 203.0.113.*) continue ;;
    172.1[6-9].* | 172.2[0-9].* | 172.3[01].*) continue ;;
  esac
  fail "$file" "$line" "real-looking IP address $ip: replace it with 203.0.113.x (documentation range) or 10.0.0.x"
done < <(grep -rHnoE '(^|[^0-9.A-Za-z])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9.]|$)' "${target[@]}" 2>/dev/null |
  sed -E 's/^([^:]+):([0-9]+):[^0-9]*/\1:\2:/')

# 2. E-mail addresses (except example domains).
while IFS=: read -r file line match; do
  case "$match" in *@example.* | *@*.example | *@localhost*) continue ;; esac
  fail "$file" "$line" "e-mail address $match: remove it or use user@example.com"
done < <(grep -rHnoE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "${target[@]}" 2>/dev/null)

# 3. Secrets: key=value pairs with a value that is not an obvious placeholder, long tokens, private keys.
while IFS=: read -r file line _; do
  fail "$file" "$line" "possible secret (password/token/key with a value): replace the value with <redacted>"
done < <(grep -rHnEi '(password|passwd|secret|token|api[_-]?key|apikey)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9+/_-]{8,}' "${target[@]}" 2>/dev/null |
  grep -viE 'using password: (yes|no)|<[a-z_:]+>|<redacted>|change-me|example|xxxx|\*\*\*\*' || true)

while IFS=: read -r file line _; do
  fail "$file" "$line" "private key material"
done < <(grep -rHnE -- '-----BEGIN [A-Z ]*PRIVATE KEY-----' "${target[@]}" 2>/dev/null || true)

while IFS=: read -r file line _; do
  fail "$file" "$line" "Discord/Telegram/GitHub token"
done < <(grep -rHnE '(ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|[0-9]{8,10}:[A-Za-z0-9_-]{35}|[MN][A-Za-z0-9_-]{23,25}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27,})' "${target[@]}" 2>/dev/null || true)

if [ "$status" -ne 0 ]; then
  echo
  echo "Privacy lint failed. Fixtures must be sanitized: see CONTRIBUTING.md, section 'Real logs and privacy'."
else
  echo "Privacy lint passed."
fi
exit "$status"
