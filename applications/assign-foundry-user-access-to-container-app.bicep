
@description('Specifies the foundry resource.')
param foundryAccountResourceName string

@description('Specifies the name of the container app.')
param containerAppName string

var foundryUserRoleDefinitionID string = '53ca6127-db72-4b80-b1b0-d745d6d5456d'

var containerAppToFoundryRoleAssignmentName = guid(containerApp.id, foundryUserRoleDefinitionID, foundryAccountResource.id)

resource foundryAccountResource 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: foundryAccountResourceName
}

resource containerApp 'Microsoft.App/containerApps@2026-01-01' existing = {
  name: containerAppName
}

resource containerAppToFoundryRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: foundryAccountResource
  name: containerAppToFoundryRoleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', foundryUserRoleDefinitionID)
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}