# Multi-stage build for radsecproxy for WBA OpenRoaming Connector (ANP Mode)
# Based on Alpine Linux for minimal image size

# Build stage
FROM alpine:3.19 as build

# Metadata
LABEL maintainer="WBA OpenRoaming Team"
LABEL description="Build stage for radsecproxy"

# Environment variables
ENV RADSECVERSION=1.9.1
ENV RADSECURL=https://github.com/radsecproxy/radsecproxy/releases/download/${RADSECVERSION}/
ENV RADSECFILENAME=radsecproxy-${RADSECVERSION}.tar.gz

# Set working directory
WORKDIR /root

# Install build dependencies
RUN apk add --no-cache --update \
    make \
    g++ \
    openssl-dev \
    nettle-dev \
    musl-dev \
    wget

# Create output directory
RUN mkdir output

# Download and extract radsecproxy source
RUN wget ${RADSECURL}${RADSECFILENAME} && \
    tar xf ${RADSECFILENAME} --strip-components=1

# Configure, make and install to output directory
RUN ./configure --prefix=/root/output --sysconfdir=/etc && \
    make && \
    make install

# Final stage
FROM alpine:3.19

# Metadata
LABEL maintainer="WBA OpenRoaming Team"
LABEL description="Radsecproxy for WBA OpenRoaming ANP Mode"
LABEL version="1.0"

# Install runtime dependencies
RUN apk add --no-cache --update \
    openssl \
    ca-certificates \
    bash \
    nettle \
    tini \
    bind-tools

# Copy built files from build stage
COPY --from=build /root/output/ /
COPY --from=build /root/radsecproxy.conf-example /etc/radsecproxy.conf

# Copy startup script and make it executable
COPY start.sh /root/start.sh
RUN chmod u+x /root/start.sh

# Copy NAPTR script and make it executable
COPY configs/radsecproxy/naptr-openroaming.sh /etc/radsecproxy/naptr-openroaming.sh
RUN chmod +x /etc/radsecproxy/naptr-openroaming.sh

# Create necessary directories
RUN mkdir -p /var/log/radsecproxy && \
    mkdir -p /etc/radsecproxy/certs

# Define volume for logs
VOLUME /var/log/radsecproxy

# Expose RADIUS ports
EXPOSE 1812/udp 1813/udp

# Add health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD pidof radsecproxy || exit 1

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Default command
CMD ["/root/start.sh"]
