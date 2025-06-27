variable "name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "ingress_dns_result" {
  type = string
}

variable "ingress_dns_vote" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

