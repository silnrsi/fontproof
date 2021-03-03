#syntax=docker/dockerfile:1.2

ARG SILETAG

FROM docker.io/siletypesetter/sile:$SILETAG AS fontproof

# This is a hack to convince Docker Hub that its cache is behind the times.
# This happens when the contents of our dependencies changes but the base
# system hasn’t been refreshed. It’s helpful to have this as a separate layer
# because it saves a lot of time for local builds, but it does periodically
# need a poke. Incrementing this when changing dependencies or just when the
# remote Docker Hub builds die should be enough.
ARG DOCKER_HUB_CACHE=0

ARG RUNTIME_DEPS
# Freshen all base system packages
RUN pacman --needed --noconfirm -Syuq && yes | pacman -Sccq

# Install run-time dependecies (increment cache var above)
RUN pacman --needed --noconfirm -Sq $RUNTIME_DEPS && yes | pacman -Sccq

# Set at build time, forces Docker’s layer caching to reset at this point
ARG VCS_REF=0

# Copy fontproof sources somewhere
COPY ./ /usr/local/share/fontproof

# Patch SILE path with our quazi-installation directory
RUN sed -i -e '/^extendPath...../a extendPath("/usr/local/share/fontproof")' \
	/usr/local/bin/sile

LABEL maintainer="Caleb Maclennan <caleb@alerque.com>"
LABEL version="$VCS_REF"

RUN sile --version

WORKDIR /data
ENTRYPOINT ["sile"]
