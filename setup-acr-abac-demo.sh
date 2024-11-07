#!/bin/bash

# Check if an Azure Container Registry is provided
if [ -z "$1" ]; then
  echo "No Azure Container Registry name provided. Please pass in an ACR name."
  exit 1
fi

ACR_NAME="$1"

# Log in to Azure
echo "Logging in to Azure..."
az login
if [ $? -ne 0 ]; then
  echo "Failed to log in to Azure. Please check your credentials."
  exit 1
fi

# Log in to the Azure Container Registry
echo "Logging in to Azure Container Registry: '$ACR_NAME'..."
az acr login --name "$ACR_NAME"
if [ $? -ne 0 ]; then
  echo "Failed to log in to Azure Container Registry: '$ACR_NAME'. Please ensure the registry name is correct and you have the right permissions."
  exit 1
fi

echo "Successfully logged in to ACR registry: $ACR_NAME"


# Pull an nginx image from Docker Hub
docker pull docker.io/library/nginx:latest

# Create an array of image names to push to the Azure Container Registry
IMAGES=(
    "$ACR_NAME.azurecr.io/infra/webapp/backend:latest"
    "$ACR_NAME.azurecr.io/infra/webapp/frontend:latest"
    "$ACR_NAME.azurecr.io/ml/inferencing/infra:latest"
    "$ACR_NAME.azurecr.io/ml/inferencing/testing:latest"
    "$ACR_NAME.azurecr.io/ml/inferencing/tooling:latest"
    "$ACR_NAME.azurecr.io/ml/inferencing:latest"
    "$ACR_NAME.azurecr.io/ml/training/base:latest"
    "$ACR_NAME.azurecr.io/ml/training/tooling:latest"
    "$ACR_NAME.azurecr.io/ml/training:latest"
)

# Tag the nginx image with the ACR name. After this, the image can be pushed to the ACR.
for IMAGE in "${IMAGES[@]}"; do
  echo "Tagging and pushing image: $IMAGE"
  docker tag docker.io/library/nginx:latest "$IMAGE"
  docker push "$IMAGE"
done

# Enable ABAC Repository Permissions Role Assignment Mode on the Azure Container Registry
echo "Enabling ABAC Repository Permissions Role Assignment Mode on the Azure Container Registry $ACR_NAME..."
az acr update -n "$ACR_NAME" --role-assignment-mode AbacRepositoryPermissions
if [ $? -ne 0 ]; then
  echo "Failed to enable ABAC Repository Permissions Role Assignment Mode on the Azure Container Registry $ACR_NAME. Please ensure you have the correct CLI version and that your subscription is registered for the ACR ABAC Preview. Please refer to https://github.com/Azure/acr/tree/main/docs/preview/abac-repo-permissions"
  exit 1
fi
