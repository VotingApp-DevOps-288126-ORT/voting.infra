variable "vpc_id" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "subnet_cidrs" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "subnet_type" {
  type = string
}

variable "map_public_ip" {
  type = bool
}


