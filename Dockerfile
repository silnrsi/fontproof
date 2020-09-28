FROM docker.io/siletypesetter/sile:v0.10.12 AS fontproof

# Freshen all base system packages
RUN pacman --needed --noconfirm -Syuq && yes | pacman -Sccq

# Install fontproof dependencies
RUN pacman --needed --noconfirm -Syq words

# Set at build time, forces Docker's layer caching to reset at this point
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
