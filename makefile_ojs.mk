# makefile_ojs.mk
# OJS management commands

.PHONY: ojs-shell ojs-db-shell ojs-upgrade ojs-health

ojs-shell:
	$(DC_BIN) exec ojs bash

ojs-db-shell:
	$(DC_BIN) exec db mariadb -u$${OJS_DB_USER:-ojs} -p$${OJS_DB_PASSWORD:-changeMePlease} $${OJS_DB_NAME:-ojs}

ojs-upgrade:
	$(DC_BIN) exec ojs php /var/www/html/tools/upgrade.php upgrade

ojs-health:
	curl -fsS http://localhost:$${DC_OJS_HTTP_PORT:-8081}/index.php && echo " OK"
