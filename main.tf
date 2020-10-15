provider "azurerm" {
  subscription_id = ""
  client_id       = ""
  client_secret   = ""
  tenant_id       = ""
  version = "2.31.1"
  features {}
}

resource "azurerm_resource_group" "rg" {
  name = "terraform"
  location = "West Europe"
}



#__________________________________________________________________

#Creating VNET1 and VSUB1

resource "azurerm_virtual_network" "VNET1" {
  name                = "VNET1"
  location            = "West Europe"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["8.8.8.8", "1.1.1.1"]
}

resource "azurerm_subnet" "VSUB1" {
  name                 = "VSUB1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.VNET1.name
  address_prefixes     = ["10.0.0.0/16"]
}

#Creating VNET2 and VSUB2

resource "azurerm_virtual_network" "VNET2" {
  name                = "VNET2"
  location            = "West Europe"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["192.168.0.0/16"]
  dns_servers         = ["8.8.8.8", "1.1.1.1"]
}

resource "azurerm_subnet" "VSUB2" {
  name                 = "VSUB2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.VNET2.name
  address_prefixes     = ["192.168.0.0/16"]
}


#_____________________________________________________________________

# VNET1 and VNET1 peering

resource "azurerm_virtual_network_peering" "peer1" {
  name                      = "peer1to2"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.VNET1.name
  remote_virtual_network_id = azurerm_virtual_network.VNET2.id
}

resource "azurerm_virtual_network_peering" "peer2" {
  name                      = "peer2to1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.VNET2.name
  remote_virtual_network_id = azurerm_virtual_network.VNET1.id
}





#_________________________________________________________________________

# Creating public IP

resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "West Europe"
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform"
    }
}

#_______________________________________________________________________

# Creating Network Security Group NSG1


resource "azurerm_network_security_group" "NSG1" {
    name                = "NSG1"
    location            = "West Europe"
    resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefixes      = ["86.57.255.0/24","141.136.72.240/32"]
        destination_address_prefix = "*"
    }

    security_rule {
        name                        = "Internet"
        priority                    = 100
        direction                   = "Outbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "*"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
}

    security_rule {
      name                       = "icmp"
      priority                   = 101
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "ICMP"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefixes      = ["86.57.255.0/24","141.136.72.240/32"]
      destination_address_prefix = "*"
}


    tags = {
        environment = "Terraform security group NSG1"
    }
}


# Creating Network Security Group NSG2

resource "azurerm_network_security_group" "NSG2" {
    name                = "NSG2"
    location            = "West Europe"
    resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "10.0.2.5/32"
        destination_address_prefix = "*"
    }

    security_rule {
        name                        = "Internet"
        priority                    = 100
        direction                   = "Outbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "*"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
}

    security_rule {
       name                       = "icmp"
       priority                   = 101
       direction                  = "Inbound"
       access                     = "Allow"
       protocol                   = "icmp"
       source_port_range          = "*"
       destination_port_range     = "*"
       source_address_prefix      = "10.0.2.5/32"
       destination_address_prefix = "*"
}

    tags = {
        environment = "Terraform security NSG2"
    }
}



#_______________________________________________________________________________


# Creating NIC for bastion


resource "azurerm_network_interface" "bastion" {
    name                        = "bastionNIC"
    location                    = "West Europe"
    resource_group_name         = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "myNicConfigurationbastion"
        subnet_id                     = azurerm_subnet.VSUB1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.2.5"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = "Terraform NIC for Bastion"
    }
}

# Connecting the security group to the network interface

resource "azurerm_network_interface_security_group_association" "bastion" {
    network_interface_id      = azurerm_network_interface.bastion.id
    network_security_group_id = azurerm_network_security_group.NSG1.id
}

# Creating NIC for internal


resource "azurerm_network_interface" "internal" {
    name                        = "internalNIC"
    location                    = "West Europe"
    resource_group_name         = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "myNicConfigurationinternal"
        subnet_id                     = azurerm_subnet.VSUB2.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "192.168.2.5"
    }

    tags = {
        environment = "Terraform NIC for internal"
    }
}


# Connecting the security group to the network interface

resource "azurerm_network_interface_security_group_association" "internal" {
    network_interface_id      = azurerm_network_interface.internal.id
    network_security_group_id = azurerm_network_security_group.NSG2.id
}





#___________________________________________________________


# Creating virtual machine Bastion

resource "tls_private_key" "bastion_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

output "tls_private_key_bastion" { value = tls_private_key.bastion_ssh.private_key_pem }

resource "azurerm_linux_virtual_machine" "bastion" {
    name                  = "bastion"
    location              = "West Europe"
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.bastion.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDiskBastion"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Debian"
        offer     = "debian-10"
        sku       = "10"
        version   = "latest"
    }

    computer_name  = "bastion"
    admin_username = "bastion"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "bastion"
        public_key     = tls_private_key.bastion_ssh.public_key_openssh
    }


    tags = {
        environment = "Terraform bastion"
    }
}


# Creating virtual machine Internal


resource "tls_private_key" "internal_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

output "tls_private_key_internal" { value = tls_private_key.internal_ssh.private_key_pem }

resource "azurerm_linux_virtual_machine" "internal" {
    name                  = "internal"
    location              = "West Europe"
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.internal.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDiskInternal"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Debian"
        offer     = "debian-10"
        sku       = "10"
        version   = "latest"
    }

    computer_name  = "internal"
    admin_username = "internal"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "internal"
        public_key     = tls_private_key.internal_ssh.public_key_openssh
    }


    tags = {
        environment = "internal"
    }
}

#_______________________________


#Route table for internal host



resource "azurerm_route_table" "example" {
  name                          = "routtableinternal"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "route1"
    address_prefix = "192.160.0.0/16"
    next_hop_type  = "internet"
  }

  tags = {
    environment = "Production"
  }
}
