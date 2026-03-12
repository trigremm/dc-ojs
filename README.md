# dc-ojs

Docker Compose setup for [OJS (Open Journal Systems)](https://pkp.sfu.ca/software/ojs/) - publications review portal.

Custom PHP 8.3 + Apache image with OJS 3.5.0-3 installed from source tarball.

## Quick start

```bash
cp .env.sample .env     # edit passwords
make r                  # build and start
```

Visit `http://localhost:8081` to complete the web installer.

### Web installer settings

| Field              | Value                        |
|--------------------|------------------------------|
| Database driver    | `mysqli`                     |
| Host               | `db`                         |
| Username           | value from `OJS_DB_USER`     |
| Password           | value from `OJS_DB_PASSWORD` |
| Database name      | value from `OJS_DB_NAME`     |
| Create new database| **unchecked**                |
| Files directory    | `/var/www/files`             |

## Commands

```bash
make r            # build + restart
make up           # start
make stop         # stop
make down         # stop and remove
make logs         # tail logs
make ps           # list containers
make ojs-shell    # bash into OJS container
make ojs-db-shell # mariadb CLI
make ojs-upgrade  # run OJS upgrade script
make ojs-health   # check OJS health
```
