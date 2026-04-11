# makefiles/ojs.mk
# OJS deployment commands (simulates Plesk hosting workflow)

OJS_VERSION ?= 3.5.0-3
OJS_URL := https://pkp.sfu.ca/ojs/download/ojs-$(OJS_VERSION).tar.gz
# SHA256 of the upstream tarball. Set OJS_SHA256 in .env to enable verification.
# Obtain from: curl -sL https://pkp.sfu.ca/ojs/download/ojs-$(OJS_VERSION).tar.gz | sha256sum
OJS_SHA256 ?=

# All file operations run inside the ojs container so that files are owned by
# www-data and the host user never needs write access to .docker_volumes/html.
DC_EXEC_OJS := $(DC_BIN) exec -T ojs

.PHONY: ojs-install ojs-config ojs-clean ojs-cache-clear
.PHONY: ojs-shell ojs-db-shell ojs-upgrade ojs-health
.PHONY: ojs-scheduler ojs-jobs ojs-backup ojs-restore

# Download + extract OJS into /var/www/html inside the container.
# Requires `make up` first (container must be running).
ojs-install:
	@$(DC_BIN) ps --status running --services | grep -qx ojs || { echo "ojs container is not running — run 'make up' first"; exit 1; }
	@echo "Downloading OJS $(OJS_VERSION) inside container..."
	$(DC_EXEC_OJS) curl -fSL "$(OJS_URL)" -o /tmp/ojs.tar.gz
	@if [ -n "$(OJS_SHA256)" ]; then \
		echo "Verifying sha256..."; \
		$(DC_EXEC_OJS) bash -c 'echo "$(OJS_SHA256)  /tmp/ojs.tar.gz" | sha256sum -c -'; \
	else \
		echo "WARN: OJS_SHA256 not set — skipping checksum verification"; \
	fi
	@echo "Cleaning /var/www/html..."
	$(DC_EXEC_OJS) bash -c 'rm -rf /var/www/html/* /var/www/html/.[!.]*'
	@echo "Extracting..."
	$(DC_EXEC_OJS) tar -xzf /tmp/ojs.tar.gz --strip-components=1 -C /var/www/html
	$(DC_EXEC_OJS) rm /tmp/ojs.tar.gz
	$(MAKE) ojs-config
	@echo "Setting permissions..."
	$(DC_EXEC_OJS) chown -R www-data:www-data /var/www/html /var/www/files
	$(DC_EXEC_OJS) bash -c 'chmod -R 755 /var/www/html && find /var/www/html -type f -exec chmod 644 {} +'
	$(DC_EXEC_OJS) chmod -R 775 /var/www/html/cache /var/www/html/public /var/www/files
	@echo ""
	@echo "OJS $(OJS_VERSION) installed."
	@echo "Visit http://localhost:$${DC_OJS_HTTP_PORT:-8060} to run the web installer."

# Copy config.inc.php into the running container (pipe via stdin).
ojs-config:
	@echo "Copying config..."
	$(DC_EXEC_OJS) tee /var/www/html/config.inc.php < config/ojs.config.inc.php > /dev/null
	$(DC_EXEC_OJS) chown www-data:www-data /var/www/html/config.inc.php
	@echo "Config updated."

# Wipe OJS files (clean slate).
ojs-clean:
	$(DC_EXEC_OJS) bash -c 'rm -rf /var/www/html/* /var/www/html/.[!.]*'
	@echo "OJS files removed."

# Clear OJS template/opcache cache.
ojs-cache-clear:
	$(DC_EXEC_OJS) bash -c 'rm -rf /var/www/html/cache/*.php /var/www/html/cache/t_compile/* /var/www/html/cache/t_cache/*'
	@echo "OJS cache cleared."

# Run OJS scheduled tasks manually.
ojs-scheduler:
	$(DC_BIN) exec ojs php /var/www/html/lib/pkp/tools/scheduler.php run

# Run the queue worker to process pending jobs.
ojs-jobs:
	$(DC_BIN) exec ojs php /var/www/html/lib/pkp/tools/jobs.php work

# Backup database dump + files archive into .docker_volumes/backups/.
ojs-backup:
	@mkdir -p .docker_volumes/backups
	@$(LOAD_ENV); ts=$$(date +%Y%m%d-%H%M%S); \
	$(DC_BIN) exec -T -e MYSQL_PWD="$$OJS_DB_ROOT_PASSWORD" db mariadb-dump -u root "$$OJS_DB_NAME" > .docker_volumes/backups/db-$$ts.sql && \
	tar -czf .docker_volumes/backups/files-$$ts.tar.gz -C .docker_volumes private && \
	umask 077 && chmod 600 .docker_volumes/backups/db-$$ts.sql .docker_volumes/backups/files-$$ts.tar.gz && \
	echo "Backup saved: .docker_volumes/backups/{db,files}-$$ts.*"

# Restore latest backup (db + files).
ojs-restore:
	@$(LOAD_ENV); db=$$(ls -t .docker_volumes/backups/db-*.sql 2>/dev/null | head -1); \
	files=$$(ls -t .docker_volumes/backups/files-*.tar.gz 2>/dev/null | head -1); \
	[ -n "$$db" ] || { echo "No db backup found"; exit 1; }; \
	echo "Restoring $$db and $$files..."; \
	$(DC_BIN) exec -T -e MYSQL_PWD="$$OJS_DB_ROOT_PASSWORD" db mariadb -u root "$$OJS_DB_NAME" < $$db && \
	tar -xzf $$files -C .docker_volumes && \
	echo "Restore done."

# Shell access
ojs-shell:
	$(DC_BIN) exec ojs bash

ojs-db-shell:
	@$(LOAD_ENV); $(DC_BIN) exec -e MYSQL_PWD="$$OJS_DB_PASSWORD" db mariadb -u"$$OJS_DB_USER" "$$OJS_DB_NAME"

ojs-upgrade:
	$(DC_BIN) exec ojs php /var/www/html/tools/upgrade.php upgrade

ojs-health:
	curl -fsS http://localhost:$${DC_OJS_HTTP_PORT:-8060}/index.php && echo " OK"

# Generate secure random values for config/ojs.config.inc.php (salt, api_key_secret).
# Print them — user copies into the config file manually.
ojs-gen-secrets:
	@echo "salt           = \"$$(openssl rand -hex 32)\""
	@echo "api_key_secret = \"$$(openssl rand -hex 32)\""
	@echo ""
	@echo "Copy the lines above into config/ojs.config.inc.php [security] section,"
	@echo "then run 'make ojs-config' to push the updated config into the container."
