variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "gateway_id" {
  type = string
}

variable "subnet_type" {
  type = string
}

variable "environment" {
  type = string
}
