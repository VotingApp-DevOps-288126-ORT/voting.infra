resource "aws_eks_node_group" "node_group" {
  cluster_name    = var.cluster_name
  node_group_name = "ng-${var.environment}"
  node_role_arn   = var.role
  subnet_ids      = var.subnet_ids # Subnets privadas

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = var.instance_types
  ami_type       = "AL2_x86_64"

  remote_access {
    ec2_ssh_key = var.ec2_ssh_key
  }

  tags = {
    Name        = "ng-${var.environment}"
    Environment = var.environment
  }

}
