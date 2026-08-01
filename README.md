# LogicBuilder.Samples.Contoso.Infrastructure

This repository contains the Infrastructure as Code (IaC) for deploying a multi-tier Azure Container Apps environment for the Contoso sample application.

## Overview

The infrastructure is defined using Azure Bicep and provisions a complete microservices-based application architecture consisting of six containerized applications running on Azure Container Apps.

## Architecture

### Applications

The deployment includes six container applications:

1. **Angular Frontend** (`contoso-angular`) - A client-side web application that serves as the user interface
2. **Workflow Service** (`contoso-workflow`) - A workflow orchestration service
3. **API Service** (`contoso-api`) - A front-end API that communicates with the BSL backend
4. **Kendo API Service** (`contoso-kendo-api`) - A front-end API for Kendo UI components that communicates with the Kendo BSL backend
5. **BSL Service** (`contoso-bsl`) - An internal back-end business service layer
6. **Kendo BSL Service** (`contoso-kendo-bsl`) - An internal back-end business service layer for Kendo operations

### Communication Flow

- **Angular App** → Makes CORS-enabled requests to:
  - API Service (CRUD operations)
  - Kendo API Service (grid operations)
  - Workflow Service (workflow operations)

- **API Service** → Communicates internally with BSL Service over mTLS
- **Kendo API Service** → Communicates internally with Kendo BSL Service over mTLS

### Security

- **External Services**: Angular app, API Service, Kendo API Service, and Workflow Service are publicly accessible via HTTPS
- **Internal Services**: BSL Service and Kendo BSL Service are internal-only with mutual TLS (mTLS) client certificate requirement
- **CORS Policy**: Configured to allow the Angular app to make cross-origin requests to the API services
- **Identity**: All services use System Assigned Managed Identities
- **ACR Access**: Each container app has AcrPull role assignment for pulling images from the Azure Container Registry

## Infrastructure Components

- **Azure Container Apps Environment** - Managed environment for all container apps
- **Azure Container Registry (ACR)** - Private registry for container images (Basic SKU)
- **Application Insights** - Application performance monitoring and telemetry
- **Log Analytics Workspace** - Centralized logging with 30-day retention

## Deployment

### Parameters

- `location` - Azure region for deployment (defaults to resource group location)
- `cpuCore` - CPU allocation per container (0.25-2 cores, default: 0.5)
- `memorySize` - Memory allocation per container (0.5-4 GiB, default: 1)
- `minReplicas` - Minimum replica count (0-25, default: 1)
- `maxReplicas` - Maximum replica count (0-25, default: 3)
- `prefix` - Naming prefix for resources (default: 'contoso')
- `placeholderImage` - Initial placeholder image for deployment (default: mcr.microsoft.com/azuredocs/aci-helloworld:latest)
- `targetPort` - Container target port (default: 8080)

### Initial Deployment

All containers initially use a public placeholder image. After deployment, you can update each container app with your custom images from the provisioned Azure Container Registry.

### Prerequisites

- Azure subscription
- Azure CLI or PowerShell with Bicep support
- Resource group created

### Deploy Command

```
	az deployment group create 
		--resource-group <your-resource-group> 
		--template-file applications/contoso-apps.bicep
```

## Outputs

- `acrLoginServer` - The login server URL for the Azure Container Registry

## Related Repositories

This infrastructure repository is designed to support the LogicBuilder.Samples.Contoso application.