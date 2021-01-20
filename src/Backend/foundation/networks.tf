locals {
  networks = {
    for k, v in try(var.foundation.networks, {}) : k => merge(
      {
        # overrideable defaults
        lookup               = false
        nat_gateway_required = false
        subnets              = {}
        location             = local.default_resource_group.location
        resource_group_name  = local.default_resource_group.name
      },
      v
    )
  }
}

# create virtual networks
resource "azurestack_virtual_network" "networks" {
  for_each = {
    for k, v in local.networks : k => v if ! v.lookup
  }

  name                = each.key
  location            = each.value.location
  resource_group_name = data.azurestack_resource_group.resource_group[each.value.resource_group_name].name
  address_space       = each.value.address_space
}

# lookup virtual networks
data "azurestack_virtual_network" "networks" {
  for_each = local.networks

  name                = each.key
  resource_group_name = each.value.resource_group_name

  # depends on required as we may lookup an existing network
  depends_on = [azurestack_virtual_network.networks]
}

locals {
  subnets = {
    for entry in flatten([
      for network_key, network_data in local.networks : [
        for subnet_key, subnet_data in network_data.subnets :
        merge(
          {
            network = network_key
            subnet  = subnet_key
          },
          subnet_data,
          {
            resource_group_name  = azurestack_virtual_network.networks[network_key].resource_group_name
            virtual_network_name = azurestack_virtual_network.networks[network_key].name
          }
        )
      ]
    ]) : "${entry.network}-${entry.subnet}" => entry
  }
}

# create the subnets
resource "azurestack_subnet" "networks" {
  for_each = local.subnets

  resource_group_name  = data.azurestack_resource_group.resource_group[each.value.resource_group_name].name
  virtual_network_name = each.value.virtual_network_name
  name                 = each.value.subnet
  address_prefix     = each.value.address_prefixes
 
}

