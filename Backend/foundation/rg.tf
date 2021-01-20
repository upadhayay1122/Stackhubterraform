# resource "azurestack_resource_group" "rg" {
#   name = "MMTC_RG"
#   location = "azs001"
  
# }
#
# Resource Groups
#
# We recommend that you deploy all network and management resources in a single resource 
# group as there are interdependencies between these components.
#
# However, if you really want to use multiple resource groups, you can define an array
# of named resource groups
# Note: Just make sure that one, and only one is marked as "is_default = true".  This will
# be used for all resources where an alternative "resource_group_name" is not defined
#
# By default, we assume that all resource groups need to be created. However, If a client 
# requires you to deploy to existing resource groups, that can be achieved using a lookup.
# You just need to add
#   "lookup": true
# to your resource group config block in the input json.
#
# Logic overview:
# * Generate list of resource groups to lookup/create
# * Create resource group where lookup is not true
# * Look up references for ALL defined groups - these are used when building other 
#   resources
# * Identify the default resource group and store the reference for use as a default

# create a list of resource groups to create/lookup by combining
# defaults, inputs, fixed values and internal references  
locals {
  resource_groups = {
    for v in var.foundation.resource_groups : v.name => merge(
      {
        # overrideable defaults
        lookup     = false
        tags       = try(var.foundation.tags, {})
        is_default = false
      },
      v,
      {
        # fixed values and internal references
      }
    )
  }
}

# create new resource groups where "lookup" is not set to true 
resource "azurestack_resource_group" "resource_group" {
  for_each = {
    for k, v in local.resource_groups : k => v if ! v.lookup
  }

  name     = each.value.name
  location = each.value.location
  tags     = each.value.tags
}

# look the existing (or newly created) resource group to use as a reference for all
# other resource creations
data "azurestack_resource_group" "resource_group" {
  for_each = local.resource_groups
  name     = each.value.name

  depends_on = [azurestack_resource_group.resource_group]
}

# Obtain default resource group reference
#
# Note: I know this looks odd. We have to write the code this way to address issues 
# with the way Terraform builds dependency graphs.
# We need the resource group name reference from the data block to ensure that 
# Terraform builds a dependency between the new resource and the resource group
# We need the set the location based on input variables to ensure that Terraform
# knows the location at plan generation time. Without this, Terraform would
# destroy and recreate every resource on every deployment as it is unable to 
# verify that existing resources are built in the correct location
# The [0] on the end ensures that we don't end up with multiple defaults
# we aren't going to error check for this though
locals {
  default_resource_group = [
    for k, v in local.resource_groups : {
      name     = data.azurestack_resource_group.resource_group[k].name
      location = v.location
    } if v.is_default
  ][0]
}

# debug output
output "default_rg" {
  value = local.default_resource_group
}
/*
*/