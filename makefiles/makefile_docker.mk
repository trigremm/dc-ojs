# makefile_docker.mk
# Docker commands (not docker compose)

.PHONY: docker-image-prune docker-builder-prune

docker-image-prune:
	docker image prune -f || true

docker-builder-prune:
	docker builder prune --filter "until=36h" -f || true
