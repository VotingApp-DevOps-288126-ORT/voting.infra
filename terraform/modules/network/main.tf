module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  environment          = var.environment
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
}

module "public_subnets" {
  source        = "./modules/subnet"
  vpc_id        = module.vpc.id
  azs           = var.azs
  subnet_cidrs  = var.public_subnets
  subnet_type   = "public"
  map_public_ip = true
  environment   = var.environment
}

module "private_subnets" {
  source        = "./modules/subnet"
  vpc_id        = module.vpc.id
  azs           = var.azs
  subnet_cidrs  = var.private_subnets
  subnet_type   = "private"
  map_public_ip = false
  environment   = var.environment
}

module "internet_gateway" {
  source      = "./modules/internet-gateway"
  environment = var.environment
  vpc_id      = module.vpc.id
}

module "nat_gateway" {
  source      = "./modules/nat-gateway"
  environment = var.environment
  igw_id      = module.internet_gateway.id
  subnet_id   = module.public_subnets.ids[0]
}

module "public_route_table" {
  source      = "./modules/route-table"
  vpc_id      = module.vpc.id
  environment = var.environment
  subnet_ids  = module.public_subnets.ids
  gateway_id  = module.internet_gateway.id
  subnet_type = "public"
}

module "private_route_table" {
  source      = "./modules/route-table"
  vpc_id      = module.vpc.id
  environment = var.environment
  subnet_ids  = module.private_subnets.ids
  gateway_id  = module.nat_gateway.id
  subnet_type = "private"
}

module "nsg-vpc" {
  source      = "./modules/security-group"
  environment = var.environment
  vpc_id      = module.vpc.id
}

