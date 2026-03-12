# dc-ojs

Docker Compose setup simulating a PHP Plesk hosting environment for deploying [OJS (Open Journal Systems)](https://pkp.sfu.ca/software/ojs/).

The container provides a bare PHP 8.3 + Apache engine. OJS is installed separately via Makefile, mirroring the real Plesk deployment workflow.

## Quick start

```bash
cp .env.sample .env     # edit passwords
make up                 # start bare PHP + MariaDB
make ojs-install        # download and extract OJS into html volume
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
make up              # start containers
make stop            # stop
make down            # stop and remove
make logs            # tail logs
make ps              # list containers

make ojs-install     # download + extract OJS into html volume
make ojs-config      # re-copy config into installed OJS
make ojs-clean       # wipe OJS files (clean slate)
make ojs-upgrade     # run OJS upgrade script
make ojs-shell       # bash into PHP container
make ojs-db-shell    # mariadb CLI
```
