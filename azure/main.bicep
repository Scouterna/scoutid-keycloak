@description('The initial admin username for Keycloak.')
param keycloakBootstrapAdminUsername string

@secure()
@description('The initial admin password for Keycloak.')
param keycloakBootstrapAdminPassword string

@description('The Object ID of the Microsoft Entra user who will be the database admin.')
param entraAdminPrincipalId string

@description('The User Principal Name (email) of the Entra user admin.')
param entraAdminPrincipalName string

@description('The name of the Keycloak Docker image to use. Probably a version of `ghcr.io/scouterna/scoutid-keycloak`.')
param keycloakImageName string

var appServiceName = 'app-scoutid-prod-sec-${uniqueString(resourceGroup().id)}'

module network './modules/network.bicep' = {
  name: 'network-deployment'
}

module database './modules/database.bicep' = {
  name: 'database-deployment'
  params: {
    subnetId: network.outputs.postgresSubnetId
    privateDnsZoneId: network.outputs.postgresPrivateDnsZoneId
    entraAdminPrincipalId: entraAdminPrincipalId
    entraAdminPrincipalName: entraAdminPrincipalName
  }
}

module app './modules/app.bicep' = {
  name: 'app-deployment'
  params: {
    appServiceName: appServiceName
    subnetId: network.outputs.appSvcSubnetId
    imageName: keycloakImageName
    dbServerFqdn: database.outputs.dbFqdn
    keycloakBootstrapAdminUsername: keycloakBootstrapAdminUsername
    keycloakBootstrapAdminPassword: keycloakBootstrapAdminPassword
  }
}

module frontdoor './modules/frontdoor.bicep' = {
  name: 'frontdoor-deployment'
  params: {
    appServiceHostname: app.outputs.appServiceHostname
  }
}

// // This resource updates the App Service with the Front Door hostname.
// // This is done last to avoid a circular dependency between App and Front Door.
// resource appSettings 'Microsoft.Web/sites/config@2024-11-01' = {
//   name: '${appServiceName}/appsettings'
//   properties: {
//     KC_HOSTNAME: frontdoor.outputs.frontDoorEndpointHostName
//     KC_HOSTNAME_STRICT: 'true'
//   }
//   dependsOn: [
// #disable-next-line no-unnecessary-dependson
//     app
// #disable-next-line no-unnecessary-dependson
//     frontdoor
//   ]
// }

output keycloakUrl string = 'https://${frontdoor.outputs.frontDoorEndpointHostName}'
output postDeploymentInstruction string = 'IMPORTANT: You must now manually grant the App Service Managed Identity (${app.outputs.appServicePrincipalId}) permissions in the PostgreSQL database.'
