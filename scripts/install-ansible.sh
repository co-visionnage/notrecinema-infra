#!/usr/bin/env bash
# Устанавливает Ansible на вашей машине (Ubuntu/Debian, в т.ч. WSL) через pipx.
# С ключом --with-dev-tools дополнительно ставит инструменты разработчика
# (Go, yamllint, yamlfmt) ролью dev_tools: им нужен доступ к go.dev, который
# с российских хостингов может быть закрыт, поэтому по умолчанию они пропускаются.
set -euo pipefail

sudo apt-get update
sudo apt-get install -y pipx git openssh-client python3
pipx ensurepath
pipx install --include-deps ansible

export PATH="$HOME/.local/bin:$PATH"
ansible --version

cd "$(dirname "$0")/../ansible"
ansible-galaxy collection install -r requirements.yml
if [ "${1:-}" = "--with-dev-tools" ]; then
  ansible-playbook workstation.yml --ask-become-pass
fi
