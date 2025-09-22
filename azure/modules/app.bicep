param appServiceName string

param subnetId string
param imageName string
param dbServerFqdn string
param keycloakBootstrapAdminUsername string
@secure()
param keycloakBootstrapAdminPassword string


resource appServicePlan 'Microsoft.Web/serverfarms@2024-11-01'= {
  name: 'asp-scoutid-prod-sec-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  kind: 'linux'
  sku: {
    name: 'S2'
    tier: 'Standard'
  }
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2024-11-01' = {
  name: appServiceName
  location: resourceGroup().location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    virtualNetworkSubnetId: subnetId
    siteConfig: {
      appCommandLine: 'start --optimized'
      linuxFxVersion: 'DOCKER|${imageName}'
      alwaysOn: true
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'KC_DB'
          value: 'postgres'
        }
        {
          name: 'KC_DB_URL'
          value: 'jdbc:postgresql://${dbServerFqdn}:5432/keycloak?sslmode=require'
        }
        {
          name: 'KC_DB_USERNAME'
          value: appServiceName
        }
        {
          name: 'KC_BOOTSTRAP_ADMIN_USERNAME'
          value: keycloakBootstrapAdminUsername
        }
        {
          name: 'KC_BOOTSTRAP_ADMIN_PASSWORD'
          value: keycloakBootstrapAdminPassword
        }
        {
          name: 'KC_PROXY_HEADERS'
          value: 'xforwarded'
        }
        {
          name: 'KC_HTTP_ENABLED' // We can enable this because Front Door terminates TLS
          value: 'true'
        }
        {
          name: 'KC_HOSTNAME_STRICT' // TODO: Remove before going to prod
          value: 'false'
        }
      ]
    }
  }
}
output appServicePrincipalId string = appService.identity.principalId
output appServiceHostname string = appService.properties.defaultHostName
