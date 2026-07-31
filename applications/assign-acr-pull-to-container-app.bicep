@description('Set the ACR Pull Role Definition ID')
param acrPullRoleDefinitionID string = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

@description('Specifies the name of the container app.')
param containerAppName string

@description('The naming prefix for all resources.')
param prefix string = 'contoso'

@description('Generate a unique GUID to use as name for the role assignment')
var containerAppToAcrRoleAssignmentName = guid(containerApp.id, acrPullRoleDefinitionID, acr.id)

var uniqueSubString = uniqueString(resourceGroup().id)
var acrName = '${prefix}acr${uniqueSubString}'

resource acr 'Microsoft.ContainerRegistry/registries@2025-11-01' existing = {
  name: acrName
}

resource containerApp 'Microsoft.App/containerApps@2022-06-01-preview' existing = {
  name: containerAppName
}

resource containerAppToAcrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: containerAppToAcrRoleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleDefinitionID)
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
