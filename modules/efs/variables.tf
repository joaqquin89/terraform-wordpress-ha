variable "efs_name" {
  type        = "string"
}

variable  "subnet_id"{
   type = "string"
}

variable  "subnet_sg"{
   type = "list"
}
variable "vpc_id"{
    type = "string"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}
