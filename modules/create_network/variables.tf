variable vpc_cidr { }
//create_vpcvariable subnets_per_create { type="list" }
variable az {  type = list }
variable "vpc_tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}
variable id_vpc { default = "" }
variable "vpc_name" {
  description = "Name to be used on the Default VPC"
}

variable "key_name_pem"{
  type = string
}
variable cidr_blocks_public {
  type = list
}
variable cidr_blocks_private {
  type = list
}

variable "igw_tags" {
  description = "Additional tags for the internet gateway"
  default     = {}
}