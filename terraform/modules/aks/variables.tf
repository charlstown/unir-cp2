variable "aks_name" {}
variable "resource_group" {}
variable "location" {}
variable "dns_prefix" {}
variable "node_count" {}
variable "vm_size" {}
variable "acr_id" {}
variable "tags" {
  type = map(string)
}