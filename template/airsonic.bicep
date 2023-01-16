param uniqueId string = 'airsonic'
param location string = resourceGroup().location
param virtualMachineSize string = 'Standard_B1ms'

param subnetName string = '${uniqueId}-subnet'
param virtualNetworkName string = '${uniqueId}-vnet'

var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)

var networkInterfaceName = '${uniqueId}-nic'
var subnetRef = '${vnetId}/subnets/${subnetName}'
var publicIpAddressName = '${uniqueId}-pip'

resource publicIpAddress 'Microsoft.Network/publicIpAddresses@2020-08-01' = {
  name: publicIpAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
  sku: {
    name: publicIpAddressSku
  }
  tags: {
    demo: 'azure-migrate'
    app: 'airsonic'
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: networkInterfaceName
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', publicIpAddressName)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
  tags: {
    demo: 'azure-migrate'
    app: 'airsonic'
  }
  dependsOn: [
    networkSecurityGroup
    virtualNetwork
    publicIpAddress
  ]
}
