# notrecinema-infra

Настройка серверов для notrecinema через Ansible. Рассчитано на Ubuntu 22.04/24.04.

## Структура

```bash
ansible/
  site.yml                  точка входа
  group_vars/all.example.yml  все настройки (копия -> all.yml)
  inventory.example.ini     адрес сервера (копия -> inventory.ini)
  roles/
    common/        базовые пакеты, автообновления безопасности
    deploy_user/   пользователь деплоя и его SSH-ключи
    docker/        Docker + compose v2
    ssh_hardening/ только ключи, без root, AllowUsers
    firewall/      UFW
    fail2ban/      защита от перебора SSH
    app_checkout/  клонирование приложений из списка `apps`
scripts/install-ansible.sh  установка Ansible
```

## 1. Установка Ansible (на вашей машине)

Ansible не работает нативно на Windows -- используйте WSL (Ubuntu):

```powershell
wsl --install -d Ubuntu
```

Дальше внутри Ubuntu/WSL или на Linux/macOS-машине:

```bash
./scripts/install-ansible.sh
```

Скрипт ставит Ansible через pipx и коллекции из `ansible/requirements.yml`.

## 2. Настройка

```bash
cd ansible
cp inventory.example.ini inventory.ini
cp group_vars/all.example.yml group_vars/all.yml
# отредактируйте оба файла
```

Оба файла в `.gitignore`: в них адрес сервера.

## 3. Запуск

Перед первым запуском держите открытой вторую SSH-сессию на сервер.

```bash
ansible-playbook site.yml --ask-become-pass
```

Выборочно, по тегам: `common`, `users`, `docker`, `ssh`, `firewall`,
`fail2ban`, `apps`:

```bash
ansible-playbook site.yml --tags apps --ask-become-pass
```

Плейбук идемпотентен, его можно запускать повторно.

## Что важно знать

- Чтобы клонировать другой репозиторий, достаточно добавить запись в `apps`.
- Docker публикует порты в обход UFW: всё из `ports:` в compose будет доступно
  снаружи, даже если UFW порт не разрешал.
