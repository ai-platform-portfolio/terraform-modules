variable "aks_cluster_id" { type = string }
variable "name_prefix" { type = string }
variable "spot_max_price" { type = number }
variable "tags" {
  type    = map(string)
  default = {}
}
