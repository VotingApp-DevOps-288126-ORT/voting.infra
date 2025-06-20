resource "aws_eks_cluster" "eks" {
  name     = "cluster-eks-${var.environment}"
  role_arn = var.role

  vpc_config {
    subnet_ids = concat(var.public_subnet_ids, var.private_subnet_ids)
  }

  tags = {
    Name = "cluster-eks-${var.environment}"
  }
}



