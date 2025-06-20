variable "subnet_ids" {
  type = list(string)
}

variable "role" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "desired_size" {
  type = number
}

variable "instance_types" {
  type = list(string)
}

variable "ec2_ssh_key" {
  type = string
}
