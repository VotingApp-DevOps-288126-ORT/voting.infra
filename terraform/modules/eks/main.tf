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


# Refactor to module TODO
resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.12.1"
  values           = [file("${path.module}/nginx/nginx-${var.environment}.yaml")]

  set {
    name  = "controller.service.internal.enabled"
    value = "true"
  }

  depends_on = [
    module.eks_cluster,
    module.node_group
  ]
}

data "aws_eks_cluster_auth" "prod" {
  name = module.eks_cluster.name
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate)
    token                  = data.aws_eks_cluster_auth.prod.token
  }
}


