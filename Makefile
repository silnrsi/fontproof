VERSION := $(shell git describe --long --tags --always)

.PHONY: docker
docker: Dockerfile
	IMAGE_NAME=siletypesetter/fontproof:HEAD ./hooks/build $(VERSION)
