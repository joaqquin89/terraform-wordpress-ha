variable "server_port" {
  type        = number
  default     = 8080
}

variable "elb_name" {
  type        = "string"
}

#variable "type_lb" {
#  type        = "string"
#}

variable  "subnets_id"{
   type = "list"
}
variable vpc_id {
    type = "string"
}

variable "tags_loadbancer" {
  description = "A map of tags to add to all resources"
  default     = {}
}
