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
    monitoring/    VictoriaMetrics + vmalert + Grafana + node-exporter (выключена по умолчанию)
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

## Мониторинг

Роль `monitoring` поднимает отдельный compose-стек в `/opt/monitoring`:

| Сервис | Для чего | Доступ |
|---|---|---|
| VictoriaMetrics | хранение метрик (90 дней), сбор с api, воркера, сервера | только loopback `:8428` (ssh-туннель) |
| vmalert | правила алертов (`roles/monitoring/files/rules`) | только внутри сети |
| Grafana | дашборды; готовый «notrecinema: обзор» | loopback `:3001`, наружу через nginx |
| node-exporter | CPU, память, диск сервера | только внутри сети |

Роль выключена по умолчанию: ей нужен уже запущенный стек приложения (она
подключается к его сети `notrecinema-net`, потому что порты api и воркера на
хосте привязаны к loopback и из контейнера недоступны). Порядок:

1. Задеплойте стек приложения (`docker-compose.prod.yml` в `/opt/notrecinema`).
2. В `group_vars/all.yml`: `monitoring_enabled: true`, `grafana_admin_password`
   (не короче 12 символов), `grafana_root_url`.
3. Чтобы открыть Grafana наружу: A-запись `grafana.notrecinema.ru` на сервер и
   сайт `grafana` в `nginx_sites` (пример -- в `all.example.yml`), затем
   `--tags nginx`.
4. `ansible-playbook site.yml --tags monitoring --ask-become-pass`.

Что важно знать:

- Алерты пока только вычисляются: рассылки нет (нет Alertmanager). Активные
  алерты видны на дашборде («Алертов сейчас») и по запросу
  `ALERTS{alertstate="firing"}`. Подключить Telegram или почту можно позже,
  добавив Alertmanager и убрав `-notifier.blackhole` у vmalert.
- Образы стоят на `latest`; для воспроизводимости закрепите версии в
  `victoriametrics_image` и остальных.
- Правки дашбордов через интерфейс Grafana не сохраняются: меняйте JSON в
  `roles/monitoring/files/dashboards` и перезапускайте роль.
- `node-exporter` работает в bridge-сети, поэтому сетевые метрики хоста
  (`node_network_*`) отражают контейнер; CPU, память и диск -- хоста.
- Каталог метрик и пороги алертов -- в
  `notrecinema-api/docs/METRICS.md`.

## Что важно знать

- Чтобы клонировать другой репозиторий, достаточно добавить запись в `apps`.
- `/metrics` у сайтов из `nginx_sites` наружу не отдаётся (404, настраивается
  через `deny_paths` / `nginx_default_deny_paths`): метрики API и воркера
  забирает Prometheus напрямую по внутренней сети.
- В `.env` на сервере (общий для API и воркера) должен быть
  `UNSUBSCRIBE_SECRET` (`openssl rand -hex 32`), а `APP_URL` -- адрес
  фронтенда (`https://notrecinema.ru`): на него ведут ссылки из писем.
  Callback GitHub OAuth теперь `https://<фронтенд>/api/v1/auth/github/callback`.
- Docker публикует порты в обход UFW: всё из `ports:` в compose будет доступно
  снаружи, даже если UFW порт не разрешал.
