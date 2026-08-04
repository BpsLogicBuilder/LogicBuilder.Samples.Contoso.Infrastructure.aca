@description('Set the ACR Pull Role Definition ID')
param keyVaultCertificateUserRoleDefinitionID string = 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba'

@description('Specifies the name of the container app.')
param containerAppName string

@description('Generate a unique GUID to use as name for the role assignment')
var containerAppToKeyVaultRoleAssignmentName = guid(containerApp.id, keyVaultCertificateUserRoleDefinitionID, keyVault.id)

resource keyVault 'Microsoft.KeyVault/vaults@2026-02-01' existing = {
  name: 'bpsKvContoso'
}

resource containerApp 'Microsoft.App/containerApps@2026-01-01' existing = {
  name: containerAppName
}

resource containerAppToAcrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: containerAppToKeyVaultRoleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultCertificateUserRoleDefinitionID)
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
