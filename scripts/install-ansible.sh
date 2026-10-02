#!/usr/bin/env bash
# Устанавливает Ansible на вашей машине (Ubuntu/Debian, в т.ч. WSL) через pipx
# и ставит нужные коллекции.
set -euo pipefail

sudo apt-get update
sudo apt-get install -y pipx git openssh-client
pipx ensurepath
pipx install --include-deps ansible

export PATH="$HOME/.local/bin:$PATH"
ansible --version
ansible-galaxy collection install -r "$(dirname "$0")/../ansible/requirements.yml"
