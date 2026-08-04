// Main Bicep template for Azure Container Apps Environment and 6 Apps
@description('The region to deploy all resources.')
param location string = resourceGroup().location

@description('Number of CPU cores the container can use. Can be with a maximum of two decimals.')
@allowed([
  '0.25'
  '0.5'
  '0.75'
  '1'
  '1.25'
  '1.5'
  '1.75'
  '2'
])
param cpuCore string = '0.5'

@description('Amount of memory (in gibibytes, GiB) allocated to the container up to 4GiB. Can be with a maximum of two decimals. Ratio with CPU cores must be equal to 2.')
@allowed([
  '0.5'
  '1'
  '1.5'
  '2'
  '3'
  '3.5'
  '4'
])
param memorySize string = '1'

@description('Minimum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param minReplicas int = 1

@description('Maximum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param maxReplicas int = 3

@description('The naming prefix for all resources.')
param prefix string = 'contoso'

@description('Specifies the docker container image to deploy.')
param placeholderImage string = 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'

@description('Specifies the container port.')
param targetPort int = 8080

// Variables
var uniqueSubString = uniqueString(resourceGroup().id)
var acrName = '${prefix}acr${uniqueSubString}'
var logAnalyticsWorkspaceName = '${prefix}-law-${uniqueSubString}'
var appInsightsName = '${prefix}-insights-${uniqueSubString}'
var containerAppEnvName = '${prefix}-cae-${uniqueSubString}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2026-01-01' = {
  name: containerAppEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

resource bslService 'Microsoft.App/containerApps@2026-01-01' = {
  name: '${prefix}-bsl-${uniqueSubString}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: false
        targetPort: targetPort
        transport: 'auto'
        clientCertificateMode:'require'
      }
    }
    template: {
      containers: [
        {
          name: 'bsl'
          image: placeholderImage
          resources: {
            cpu: json(cpuCore)
            memory: '${memorySize}Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsights.properties.ConnectionString
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

resource kendoBslService 'Microsoft.App/containerApps@2026-01-01' = {
  name: '${prefix}-kendo-bsl-${uniqueSubString}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: false
        targetPort: targetPort
        transport: 'auto'
        clientCertificateMode:'require'
      }
    }
    template: {
      containers: [
        {
          name: 'kendo-bsl'
          image: placeholderImage
          resources: {
            cpu: json(cpuCore)
            memory: '${memorySize}Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsights.properties.ConnectionString
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

resource apiService 'Microsoft.App/containerApps@2026-01-01' = {
  name: '${prefix}-api-${uniqueSubString}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        corsPolicy: {
          allowedOrigins: [
            'https://${prefix}-angular-${uniqueSubString}.azurewebsites.net'
          ]
          allowedMethods: [
            'GET'
            'POST'
            'PUT'
            'DELETE'
          ]
          allowedHeaders: [
            'Content-Type'
            'Authorization"'
          ]
          exposeHeaders: [
            '*'
          ]
          maxAge: 300
          allowCredentials: false
        }
      }
    }
    template: {
      containers: [
        {
          name: 'api'
          image: placeholderImage
          resources: {
            cpu: json(cpuCore)
            memory: '${memorySize}Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsights.properties.ConnectionString
            }
            {
              name: 'baseBslUrl'
              value: 'http://${bslService.properties.configuration.ingress.fqdn}'
            }
          ]
        }
      ]
    }
  }
}

resource kendoApiService 'Microsoft.App/containerApps@2026-01-01' = {
  name: '${prefix}-kendo-api-${uniqueSubString}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        corsPolicy: {
          allowedOrigins: [
            'https://${prefix}-angular-${uniqueSubString}.azurewebsites.net'
          ]
          allowedMethods: [
            'GET'
            'POST'
            'PUT'
            'DELETE'
          ]
          allowedHeaders: [
            'Content-Type'
            'Authorization"'
          ]
          exposeHeaders: [
            '*'
          ]
          maxAge: 300
          allowCredentials: false
        }
      }
    }
    template: {
      containers: [
        {
          name: 'kendo-api'
          image: placeholderImage
          resources: {
            cpu: json(cpuCore)
            memory: '${memorySize}Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsights.properties.ConnectionString
            }
            {
              name: 'baseBslUrl'
              value: 'http://${kendoBslService.properties.configuration.ingress.fqdn}'
            }
          ]
        }
      ]
    }
  }
}

