variable "name" {
  type = string
}

variable "dev_subnet_ids" {
  type = list(string)
}

variable "test_subnet_ids" {
  type = list(string)
}

variable "prod_subnet_ids" {
  type = list(string)
}

variable "dev_ingress_dns" {
  type = string
}

variable "test_ingress_dns" {
  type = string
}

variable "prod_ingress_dns" {
  type = string
}

variable "dev_security_group_ids" {
  type = list(string)
}

variable "test_security_group_ids" {
  type = list(string)
}

variable "prod_security_group_ids" {
  type = list(string)
}
