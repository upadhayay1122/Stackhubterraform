# defintion of the Azure provider version
# Terraform backend configuration for remote state file
# update key for your specific deployment
# terraform {
#   backend "azurerm" {
#     key = "sc99/foundation.tfstate"
#   }
# }

provider "azurestack" {
    arm_endpoint = var.arm_endpoint
    subscription_id = var.subscription_id
    client_id = var.client_id
    client_secret = var.client_secret
    tenant_id = var.tenant_id
    
}

/*
data "azurerm_client_config" "current" {}

#use provider for different subscription 
provider "azurerm" {
  alias   = "remote"
  version = ">=2.0.0"
  features {}
  #subscription_id            = var.remote_subscription_id != null ? var.remote_subscription_id : data.azurerm_client_config.current.subscription_id
  #skip_provider_registration = var.skip_provider_registration
}
*/

variable "foundation" {}
variable "arm_endpoint" {}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

  


module "foundation" {
  # Choose the module source: options listed in order of recommended preference
  #source = "git::ssh://git@innersource.accenture.com/iasc/cloudbuilder-terraform.git//modules/azure/network?ref=v20200612.1"
#   source  = "C:/Users/gaurav.upadhyaya/Azure Stack Hub/Terraformcode/Backend/foundation"
    source  = "../../../Backend/foundation"
    foundation = var.foundation

  
}