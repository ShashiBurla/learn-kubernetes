variable "resource_group" {
  default = "devops-practiece" 
}
variable "location" {
  default = "Denmark East"
}
variable "image_id" {
  default = "/subscriptions/e890e2a1-2eca-4c0b-8e51-dd98c583dd43/resourceGroups/devops-practiece/providers/Microsoft.Compute/galleries/rhel10.1/images/1.0.0"
}
variable "subnet_id" {
  default = "/subscriptions/e890e2a1-2eca-4c0b-8e51-dd98c583dd43/resourceGroups/devops-practiece/providers/Microsoft.Network/virtualNetworks/terraform-vnet/subnets/default"
}
variable "vm_name" {
  default = "docker"
}
