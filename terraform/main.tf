terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    bucket = "voting.backend"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}

# ECR 

module "voting_vote_ecr" {
  source      = "./modules/ecr"
  application = "voting_vote"
}

module "voting_result_ecr" {
  source      = "./modules/ecr"
  application = "voting_result"
}

module "voting_worker_ecr" {
  source      = "./modules/ecr"
  application = "voting_worker"
}

# Networks

module "voting_prod_network" {
  source               = "./modules/network"
  vpc_cidr             = "10.1.0.0/16"
  environment          = "prod"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnets       = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets      = ["10.1.101.0/24", "10.1.102.0/24"]
  enable_dns_support   = true
  enable_dns_hostnames = true
}

module "voting_test_network" {
  source               = "./modules/network"
  vpc_cidr             = "10.2.0.0/16"
  environment          = "test"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnets       = ["10.2.1.0/24", "10.2.2.0/24"]
  private_subnets      = ["10.2.101.0/24", "10.2.102.0/24"]
  enable_dns_support   = true
  enable_dns_hostnames = true
}

module "voting_dev_network" {
  source               = "./modules/network"
  vpc_cidr             = "10.3.0.0/16"
  environment          = "dev"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnets       = ["10.3.1.0/24", "10.3.2.0/24"]
  private_subnets      = ["10.3.101.0/24", "10.3.102.0/24"]
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# EKS

module "voting_prod_cluster_eks" {
  source             = "./modules/eks"
  environment        = "prod"
  region             = var.region
  public_subnet_ids  = module.voting_prod_network.public_subnet_ids
  private_subnet_ids = module.voting_prod_network.private_subnet_ids
  desired_size       = 2
  max_size           = 3
  min_size           = 1
  instance_types     = ["t3.small"]
}

module "voting_test_cluster_eks" {
  source             = "./modules/eks"
  environment        = "test"
  region             = var.region
  public_subnet_ids  = module.voting_test_network.public_subnet_ids
  private_subnet_ids = module.voting_test_network.private_subnet_ids
  desired_size       = 2
  max_size           = 3
  min_size           = 1
  instance_types     = ["t3.small"]
}


module "voting_dev_cluster_eks" {
  source             = "./modules/eks"
  environment        = "dev"
  region             = var.region
  public_subnet_ids  = module.voting_dev_network.public_subnet_ids
  private_subnet_ids = module.voting_dev_network.private_subnet_ids
  desired_size       = 2
  max_size           = 3
  min_size           = 1
  instance_types     = ["t3.small"]
}


# Api Gateway

module "voting_api_gateway" {
  source = "./modules/api_gateway/"
  name   = "voting-api"

  dev_subnet_ids  = module.voting_dev_network.private_subnet_ids
  test_subnet_ids = module.voting_test_network.private_subnet_ids
  prod_subnet_ids = module.voting_prod_network.private_subnet_ids

  dev_security_group_ids  = [module.voting_dev_network.sg_id]
  test_security_group_ids = [module.voting_test_network.sg_id]
  prod_security_group_ids = [module.voting_prod_network.sg_id]

  dev_ingress_dns  = module.voting_dev_cluster_eks.voting_ingress_hostname
  test_ingress_dns = module.voting_test_cluster_eks.voting_ingress_hostname
  prod_ingress_dns = module.voting_prod_cluster_eks.voting_ingress_hostname
}
