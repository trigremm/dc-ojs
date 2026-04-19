# makefile_git.mk

.PHONY: git-pull git-cleanup git-commit-message

git-pull:
	git pull

git-cleanup:
	git branch | grep -v "^\*" | grep -v "^\s*main$$" | xargs -n 1 git branch -d || true

git-commit-message:
	@echo "Current Git commit: $(shell git rev-parse --short HEAD)"
	@echo "Git commit message: $(shell git log -1 --pretty=%s)"
