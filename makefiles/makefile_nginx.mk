# makefile_nginx.mk
# Nginx config deployment commands — copy site configs from x_nginx/ into
# /etc/nginx/sites-available and symlink into sites-enabled, then reload.
#
# The vhost files ship HTTP-only. `certbot --nginx --redirect` is then run
# against the live config to add the 443 server block, the HTTP->HTTPS
# redirect, and manage cert renewal.

NGINX_SITES_AVAILABLE := /etc/nginx/sites-available
NGINX_SITES_ENABLED := /etc/nginx/sites-enabled

.PHONY: nginx-test nginx-reload nginx-status
.PHONY: nginx-add-ojs-asmo-su nginx-remove-ojs-asmo-su

nginx-add-ojs-asmo-su:
	sudo nginx -t
	sudo cp x_nginx/ojs.asmo.su.conf $(NGINX_SITES_AVAILABLE)/ojs.asmo.su.conf
	sudo ln -sf $(NGINX_SITES_AVAILABLE)/ojs.asmo.su.conf $(NGINX_SITES_ENABLED)/ojs.asmo.su.conf
	sudo nginx -t && sudo nginx -s reload
	sudo certbot --nginx -d ojs.asmo.su --redirect --keep-until-expiring --non-interactive --agree-tos -m asmo@asmo.su
	sudo nginx -t && sudo nginx -s reload

nginx-remove-ojs-asmo-su:
	sudo rm -f $(NGINX_SITES_ENABLED)/ojs.asmo.su.conf
	sudo rm -f $(NGINX_SITES_AVAILABLE)/ojs.asmo.su.conf
	sudo nginx -t && sudo nginx -s reload

nginx-test:
	sudo nginx -t

nginx-reload:
	sudo nginx -s reload

nginx-status:
	@ls x_nginx/ | grep -v '^README' | while read name; do \
		if [ -L $(NGINX_SITES_ENABLED)/$$name ]; then \
			echo "$$name: enabled"; \
		elif [ -f $(NGINX_SITES_AVAILABLE)/$$name ]; then \
			echo "$$name: available (not enabled)"; \
		else \
			echo "$$name: not deployed"; \
		fi; \
	done
