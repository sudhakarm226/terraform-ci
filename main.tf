provider "azurerm" {
  features {}
  subscription_id = "a95dbe9e-bf88-4327-88b8-f85c96e18436"
  #tenant_id = "6af5992f-c8b9-4f47-ba6e-f795ec682a52"
  #client_id = "533c0e52-4b6a-4b8c-8167-7f6c66d9742a"
  #client_secret = "rgy8Q~xLrwN1ptmTRTDJkRvTIXgApZ9ZPLb37cG6"
}


variable "vm_name" {
  type = string
}
resource "azurerm_resource_group" "az-rg" {
  name = "RG_VMs"
  location = "South India"
}

resource "azurerm_virtual_network" "az-vnet" {
    name = "manual-az-vm-vnet"
    location = azurerm_resource_group.az-rg.location
    resource_group_name = azurerm_resource_group.az-rg.name
    address_space = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "az-sub" {
  name = "default"
  resource_group_name = azurerm_resource_group.az-rg.name
  virtual_network_name = azurerm_virtual_network.az-vnet.name
  address_prefixes = azurerm_virtual_network.az-vnet.address_space
}


resource "azurerm_public_ip" "az-pip" {
  name                = "vm-public-ip"
  location            = azurerm_resource_group.az-rg.location
  resource_group_name = azurerm_resource_group.az-rg.name
  sku                 = "Basic"  # ✅ Must be Basic for Dynamic
  allocation_method   = "Dynamic"  # Can also be "Static" if you want a fixed IP
}

resource "azurerm_network_interface" "az-ni" {
    name = "manual-az-vm549"
    location = azurerm_resource_group.az-rg.location
    resource_group_name = azurerm_resource_group.az-rg.name
    ip_configuration {
      name = "ipconfig1"
      subnet_id = azurerm_subnet.az-sub.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.az-pip.id

    }
    depends_on = [ azurerm_subnet.az-sub ]
}

resource "azurerm_linux_virtual_machine" "new-vm" {
  resource_group_name = azurerm_resource_group.az-rg.name
  network_interface_ids = [azurerm_network_interface.az-ni.id]
  admin_username = "azureuser"
  admin_password = "azureuser@123"
  disable_password_authentication = false
  location = azurerm_resource_group.az-rg.location
  name = var.vm_name
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  size = "Standard_B1s"
}
