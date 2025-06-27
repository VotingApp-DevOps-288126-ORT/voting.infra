data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

module "eks_cluster" {
  source             = "./modules/cluster"
  environment        = var.environment
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
  role               = data.aws_iam_role.lab_role.arn
}

module "private_key" {
  source      = "../private-key/"
  file_name   = "votingapp"
  environment = var.environment
}

module "node_group" {
  source         = "./modules/node-group"
  environment    = var.environment
  subnet_ids     = var.private_subnet_ids
  cluster_name   = module.eks_cluster.name
  role           = data.aws_iam_role.lab_role.arn
  ec2_ssh_key    = module.private_key.key_name
  desired_size   = var.desired_size
  max_size       = var.max_size
  min_size       = var.min_size
  instance_types = var.instance_types
  depends_on     = [module.eks_cluster]
}

data "aws_eks_cluster_auth" "auth" {
  name = module.eks_cluster.name
}
