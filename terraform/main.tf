terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
  azs                  = ["us-east-1a"]
  public_subnets       = ["10.3.1.0/24"]
  private_subnets      = ["10.3.101.0/24"]
  enable_dns_support   = true
  enable_dns_hostnames = true
}

