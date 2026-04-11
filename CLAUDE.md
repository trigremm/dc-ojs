# dc-ojs — заметки для Claude Code

Среда разворачивает OJS (Open Journal Systems) через Docker Compose, имитируя Plesk-хостинг: голый PHP+Apache контейнер, OJS раскатывается отдельно Make-таргетом в bind-mount.

## Структура

- `docker-compose.yaml` — два сервиса: `db` (MariaDB 11) и `ojs` (PHP 8.3 + Apache)
- `backend/` — Dockerfile и apache.conf для сервиса `ojs`
- `config/` — файлы, монтируемые в контейнеры (`php.custom.ini`, `db.charset.conf`, `ojs.config.inc.php`)
- `makefiles/` — фрагменты Makefile (`docker_compose.mk`, `ojs.mk`), подключаются явно из корневого `Makefile`
- `.docker_volumes/` — данные БД, `html` (OJS-файлы), `private` (загрузки), `apache_logs`, `backups` — всё в `.gitignore`

## Workflow

```bash
cp .env.sample .env        # настроить пароли
make up                    # поднять db + ojs
make ojs-install           # скачать + распаковать OJS внутри контейнера
# открыть http://localhost:${DC_OJS_HTTP_PORT} для веб-установщика
```

## Make

Все `.mk`-фрагменты подключаются в корневом `Makefile` **поимённо**, не через glob — пользователь явно отверг `include makefiles/*.mk`.

Ключевые цели:

- `make up` / `stop` / `down` / `ps` / `logs` / `build` — обёртки над `docker compose`
- `make r` (recreate) — build + stop + up
- `make ojs-install` — скачивает OJS внутри контейнера (`docker compose exec ojs curl ... | tar`), распаковывает в `/var/www/html`, затем `ojs-config` и chown/chmod
- `make ojs-config` — пайпит `config/ojs.config.inc.php` в контейнер через `tee`
- `make ojs-clean` — `rm -rf /var/www/html/*` внутри контейнера
- `make ojs-cache-clear` / `ojs-scheduler` / `ojs-jobs` — cache, cron-задачи, очередь
- `make ojs-backup` / `ojs-restore` — дамп БД + `private/` в `.docker_volumes/backups/`
- `make ojs-shell` / `ojs-db-shell` — доступ в контейнеры

## Важные принципы

- **Файловые операции над OJS идут внутри контейнера**, не с хоста. Причина: bind-mount `.docker_volumes/html` принадлежит root-у контейнера (www-data), у host-юзера нет прав. `ojs-install` и `ojs-clean` используют `docker compose exec -T ojs` вместо прямых хостовых команд.
- **`config/ojs.config.inc.php` не монтируется как volume** — он копируется внутрь контейнера через `tee` на шаге `ojs-config`. Это нужно чтобы веб-установщик мог переписать файл (с `installed = Off` → `On`) без конфликта с read-only mount.
- **PHP-расширения**: composer platform-check OJS 3.5 требует `ftp`, `mbstring`, `pdo_mysql`, `exif`, `fileinfo`, `bcmath`, `gd`, `intl`, `xml`, `zip`, `calendar`. Все включены в `backend/Dockerfile`.
- **БД-учётки**: в `config/ojs.config.inc.php` секция `[database]` оставлена пустой — веб-установщик подставит значения из формы. Не хардкодить.

## Версия OJS

`OJS_VERSION` в `.env` — используется `makefiles/ojs.mk` для скачивания тарбола с `pkp.sfu.ca`. Текущая: `3.5.0-3` (релиз 19.12.2025). Актуальная: см. https://github.com/pkp/ojs/tags
