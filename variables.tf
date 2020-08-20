variable "accesskey" {
    default  = ""
}
variable "secretkey" {
    default  = ""
}
variable "tags" {
  description = "tags for recognize te proyect"
  default     = {
    owner   =""
    proyecto =""
  }
}
variable "aws_region" {
  description = "Region for the VPC"
  default = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default = "10.0.0.0/16"
}

variable "ami" {
  description = "Centos 7.5"
  default     = "ami-006219aba10688d0b"
}

variable "key_path" {
  description = "SSH Public Key path"
  default = ""
}

variable "min_size"{
    default = 1
}

variable "max_size"{
    default = 6
}
variable "private_key"{
    default = ""
}

variable username {
  description = "DB username"
  default = ""
}

variable password {
  description = "DB password"
  default = ""
}

variable dbname {
  description = "db name"
  default = ""
}

variable "route53_public_dns_name"{
    type = "string"
    default= ""
}
