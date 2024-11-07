#!/bin/bash

# Check if the required variables are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Usage: $0 <ResourceGroupName> <AKSClusterName> <ACRName>"
  exit 1
fi

RESOURCE_GROUP_NAME="$1"
AKS_CLUSTER_NAME="$2"
ACR_NAME="$3"

# Log in to Azure
echo "Logging in to Azure..."
az login
if [ $? -ne 0 ]; then
  echo "Failed to log in to Azure. Please check your credentials."
  exit 1
fi

# Connect to the AKS cluster
echo "Getting AKS credentials for cluster: $AKS_CLUSTER_NAME in resource group: $RESOURCE_GROUP_NAME..."
az aks get-credentials --resource-group "$RESOURCE_GROUP_NAME" --name "$AKS_CLUSTER_NAME"
if [ $? -ne 0 ]; then
  echo "Failed to get AKS credentials. Please ensure the resource group and cluster name are correct."
  exit 1
fi

echo "Successfully connected to AKS cluster: $AKS_CLUSTER_NAME"

# Get the object ID of the agent pool managed identity
AGENTPOOL_MI_ID=$(az aks show \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $AKS_CLUSTER_NAME \
  --query "identityProfile.kubeletidentity.objectId" \
  --output tsv)
echo "Agent Pool Managed Identity ID: $AGENTPOOL_MI_ID"

# Get the ACR Resource ID
ACR_ID=$(az acr show --name $ACR_NAME --query "id" --output tsv)
echo "ACR Resource ID: $ACR_ID"

# Remove the AcrPull role assignment for the AKS agent pool's managed identity on the ACR
echo "Removing the non-ABAC-enabled AcrPull role assignment (if it exists) for the AKS agent pool's managed identity (Object ID: $AGENTPOOL_MI_ID) on the ACR ($ACR_NAME)..."
az role assignment delete --assignee $AGENTPOOL_MI_ID --role "AcrPull" --scope $ACR_ID

# Assign the "Container Registry Repository Reader" role to the AKS agent pool's managed identity on the ACR with ABAC conditions.
# The ABAC conditions allow read access to the repository "ml/inferencing" and all child repositories under "ml/inferencing/".
# This allows the AKS agent pool's managed identity to only pull images from these allowed repositories.
echo "Assigning 'Container Registry Repository Reader' role to the AKS agent pool's managed identity (Object ID: $AGENTPOOL_MI_ID) on the ACR ($ACR_NAME) with ABAC conditions to only allow read access to 'ml/inferencing' repository and child repositories under 'ml/inferencing/'..."
az role assignment create \
  --assignee $AGENTPOOL_MI_ID \
  --role "Container Registry Repository Reader" \
  --scope $ACR_ID \
  --condition-version "2.0" \
  --condition "(
    (
      !(ActionMatches{'Microsoft.ContainerRegistry/registries/repositories/content/read'})
      AND
      !(ActionMatches{'Microsoft.ContainerRegistry/registries/repositories/metadata/read'})
    )
    OR
    (
      @Resource[Microsoft.ContainerRegistry/registries/repositories:name] StringEqualsIgnoreCase 'ml/inferencing'
      OR
      @Resource[Microsoft.ContainerRegistry/registries/repositories:name] StringStartsWithIgnoreCase 'ml/inferencing/'
    )
  )"

# Iterate over each Kubernetes deployment YAML and deploy the resources on the AKS cluster.
# Substitute the ACR name in the deployment YAML files before applying them.
export ACR_NAME="$ACR_NAME"
for file in ./deployments/*.yaml; do
  echo "Deploying resources from file: $file"
  envsubst < "$file" | kubectl apply -f -
done
