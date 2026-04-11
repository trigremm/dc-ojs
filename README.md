# dc-ojs

Docker Compose setup simulating a PHP Plesk hosting environment for deploying [OJS (Open Journal Systems)](https://pkp.sfu.ca/software/ojs/).

The container provides a bare PHP 8.3 + Apache engine. OJS is installed separately via Makefile, mirroring the real Plesk deployment workflow.

## TL;DR

```bash
cp .env.sample .env        # edit passwords
make up                    # start db + bare php/apache
make ojs-install           # download OJS inside container, extract to html volume
# open http://localhost:8060 → fill the web installer
```

If something breaks: `make logs` to see what happened, `make r` to rebuild the image, `make ojs-clean && make ojs-install` to start over.

## Quick start

```bash
cp .env.sample .env     # edit passwords
make up                 # start bare PHP + MariaDB
make ojs-install        # download and extract OJS into html volume
```

Visit `http://localhost:8060` to complete the web installer.

### Web installer settings

| Field               | Value                        |
| ------------------- | ---------------------------- |
| Database driver     | `mysqli`                     |
| Host                | `db`                         |
| Username            | value from `OJS_DB_USER`     |
| Password            | value from `OJS_DB_PASSWORD` |
| Database name       | value from `OJS_DB_NAME`     |
| Create new database | **unchecked**                |
| Files directory     | `/var/www/files`             |

## Commands

### Docker Compose

```bash
make up              # start containers
make stop            # stop
make down            # stop and remove
make r               # rebuild image + recreate containers
make logs            # tail logs
make ps              # list containers
```

### OJS lifecycle

```bash
make ojs-install     # download + extract OJS inside container
make ojs-config      # re-copy config into running container
make ojs-clean       # wipe OJS files (clean slate)
make ojs-upgrade     # run OJS upgrade script
make ojs-cache-clear # clear template/opcache cache
make ojs-health      # curl index.php
```

### Maintenance

```bash
make ojs-scheduler   # run scheduled tasks manually
make ojs-jobs        # process queued jobs
make ojs-backup      # dump db + private files into .docker_volumes/backups/
make ojs-restore     # restore the latest backup
```

### Shell access

```bash
make ojs-shell       # bash into PHP container
make ojs-db-shell    # mariadb CLI
```

## Structure

- `docker-compose.yaml` — `db` (MariaDB 11) + `ojs` (PHP 8.3 + Apache) services
- `backend/` — Dockerfile, apache.conf for the `ojs` image
- `config/` — mounted into containers: `php.custom.ini`, `db.charset.conf`, `ojs.config.inc.php`
- `makefiles/` — Makefile fragments (`docker_compose.mk`, `ojs.mk`) included from root `Makefile`
- `.docker_volumes/` — persistent data (db, html, private, apache_logs, backups) — gitignored

## Storage

OJS splits data between two backends:

| What                                                                                        | Where                                                        |
| ------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| Article metadata, users, review comments, issue structure, workflow state                   | **MariaDB** (`.docker_volumes/db/`)                          |
| Submission PDFs/DOCX, supplementary files, reviewer attachments, revisions, TinyMCE uploads | **Filesystem** `/var/www/files` → `.docker_volumes/private/` |
| Public images (issue covers, journal logos)                                                 | `.docker_volumes/html/public/`                               |

**OJS does not natively support S3** or other object stores as of 3.5 — it's an [open feature request](https://forum.pkp.sfu.ca/t/adding-object-storage-functionality-to-ojs/97667). Workarounds: FUSE-mount an S3 bucket (`s3fs-fuse`, `rclone mount`, AWS S3 Files), or run `rclone sync` on backups to push cold copies to S3/B2.

### Disk usage estimates

Per-article footprint (full workflow: submission → reviews → revisions → publication):

| Content                                         | Typical size  |
| ----------------------------------------------- | ------------- |
| Submission PDF                                  | 2–10 MB       |
| Supplementary files (data, figures)             | 5–50 MB       |
| Review attachments (annotated PDFs × reviewers) | 10–80 MB      |
| Revisions (each version stored in full)         | ×2–4          |
| **Total per article**                           | **50–300 MB** |

Annual estimates by journal size:

| Journal profile | Articles/year | Expected storage/year |
| --------------- | ------------- | --------------------- |
| Small           | ~50           | 5–15 GB               |
| Medium          | ~200          | 20–60 GB              |
| Large           | 1000+         | 100+ GB               |

Plan for **2–3× headroom** to cover `make ojs-backup` archives living in `.docker_volumes/backups/`.

## Security checklist

Before exposing this setup beyond localhost, go through:

**Must do:**

- [ ] Rotate `OJS_DB_ROOT_PASSWORD` and `OJS_DB_PASSWORD` in `.env` (no `change_me_*` values)
- [ ] `chmod 600 .env` so secrets are not world-readable on the host
- [ ] `make ojs-gen-secrets` → copy `salt` and `api_key_secret` into `config/ojs.config.inc.php` `[security]` section, then `make ojs-config`
- [ ] Set `OJS_SHA256` in `.env` to verify the OJS tarball on download (get it from pkp's release notes or `sha256sum` of a trusted copy)
- [ ] If the DB was already initialized with default passwords, either `ALTER USER` via `make ojs-db-shell` or wipe `.docker_volumes/db` and re-init

**For production deployment:**

- [ ] Put a TLS-terminating reverse proxy (nginx, Traefik, Caddy) in front — set `force_ssl = On` and `cookie_encryption = On` in `config/ojs.config.inc.php`
- [ ] If behind a reverse proxy, enable `trust_x_forwarded_for = On`
- [ ] Set `allowed_hosts = '["your.domain.tld"]'` in `ojs.config.inc.php` to prevent HOST header injection
- [ ] Change port binding from `127.0.0.1:` to `0.0.0.0:` only if exposing directly (not recommended)
- [ ] Add rate-limiting / fail2ban on `/index.php/*/login` to slow down brute force
- [ ] Configure SMTP in `[email]` section with encrypted credentials, don't use `sendmail` stub

**Non-issues in this setup (nginx proxy_pass in front):**

- Apache runs as root inside the container to bind port 80 — fine, because the port is only reachable via `127.0.0.1:${DC_OJS_HTTP_PORT}` on the host and nginx terminates external traffic.
- TLS/HTTPS is handled by nginx, not by Apache in the container.

**Already hardened in this setup:**

- `.env` gitignored; `docker-compose.yaml` fails fast if secrets missing
- Apache: `ServerTokens Prod`, `ServerSignature Off`, `TraceEnable Off`, security headers
- PHP: `expose_php = Off`, `allow_url_fopen = Off`, `session.cookie_httponly = 1`
- OJS: `display_errors = Off`, `show_stacktrace = Off`, `session_check_ip = On`
- Port bound to `127.0.0.1` by default
- Secrets passed via `MYSQL_PWD` env var, never on the command line

## nginx reverse proxy

This setup is designed to sit behind an existing host-level nginx that terminates TLS and proxies to `127.0.0.1:${DC_OJS_HTTP_PORT}`.

A ready-to-use config lives in [`x_nginx/ojs.asmo.su.conf`](x_nginx/ojs.asmo.su.conf) — copy it to `/etc/nginx/sites-available/`, adjust the `server_name` / cert paths, then:

```bash
sudo ln -s /etc/nginx/sites-available/ojs.asmo.su.conf /etc/nginx/sites-enabled/
sudo certbot certonly --nginx -d ojs.asmo.su
sudo nginx -t && sudo systemctl reload nginx
```

See [`x_nginx/README.md`](x_nginx/README.md) for the full install procedure and the OJS-side settings to flip after switching to a real domain (`base_url`, `allowed_hosts`, `trust_x_forwarded_for`, `force_ssl`).

## License

MIT — see [LICENSE](LICENSE). Note that `config/ojs.config.inc.php` is derived from upstream OJS and remains under GPL v3.
