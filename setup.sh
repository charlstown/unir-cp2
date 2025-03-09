#!/bin/bash

# 🚀 Configure only the Resource Group
RESOURCE_GROUP="rg-weu-cp2-dev"

echo "🔍 Fetching Azure resources..."

# 🔹 Automatically get ACR name from the resource group
ACR_NAME=$(az acr list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)

# 🔹 Automatically get the VM name from the resource group
VM_NAME=$(az vm list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)

# 🔹 Get ACR credentials
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value -o tsv)

# 🔹 Get the public IP of the VM
VM_IP=$(az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv)

# 🔐 Export variables to the current session
echo "🔐 Saving credentials..."
export ACR_NAME="$ACR_NAME"
export ACR_USERNAME="$ACR_USERNAME"
export ACR_PASSWORD="$ACR_PASSWORD"
export VM_NAME="$VM_NAME"
export VM_IP="$VM_IP"

echo "✅ Done! Variables set for this session."
