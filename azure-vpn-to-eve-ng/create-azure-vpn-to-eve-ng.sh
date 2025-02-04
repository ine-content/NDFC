#!/bin/bash
#
# Run this script from an Azure Bash Cloud Shell to create a VPN 
# from Cisco Nexus Dashboard in Azure to EVE-NG in INE's Lab Cloud. 
#
# Replace 1.2.3.4 with the Public IP Address shown in 
# the EVE-NG lab topology launched from my.ine.com
#
# Update other variables as necessary, such as RESOURCE_GROUP and LOCATION
#

# Variables
LOCAL_GATEWAY_IP="1.2.3.4"  # Replace 1.2.3.4 with EVE-NG Public IP Address
RESOURCE_GROUP="MyResourceGroup" # Replace MyResourceGroup with your Resource Group Name
LOCATION="eastus" # Location defaults to US East, update if needed
VNET_NAME="NexusDashboard-VN" # Virtual Network you created during Nexus Dashboard deployment
NEW_SUBNET="10.200.1.0/24" # Unique address space for VPN to EVE-NG
GATEWAY_SUBNET="10.200.1.0/27" # Address for GatewaySubnet object
GATEWAY_NAME="NexusDashboard-VPN"
PUBLIC_IP_NAME="${GATEWAY_NAME}-PIP"
LOCAL_GATEWAY_NAME="NexusDashboard-to-EVE-NG"
LOCAL_ADDRESS_SPACE="10.199.199.0/24" # MGMT0 subnet for N9Kv's in EVE-NG
CONNECTION_NAME="NexusDashboard-to-EVE-NG-Connection"

# Verify the Virtual Network exists
 az network vnet show  \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME

# Add IP address space to Virtual Network for GatewaySubnet 
az network vnet update \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --add addressSpace.addressPrefixes $NEW_SUBNET

# Verify the new IP address space was added
 az network vnet show  \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME

# Create the GatewaySubnet
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name GatewaySubnet \
  --address-prefixes $GATEWAY_SUBNET

# Verify the GatewaySubnet was created 
az network vnet subnet show \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name GatewaySubnet

# Create the public IP for the Virtual Network Gateway
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name $PUBLIC_IP_NAME \
  --sku Standard \
  --allocation-method Static \
  --location $LOCATION \
  --zone 1 2 3

# Verify the public IP was created
az network public-ip show \
  --resource-group $RESOURCE_GROUP \
  --name $PUBLIC_IP_NAME

# Create the Virtual Network Gateway
az network vnet-gateway create \
  --resource-group $RESOURCE_GROUP \
  --name $GATEWAY_NAME \
  --vnet $VNET_NAME \
  --public-ip-address $PUBLIC_IP_NAME \
  --gateway-type Vpn \
  --vpn-type RouteBased \
  --sku VpnGw2AZ \
  --location $LOCATION \
  --no-wait

# Verify the Virtual Network Gateway was created
az network vnet-gateway show \
  --resource-group $RESOURCE_GROUP \
  --name $GATEWAY_NAME

# Create the Local Network Gateway
az network local-gateway create \
  --resource-group $RESOURCE_GROUP \
  --name $LOCAL_GATEWAY_NAME \
  --gateway-ip-address $LOCAL_GATEWAY_IP \
  --local-address-prefixes $LOCAL_ADDRESS_SPACE \
  --location $LOCATION

# Verify the Local Network Gateway was created
az network local-gateway show \
  --resource-group $RESOURCE_GROUP \
  --name $LOCAL_GATEWAY_NAME

# Create the connection between the Virtual Network Gateway and the Local Network Gateway
az network vpn-connection create \
  --resource-group $RESOURCE_GROUP \
  --name $CONNECTION_NAME \
  --vnet-gateway1 $GATEWAY_NAME \
  --local-gateway2 $LOCAL_GATEWAY_NAME \
  --shared-key "cisco1234"

# Verify the connection was created 
az network vpn-connection show \
  --resource-group $RESOURCE_GROUP \
  --name $CONNECTION_NAME
