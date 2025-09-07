ARG KEYCLOAK_TAG=26.2.4-0

# The rest of this file is based on the following article:
# https://www.keycloak.org/server/containers#_writing_your_optimized_keycloak_containerfile

FROM quay.io/keycloak/keycloak:${KEYCLOAK_TAG} AS builder

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

WORKDIR /opt/keycloak

# Add custom provider JAR file to the providers directory
# ADD --chown=keycloak:keycloak --chmod=644 <MY_PROVIDER_JAR_URL> /opt/keycloak/providers/myprovider.jar

# Build an optimized Keycloak image
RUN /opt/keycloak/bin/kc.sh build

# Configure a database vendor
ENV KC_DB=postgres

FROM quay.io/keycloak/keycloak:${KEYCLOAK_TAG}
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
