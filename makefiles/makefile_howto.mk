# makefile_howto.mk
# `make howto-*` targets print copy-pasteable command sequences for common
# bootstrap/runtime flows on a fresh target host.

.PHONY: howto-deploy howto-up

howto-deploy:
	@echo 'ssh-keygen -t ed25519 -C "deploy-key-dc-ojs@$$(hostname)" -f ~/.ssh/deploy-key-dc-ojs'
	@echo 'eval "$$(ssh-agent -s)" && ssh-add ~/.ssh/deploy-key-dc-ojs && cat ~/.ssh/deploy-key-dc-ojs.pub'
	@echo "GIT_SSH_COMMAND='ssh -i ~/.ssh/deploy-key-dc-ojs' git clone git@github.com:trigremm/dc-ojs.git"
	@echo 'cd dc-ojs'
	@echo 'git config core.sshCommand "ssh -i ~/.ssh/deploy-key-dc-ojs"'
	@echo 'sudo usermod -aG docker $$USER'

howto-up:
	@echo 'cp .env.sample .env'
	@echo 'vim .env  # set OJS_DB_* passwords and DC_OJS_HTTP_PORT'
	@echo 'make up'
	@echo 'make ojs-install'
