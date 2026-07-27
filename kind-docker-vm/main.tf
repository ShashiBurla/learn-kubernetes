terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
  }
}
resource "azurerm_public_ip" "main" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "${var.vm_name}-nic"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                  = "${var.vm_name}-vm"
  location              = var.location
  resource_group_name   = var.resource_group
  network_interface_ids = [azurerm_network_interface.main.id]
  size                  = "Standard_D2s_v3"

  source_image_id = var.image_id
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_password = "Shashi@80999"
  admin_username = "burlash"

  disable_password_authentication = false

  secure_boot_enabled = true
  vtpm_enabled        = true

}

output "ip" {
  value = azurerm_public_ip.main.ip_address
}

resource "null_resource" "kind-setup" {
  depends_on = [azurerm_linux_virtual_machine.main, azurerm_subnet_network_security_group_association.nsg_association]

  provisioner "remote-exec" {
    connection {
      host     = azurerm_public_ip.main.ip_address
      user     = "burlash"
      password = "Shashi@80999"
      type     = "ssh"
    }

    inline = [
      "sudo dnf -y install dnf-plugins-core",
      "sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo",
      "sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -a -G docker devops",
      "sudo curl -Lo /bin/kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64",
      "sudo curl -Lo /bin/kubectl https://dl.k8s.io/release/v1.36.1/bin/linux/amd64/kubectl",
      "sudo chmod ugo+x /bin/kind /bin/kubectl",
      "sudo kind create cluster --name rhel10-cluster"
    ]

  }
}
# Create the Network Security Group
resource "azurerm_network_security_group" "main_nsg" {
  name                = "main-nsg"
  location            = var.location
  resource_group_name = var.resource_group

  # Allow HTTP traffic (Port 80)
  security_rule {
    name                       = "Allow-HTTP-80"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow SSH traffic (Port 22)
  security_rule {
    name                       = "Allow-SSH-22"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" # For better security, replace with your specific IP (e.g., "203.0.113.50/32")
    destination_address_prefix = "*"
  }
}

# Associate NSG to a Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.main_nsg.id
}
