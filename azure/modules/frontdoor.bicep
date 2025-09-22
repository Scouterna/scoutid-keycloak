@description('The fully qualified domain name (FQDN) of your backend service.')
param appServiceHostname string

resource frontDoorProfile 'Microsoft.Cdn/profiles@2025-06-01' = {
  name: 'cdnp-scoutid-prod-sec-${uniqueString(resourceGroup().id)}'
  location: 'Global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2025-06-01' = {
  parent: frontDoorProfile
  name: 'cdne-scoutid-prod-sec-${uniqueString(resourceGroup().id)}'
  location: 'Global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2025-06-01' = {
  parent: frontDoorProfile
  name: 'cdnog-scoutid-prod-sec-${uniqueString(resourceGroup().id)}'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 2
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}

resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2025-06-01' = {
  parent: originGroup
  name: 'cdno-scoutid-prod-sec-${uniqueString(resourceGroup().id)}'
  properties: {
    hostName: appServiceHostname
    httpPort: 80
    httpsPort: 443
    originHostHeader: appServiceHostname
    enabledState: 'Enabled'
  }
}

// --- 4. Simple Route - Forward All Traffic to App Service ---
resource defaultRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2025-06-01' = {
  parent: frontDoorEndpoint
  name: 'cdnr-scoutid-prod-sec-${uniqueString(resourceGroup().id)}'
  properties: {
    // Simple route that forwards all traffic to the app service
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    originGroup: {
      id: originGroup.id
    }
    forwardingProtocol: 'MatchRequest'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
  dependsOn: [
    origin
  ]
}

output frontDoorEndpointHostName string = frontDoorEndpoint.properties.hostName
