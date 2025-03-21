# FreeRADIUS Dockerfile for WBA OpenRoaming Connector (IDP Mode)
# Based on freeradius/freeradius-server but with improved best practices

FROM freeradius/freeradius-server:3.2.1

LABEL maintainer="WBA OpenRoaming Team"
LABEL description="FreeRADIUS server configured for WBA OpenRoaming IDP Mode"
LABEL version="1.0"

# Set working directory
WORKDIR /etc/freeradius

# Copy configuration files
COPY configs/freeradius/site-config/tls /etc/freeradius/sites-enabled/tls
COPY configs/freeradius/site-config/tls /etc/freeradius/sites-available/tls
COPY configs/freeradius/certs /etc/freeradius/certs
COPY configs/freeradius/proxy.conf /etc/freeradius/proxy.conf
COPY configs/freeradius/clients.conf /etc/freeradius/clients.conf

# Set proper permissions in a single layer to reduce image size
RUN set -ex \
    && chmod -R 600 /etc/freeradius/sites-enabled \
    && chmod -R 600 /etc/freeradius/sites-available \
    && chmod 600 /etc/freeradius/certs/privkey.pem \
    && chmod 600 /etc/freeradius/certs/cert.pem \
    && chmod 600 /etc/freeradius/certs/fullchain.pem \
    && chown freerad:freerad /etc/freeradius/certs/cert.pem \
    && chown freerad:freerad /etc/freeradius/certs/privkey.pem \
    && chown freerad:freerad /etc/freeradius/certs/fullchain.pem \
    && chown -R freerad:freerad /etc/freeradius/sites-enabled \
    && chown -R freerad:freerad /etc/freeradius/sites-available

# Expose standard RADIUS ports
EXPOSE 1812/udp 1813/udp 2083/tcp

# Add health check to verify the service is running
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD pidof freeradius || exit 1

# Use freerad user for better security
USER freerad

# Default command
CMD ["freeradius", "-f", "-l", "stdout"]
