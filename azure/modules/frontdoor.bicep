@description('The fully qualified domain name (FQDN) of your backend service.')
param appServiceHostname string

param publicDomainName string
param adminDomainName string

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
    sessionAffinityState: 'Enabled'
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
      '/realms/*'
      '/resources/*'
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

// Custom domain configuration
resource customDomain 'Microsoft.Cdn/profiles/customDomains@2025-06-01' = {
  parent: frontDoorProfile
  name: 'cdncd-scoutid-prod-sec-${uniqueString(resourceGroup().id)}'
  properties: {
    hostName: publicDomainName
    tlsSettings: {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
    }
  }
}

// Admin custom domain configuration
resource adminCustomDomain 'Microsoft.Cdn/profiles/customDomains@2025-06-01' = {
  parent: frontDoorProfile
  name: 'cdncd-admin-scoutid-prod-sec-${uniqueString(resourceGroup().id)}'
  properties: {
    hostName: adminDomainName
    tlsSettings: {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
    }
  }
}

// Associate custom domain with the route
resource customDomainAssociation 'Microsoft.Cdn/profiles/afdEndpoints/routes@2025-06-01' = {
  parent: frontDoorEndpoint
  name: 'cdnr-custom-scoutid-prod-sec-${uniqueString(resourceGroup().id)}'
  properties: {
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/realms/*'
      '/resources/*'
    ]
    originGroup: {
      id: originGroup.id
    }
    forwardingProtocol: 'MatchRequest'
    customDomains: [
      {
        id: customDomain.id
      }
    ]
    httpsRedirect: 'Enabled'
  }
  dependsOn: [
    origin
  ]
}

// Associate admin custom domain with the route
resource adminCustomDomainAssociation 'Microsoft.Cdn/profiles/afdEndpoints/routes@2025-06-01' = {
  parent: frontDoorEndpoint
  name: 'cdnr-admin-custom-scoutid-prod-sec-${uniqueString(resourceGroup().id)}'
  properties: {
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/admin/*'
    ]
    originGroup: {
      id: originGroup.id
    }
    forwardingProtocol: 'MatchRequest'
    customDomains: [
      {
        id: adminCustomDomain.id
      }
    ]
    httpsRedirect: 'Enabled'
  }
  dependsOn: [
    origin
  ]
}

// output frontDoorEndpointHostName string = frontDoorEndpoint.properties.hostName
