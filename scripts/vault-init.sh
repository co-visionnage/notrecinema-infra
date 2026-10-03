#!/usr/bin/env bash
# Создаёт зашифрованное хранилище секретов ansible/group_vars/all/vault.yml.
#
# 1. Если нет файла с паролем хранилища (по умолчанию
#    ~/.ansible/notrecinema-vault-pass), генерирует его.
# 2. Если нет vault.yml, создаёт его со случайными секретами и шифрует.
#
# Секреты на экран не выводятся. Посмотреть/изменить: scripts/vault-edit.sh.
# Пароль хранилища сохраните в менеджере паролей: без него vault.yml не открыть.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
pass_file="${ANSIBLE_VAULT_PASSWORD_FILE:-$HOME/.ansible/notrecinema-vault-pass}"
vault_file="$root/ansible/group_vars/all/vault.yml"

command -v ansible-vault >/dev/null || { echo "ansible-vault не найден: scripts/install-ansible.sh" >&2; exit 1; }
command -v openssl >/dev/null || { echo "нужен openssl" >&2; exit 1; }

if [ ! -f "$pass_file" ]; then
  mkdir -p "$(dirname "$pass_file")"
  umask 077
  openssl rand -base64 48 | tr -d '\n' >"$pass_file"
  echo "Создан пароль хранилища: $pass_file"
  echo "СОХРАНИТЕ его содержимое в менеджере паролей."
fi

if [ -f "$vault_file" ]; then
  echo "$vault_file уже существует, ничего не меняю."
  exit 0
fi

mkdir -p "$(dirname "$vault_file")"
umask 077
cat >"$vault_file" <<YAML
---
# Секреты. Файл зашифрован ansible-vault; правка: scripts/vault-edit.sh
# Имена с префиксом vault_ подставляются в group_vars/all.yml.
vault_grafana_admin_password: "$(openssl rand -base64 24 | tr -d '/+=\n')"
YAML
ansible-vault encrypt --vault-password-file "$pass_file" "$vault_file"

echo
echo "Готово: $vault_file (зашифрован, его можно коммитить)."
echo "Дальше в ansible/group_vars/all.yml:"
echo '  grafana_admin_password: "{{ vault_grafana_admin_password }}"'
echo "и перед запуском плейбука:"
echo "  export ANSIBLE_VAULT_PASSWORD_FILE=$pass_file"
