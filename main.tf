# Author: Nathan Nellans (me@nathannellans.com)

terraform {
  required_version = "~> 0.14.0"  # Pin the version of terraform to the 0.14.x family
  required_providers {            # Pin the version of the providers in use
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#----------------------------------
# Resource Group
#----------------------------------
resource "azurerm_resource_group" "wvd_rg" {
  name     = "ResourceGroupNameGoesHere"
  location = "Central US"
}

#----------------------------------
# WVD Resources
#----------------------------------

# WVD Host Pool Example #1 - Using type of 'Pooled'
resource "azurerm_virtual_desktop_host_pool" "wvd_pool1" {
  name                             = "HostPool1NameGoesHere"
  resource_group_name              = azurerm_resource_group.wvd_rg.name
  location                         = azurerm_resource_group.wvd_rg.location
  type                             = "Pooled"
  load_balancer_type               = "BreadthFirst"        # Options: BreadthFirst / DepthFirst
  friendly_name                    = "First WVD Pool"
  description                      = "Short description of the first Host Pool"
  validate_environment             = false
  maximum_sessions_allowed         = 1

  registration_info {
    expiration_date = "2021-03-01T08:00:00Z"               # Must be set to a time between 1 hour in the future & 27 days in the future
  }
}

# WVD Host Pool Example #2 - Using type of 'Personal'
resource "azurerm_virtual_desktop_host_pool" "wvd_pool2" {
  name                             = "HostPool2NameGoesHere"
  resource_group_name              = azurerm_resource_group.wvd_rg.name
  location                         = azurerm_resource_group.wvd_rg.location
  type                             = "Personal"
  load_balancer_type               = "Persistent"
  personal_desktop_assignment_type = "Automatic"           # Options: Automatic / Direct
  friendly_name                    = "Second WVD Pool"
  description                      = "Short description of the second Host Pool"
  validate_environment             = false
  maximum_sessions_allowed         = 1

  registration_info {
    expiration_date = "2021-03-01T08:00:00Z"               # Must be set to a time between 1 hour in the future & 27 days in the future
  }
}

# WVD App Group Example #1 - Default Desktop Application Group (DAG)
resource "azurerm_virtual_desktop_application_group" "wvd_app_group1" {
  name                = "AppGroup1NameGoesHere"
  resource_group_name = azurerm_resource_group.wvd_rg.name
  location            = azurerm_resource_group.wvd_rg.location
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.wvd_pool1.id
  friendly_name       = "First WVD App Group"
  description         = "Short description of the first App Group"
}

# WVD App Group Example #2 - RemoteApp Application Group (RAG)
resource "azurerm_virtual_desktop_application_group" "wvd_app_group2" {
  name                = "AppGroup2NameGoesHere"
  resource_group_name = azurerm_resource_group.wvd_rg.name
  location            = azurerm_resource_group.wvd_rg.location
  type                = "RemoteApp"
  host_pool_id        = azurerm_virtual_desktop_host_pool.wvd_pool1.id
  friendly_name       = "Second WVD App Group"
  description         = "Short description of the second App Group"
}

# Assign Azure AD users/groups to App Groups
resource "azurerm_role_assignment" "wvd_role_assignment1" {
  scope                = azurerm_virtual_desktop_application_group.wvd_app_group1.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = "Azure AD Object ID of User / Group"
}

# WVD Workspace
resource "azurerm_virtual_desktop_workspace" "wvd_workspace1" {
  name                = "Workspace1NameGoesHere"
  resource_group_name = azurerm_resource_group.wvd_rg.name
  location            = azurerm_resource_group.wvd_rg.location
  friendly_name       = "First WVD Workspace"
  description         = "Short description of the first Workspace"
}

# Connect App Groups to Workspaces
resource "azurerm_virtual_desktop_workspace_application_group_association" "wvd_workspace_appgroup" {
  workspace_id         = azurerm_virtual_desktop_workspace.wvd_workspace1.id
  application_group_id = azurerm_virtual_desktop_application_group.wvd_app_group1.id
}

#----------------------------------
# Session Host VM
#----------------------------------

# Create a NIC for the Session Host VM
resource "azurerm_network_interface" "wvd_vm1_nic" {
  name                = "NicNameGoesHere"
  resource_group_name = azurerm_resource_group.wvd_rg.name
  location            = azurerm_resource_group.wvd_rg.location

  ip_configuration {
    name                          = "IpConfigNameGoesHere"
    subnet_id                     = "Azure Subnet ID to attach the NIC to"
    private_ip_address_allocation = "dynamic"
  }
}

# Create the Session Host VM
resource "azurerm_windows_virtual_machine" "wvd_vm1" {
  name                  = "VMNameGoesHere"
  resource_group_name   = azurerm_resource_group.wvd_rg.name
  location              = azurerm_resource_group.wvd_rg.location
  size                  = "Standard_B1s"
  network_interface_ids = [ azurerm_network_interface.wvd_vm1_nic.id ]
  provision_vm_agent    = true
  timezone              = "Central Standard Time"
  
  admin_username = "localadmin"
  admin_password = "LocalPass2021"
    
  os_disk {
    name                 = "DiskNameGoesHere"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  boot_diagnostics {
    storage_account_uri = ""                               # Passing a null value will utilize a Managed Storage Account to store Boot Diagnostics
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-evd"                                 # This is the Windows 10 Enterprise Multi-Session image
    version   = "latest"
  }
}

# VM Extension for Domain-join
resource "azurerm_virtual_machine_extension" "vm1ext_domain_join" {
  name                       = "ExtensionName1GoesHere"
  virtual_machine_id         = azurerm_windows_virtual_machine.wvd_vm1.id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "Name": "domain.com",
      "OUPath": "OU=secondlevel,OU=firstlevel,DC=domain,DC=com",
      "User": "AdminUsername@domain.com",
      "Restart": "true",
      "Options": "3"
    }
    SETTINGS

  protected_settings = <<-PSETTINGS
    {
      "Password":"AdminPasswordGoesHere"
    }
    PSETTINGS

  lifecycle {
    ignore_changes = [ settings, protected_settings ]
  }
}

# VM Extension for Desired State Config
resource "azurerm_virtual_machine_extension" "vm1ext_dsc" {
  name                       = "ExtensionName2GoesHere"
  virtual_machine_id         = azurerm_windows_virtual_machine.wvd_vm1.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  
  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "hostPoolName": "HostPool1NameGoesHere",
        "registrationInfoToken": "${azurerm_virtual_desktop_host_pool.wvd_pool1.registration_info[0].token}"
      }
    }
    SETTINGS

  lifecycle {
    ignore_changes = [ settings ]
  }

  depends_on = [ azurerm_virtual_machine_extension.ext_domain_join ]
}
