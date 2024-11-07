# Azure Container Registry - Attribute-Based Access Control (ABAC) Entra Repository Permissions

This repository demonstrates how to configure Azure Container Registry (ACR) with Attribute-Based Access Control (ABAC), using Entra ID for fine-grained repository permissions management. Please refer to [Azure Container Registry - Attribute-Based Access Control (ABAC) Entra Repository Permissions (Private Preview)](https://github.com/Azure/acr/tree/main/docs/preview/abac-repo-permissions).

* It includes a script to set up the ACR and populate it with sample images, before onboarding the registry to ABAC Entra authentication mode.
  * Warning: Onboarding to ABAC Entra authentication mode renders existing Azure Container Registry roles, such as AcrPull, AcrPush, and AcrDelete, non-functional. This is because ACR ABAC Entra authentication mode replaces the old ACR roles with new ABAC-enabled roles.
* It also includes a script that performs a role assignment for an Azure Kubernetes Service cluster, selectively granting the AKS cluster to only have pull permissions for specific repositories in ACR. This is achieved by including ABAC conditions during the role assignment.

## Prerequisites

* Azure CLI installed and logged in
* An existing Azure subscription with a test Azure Container Registry and an Azure Kubernetes Service cluster.
* Sufficient permissions to perform operations on the ACR registry and AKS cluster.
* Sufficient permissions to perform role assignments in Azure Entra ID.

# Setup Instructions

1. Clone this repository to your local machine.

```bash
git clone https://github.com/johnsonshi/acr-abac-demo.git
cd acr-abac-demo
```

2. Run the script to populate the ACR with sample images and configure it for ABAC Entra authentication mode.

```bash
./setup-acr-abac-demo.sh <ACRName>
```

3. Run the script to perform a role assignment for the AKS cluster, granting it pull permissions for specific repositories in ACR. Feel free to modify the ABAC conditions in this script to suit your repository permissions requirements.

```bash
./setup-aks-acr-abac-demo.sh <ResourceGroupName> <AKSClusterName> <ACRName>
```

4. Navigate to the Azure Portal and verify that the role assignment has been successfully created.

* Navigate to the ACR registry's "Access control (IAM)" blade and verify that the role assignment for the role "Container Registry Repository Reader" has been successfully created.
* Inspect the role assignment's ABAC conditions to verify that the role assignment is scoped to specific repositories in the ACR registry.

5. Navigate to the Azure Portal and verify that the AKS cluster is only able to pull images from the specific repositories in ACR.

* Navigate to the AKS cluster's "Kubernetes resources" -> "Workloads" blade and select the "default" namespace.
* Verify that the AKS cluster is only able to pull images from the specific repositories in ACR.
* The pods with images from repositories that the AKS cluster does not have pull permissions for should fail to start, whereas the pods with images from repositories that the AKS cluster has pull permissions for should start successfully.

## Further Reading

* [Azure Container Registry - Attribute-Based Access Control (ABAC) Entra Repository Permissions (Private Preview)](https://github.com/Azure/acr/tree/main/docs/preview/abac-repo-permissions)
