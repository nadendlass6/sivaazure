provider "azurerm" {
  features {}
  subscription_id = "245e37be-134c-4450-aa28-321d3ab38108"
}

resource "azurerm_resource_group" "linux_rg" {
  name     = "devopsrp"
  location = "West Europe"
  
}

resource "azurerm_virtual_network" "linux_vnet" {
  name                = "linux-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.linux_rg.location
  resource_group_name = azurerm_resource_group.linux_rg.name
}

resource "azurerm_subnet" "example_subnet" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.linux_rg.name
  virtual_network_name = azurerm_virtual_network.linux_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.linux_rg.name
  location            = azurerm_resource_group.linux_rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "example" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.linux_rg.location
  resource_group_name = azurerm_resource_group.linux_rg.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.linux_rg.location
  resource_group_name = azurerm_resource_group.linux_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example_subnet.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "devopsvm"
  resource_group_name = azurerm_resource_group.linux_rg.name
  location            = azurerm_resource_group.linux_rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

