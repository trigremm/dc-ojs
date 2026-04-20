# Makefile
include makefiles/makefile_docker_compose.mk
include makefiles/makefile_docker.mk
include makefiles/makefile_format.mk
include makefiles/makefile_git.mk
include makefiles/makefile_nginx.mk
include makefiles/makefile_ojs.mk
include makefiles/makefile_howto.mk

.PHONY: ssh

ssh:
	ssh test-asmo-server
