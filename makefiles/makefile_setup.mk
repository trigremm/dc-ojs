# makefile_setup.mk
# `make setup` prints a bootstrap bash script intended to be copy-pasted into
# an SSH session on a fresh target host. Nothing runs locally — the output is
# the script. Expects git, make, docker, docker compose to already be installed
# on the target.

define SETUP_BOOTSTRAP
# ========================================================================
# dc-ojs bootstrap — copy this whole block, paste into SSH on the target host
# ========================================================================
set -euo pipefail
REPO_SSH="git@github.com-dc-ojs:trigremm/dc-ojs.git"
REPO_DIR="dc-ojs"

# 1. deploy key
if [ ! -f ~/.ssh/deploy-key-dc-ojs ]; then
    ssh-keygen -t ed25519 -N "" -C "deploy-key-dc-ojs@$$(hostname)" -f ~/.ssh/deploy-key-dc-ojs
fi

# 2. ssh config alias (github.com-dc-ojs)
mkdir -p ~/.ssh && touch ~/.ssh/config && chmod 600 ~/.ssh/config
if ! grep -q '^Host github.com-dc-ojs$$' ~/.ssh/config; then
    printf '\nHost github.com-dc-ojs\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/deploy-key-dc-ojs\n  IdentitiesOnly yes\n' >> ~/.ssh/config
fi

# 3. show pubkey + pause
echo "========================================================================"
echo " Add this deploy key at:"
echo "   https://github.com/trigremm/dc-ojs/settings/keys/new"
echo "   Title: $$(hostname)   |   Allow write access: unchecked"
echo "========================================================================"
cat ~/.ssh/deploy-key-dc-ojs.pub
echo "========================================================================"
read -r -p "Press Enter AFTER the key is added to GitHub (Ctrl-C to abort)... " _

# 4. verify GitHub SSH auth via the alias
ssh -o StrictHostKeyChecking=accept-new -T git@github.com-dc-ojs 2>&1 | grep -q "successfully authenticated" \
    || { echo "deploy key not yet active on GitHub"; exit 1; }
echo "deploy key OK"

# 5. clone
if [ ! -d $$REPO_DIR ]; then
    git clone $$REPO_SSH $$REPO_DIR
fi
cd $$REPO_DIR

# 6. env
[ -f .env ] || cp .env.sample .env
echo "------------------------------------------------------------------------"
echo "Edit .env now to set OJS_DB_* passwords (leave this shell, edit, return)."
echo "------------------------------------------------------------------------"
read -r -p "Press Enter AFTER .env is configured... " _

# 7. containers + OJS files
make up
make ojs-install
echo
echo "Done. Open http://localhost:$${DC_OJS_HTTP_PORT:-8060} (behind nginx on the public domain) to finish the OJS web installer."
# ========================================================================
endef
export SETUP_BOOTSTRAP

.PHONY: setup

setup:
	@echo "$$SETUP_BOOTSTRAP"
