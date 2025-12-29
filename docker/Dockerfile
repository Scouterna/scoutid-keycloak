# syntax=docker/dockerfile:1

# You should update all versions to the latest stable versions before building
ARG KEYCLOAK_TAG="26.4.5-0"
ARG AZURE_IDENTITY_EXTENSIONS_VERSION="1.2.5"
ARG SCOUTNET_PROVIDER_VERSION="0.5.1"
ARG SCOUTID_THEME_VERSION="0.2.0"

# The rest of this file is based on multiple sources:
# - https://github.com/keycloak/keycloak/discussions/26267#discussioncomment-10824627
# - https://www.keycloak.org/server/containers#_writing_your_optimized_keycloak_containerfile


FROM registry.access.redhat.com/ubi9/ubi:9.6 AS ubi-micro-build
RUN mkdir -p /mnt/rootfs
RUN dnf install --installroot /mnt/rootfs curl jq --releasever 9 --setopt install_weak_deps=false --nodocs -y; dnf --installroot /mnt/rootfs clean all


FROM maven:latest AS maven
ARG AZURE_IDENTITY_EXTENSIONS_VERSION
ARG SCOUTNET_PROVIDER_VERSION
ARG SCOUTID_THEME_VERSION

# Obtain the Azure Identity Providers JDBC PostgreSQL library
RUN mvn dependency:get -Dartifact=com.azure:azure-identity-extensions:${AZURE_IDENTITY_EXTENSIONS_VERSION}

# Now also get the IDP's dependencies
WORKDIR /root/.m2/repository/com/azure/azure-identity-extensions/${AZURE_IDENTITY_EXTENSIONS_VERSION}
RUN cp azure-identity-extensions-${AZURE_IDENTITY_EXTENSIONS_VERSION}.pom pom.xml
RUN mvn dependency:copy -Dartifact=com.azure:azure-identity-extensions:${AZURE_IDENTITY_EXTENSIONS_VERSION} -DoutputDirectory=/jar
RUN mvn dependency:copy-dependencies -DincludeScope=runtime -DoutputDirectory=/jar

# Download the Scoutnet Authenticator JAR
RUN cd /jar && curl -LO https://github.com/Scouterna/scoutid-keycloak-provider/releases/download/v${SCOUTNET_PROVIDER_VERSION}/keycloak-scoutnet-authenticator-${SCOUTNET_PROVIDER_VERSION}.jar

# Download the ScoutID Theme JAR
RUN cd /jar && curl -LO https://github.com/Scouterna/scoutid-keycloak-theme/releases/download/v${SCOUTID_THEME_VERSION}/keycloak-theme-for-kc-all-other-versions.jar

FROM quay.io/keycloak/keycloak:${KEYCLOAK_TAG} AS builder

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=postgres

WORKDIR /opt/keycloak

# Copy the Azure Identity Provider
COPY --from=maven --chown=keycloak:keycloak --chmod=644 /jar/*.jar providers/

# Add custom provider JAR file to the providers directory
# ADD --chown=keycloak:keycloak --chmod=644 <MY_PROVIDER_JAR_URL> /opt/keycloak/providers/myprovider.jar

# Build an optimized Keycloak image
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:${KEYCLOAK_TAG}
COPY --from=ubi-micro-build /mnt/rootfs /
COPY --from=builder /opt/keycloak/ /opt/keycloak/

COPY entrypoint.sh /opt/keycloak/custom_entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/opt/keycloak/custom_entrypoint.sh"]
