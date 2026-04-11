# x_nginx

Host-level nginx configs for reverse-proxying dc-ojs. Not used by Docker — drop onto the host nginx and reload.

## Install

```bash
sudo cp x_nginx/ojs.asmo.su.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/ojs.asmo.su.conf /etc/nginx/sites-enabled/
sudo certbot certonly --nginx -d ojs.asmo.su
sudo nginx -t && sudo systemctl reload nginx
```

## After pointing a real domain at OJS

Update `config/ojs.config.inc.php`:

```ini
[general]
base_url = "https://ojs.asmo.su"
allowed_hosts = '["ojs.asmo.su"]'
trust_x_forwarded_for = On

[security]
force_ssl = On
```

Then push the config into the container:

```bash
make ojs-config
```
