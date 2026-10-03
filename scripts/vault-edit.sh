#!/usr/bin/env bash
# Открывает зашифрованный vault.yml в $EDITOR (ansible-vault edit).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
pass_file="${ANSIBLE_VAULT_PASSWORD_FILE:-$HOME/.ansible/notrecinema-vault-pass}"

exec ansible-vault edit --vault-password-file "$pass_file" "$root/ansible/group_vars/all/vault.yml"
