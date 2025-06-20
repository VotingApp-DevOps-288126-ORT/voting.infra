output "public_subnet_ids" {
  value = module.public_subnets.ids
}

output "private_subnet_ids" {
  value = module.private_subnets.ids
}
