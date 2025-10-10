<div>
  <img align="right" height="40" src="./docs/scoutid.png" alt="ScoutID Logo">

  <h1>ScoutID Optimized Keycloak Image</h1>
</div>

> [!TIP]
> This repo is part of a family:
> - [scoutid-keycloak](https://github.com/Scouterna/scoutid-keycloak) (this repo)
> - [scoutid-keycloak-provider](https://github.com/Scouterna/scoutid-keycloak-provider)
> - [scoutid-keycloak-infra](https://github.com/Scouterna/scoutid-keycloak-infra) (private)

This repository contains the sources to build the optimized version of Keycloak
that ScoutID runs.

Features:
- The [Azure Identity library](https://learn.microsoft.com/en-us/java/api/overview/azure/identity-readme?view=azure-java-stable) is installed.
- A custom Keycloak authenticator that authenticates towards Scoutnet is installed.
- Environment variables starting with `APPSETTING_KC_` are automatically trimmed to `KC_` to allow configuring environment variables through App Service.

## Building

The Docker image is built on every push to any branch. Images are tagged with
the commit hash in the format `sha-<hash>`, and pushes to the `main` branch will
additionally be tagged with the `latest` tag.
