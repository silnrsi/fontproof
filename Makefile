VERSION := $(shell git describe --long --tags --always)

.PHONY: docker
docker: Dockerfile
	docker build \
		--build-arg VCS_REF="$(VERSION)" \
		--tag siletypesetter/fontproof:HEAD \
		./
