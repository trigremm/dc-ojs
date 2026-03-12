# makefile_ojs.mk
# OJS deployment commands (simulates Plesk hosting workflow)

OJS_VERSION ?= 3.5.0-3
OJS_URL := https://pkp.sfu.ca/ojs/download/ojs-$(OJS_VERSION).tar.gz
OJS_HTML := .docker_volumes/html
OJS_FILES := .docker_volumes/private

.PHONY: ojs-download ojs-install ojs-config ojs-clean
.PHONY: ojs-shell ojs-db-shell ojs-upgrade ojs-health

# Download OJS tarball
ojs-download:
	@mkdir -p /tmp/ojs-download
	@echo "Downloading OJS $(OJS_VERSION)..."
	curl -fSL "$(OJS_URL)" -o /tmp/ojs-download/ojs.tar.gz
	@echo "Done: /tmp/ojs-download/ojs.tar.gz"

# Extract OJS into html volume (like uploading to Plesk hosting)
ojs-install: ojs-download
	@mkdir -p $(OJS_HTML) $(OJS_FILES)
	@echo "Extracting OJS to $(OJS_HTML)..."
	tar -xzf /tmp/ojs-download/ojs.tar.gz --strip-components=1 -C $(OJS_HTML)
	@echo "Copying config..."
	cp config/ojs.config.inc.php $(OJS_HTML)/config.inc.php
	@echo "Setting permissions..."
	chmod -R 755 $(OJS_HTML)
	find $(OJS_HTML) -type f -exec chmod 644 {} +
	chmod -R 777 $(OJS_HTML)/cache
	chmod -R 777 $(OJS_HTML)/public
	chmod -R 777 $(OJS_FILES)
	@rm -rf /tmp/ojs-download
	@echo ""
	@echo "OJS $(OJS_VERSION) installed."
	@echo "Visit http://localhost:$${DC_OJS_HTTP_PORT:-8081} to run the web installer."

# Copy config into installed OJS
ojs-config:
	cp config/ojs.config.inc.php $(OJS_HTML)/config.inc.php
	@echo "Config updated."

# Remove OJS files (clean slate)
ojs-clean:
	rm -rf $(OJS_HTML)/*
	@echo "OJS files removed."

# Shell access
ojs-shell:
	$(DC_BIN) exec ojs bash

ojs-db-shell:
	$(DC_BIN) exec db mariadb -u$${OJS_DB_USER:-ojs} -p$${OJS_DB_PASSWORD:-changeMePlease} $${OJS_DB_NAME:-ojs}

ojs-upgrade:
	$(DC_BIN) exec ojs php /var/www/html/tools/upgrade.php upgrade

ojs-health:
	curl -fsS http://localhost:$${DC_OJS_HTTP_PORT:-8081}/index.php && echo " OK"