resource workflowService 'Microsoft.App/containerApps@2026-01-01' = {
  name: '${prefix}-workflow-${uniqueSubString}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        corsPolicy: {
          allowedOrigins: [
            'https://${prefix}-angular-${uniqueSubString}.azurewebsites.net'
          ]
          allowedMethods: [
            'GET'
            'POST'
            'PUT'
            'DELETE'
          ]
          allowedHeaders: [
            'Content-Type'
            'Authorization"'
          ]
          exposeHeaders: [
            '*'
          ]
          maxAge: 300
          allowCredentials: false
        }
      }
    }
    template: {
      containers: [
        {
          name: 'workflow'
          image: placeholderImage
          resources: {
            cpu: json(cpuCore)
            memory: '${memorySize}Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsights.properties.ConnectionString
            }
          ]
        }
      ]
    }
  }
}

resource angularApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: '${prefix}-angular-${uniqueSubString}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: 'angular'
          image: placeholderImage
          resources: {
            cpu: json(cpuCore)
            memory: '${memorySize}Gi'
          }
          env: [
            {
              name: 'CRUD_URL'
              value: 'https://${apiService.properties.configuration.ingress.fqdn}'
            }
            {
              name: 'GRID_URL'
              value: 'https://${kendoApiService.properties.configuration.ingress.fqdn}'
            }
            {
              name: 'WORKFLOW_URL'
              value: 'https://${workflowService.properties.configuration.ingress.fqdn}'
            }
            {
              name: 'ENVIRONMENT_NAME'
              value: 'dev'
            }
          ]
        }
      ]
    }
  }
}

module bslServiceToAcrRoleAssignment './assign-acr-pull-to-container-app.bicep' = {
  name: 'bslServiceToAcrRoleAssignment'
  params: {
    containerAppName: bslService.name
  }
}

module apiServiceToAcrRoleAssignment './assign-acr-pull-to-container-app.bicep' = {
  name: 'apiServiceToAcrRoleAssignment'
  params: {
    containerAppName: apiService.name
  }
}

module kendoBslServiceToAcrRoleAssignment './assign-acr-pull-to-container-app.bicep' = {
  name: 'kendoBslServiceToAcrRoleAssignment'
  params: {
    containerAppName: kendoBslService.name
  }
}

module kendoApiServiceToAcrRoleAssignment './assign-acr-pull-to-container-app.bicep' = {
  name: 'kendoApiServiceToAcrRoleAssignment'
  params: {
    containerAppName: kendoApiService.name
  }
}

module workflowServiceToAcrRoleAssignment './assign-acr-pull-to-container-app.bicep' = {
  name: 'workflowServiceToAcrRoleAssignment'
  params: {
    containerAppName: workflowService.name
  }
}

module  angularAppToAcrRoleAssignment './assign-acr-pull-to-container-app.bicep' = {
  name: 'angularAppToAcrRoleAssignment'
  params: {
    containerAppName: angularApp.name
  }
}

module apiServiceToKeyVaultRoleAssignment './assign-key-vault-certificate-user-role-to-container-app.bicep' = {
  name: 'apiServiceToKeyVaultRoleAssignment'
  params: {
    containerAppName: apiService.name
  }
}

module kendoApiServiceToKeyVaultRoleAssignment './assign-key-vault-certificate-user-role-to-container-app.bicep' = {
  name: 'kendoApiServiceToKeyVaultRoleAssignment'
  params: {
    containerAppName: kendoApiService.name
  }
}

@description('Output the login server property for later use')
output acrLoginServer string = acr.properties.loginServer
