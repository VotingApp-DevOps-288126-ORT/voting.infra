resource "aws_ecr_repository" "elastic_container_registry" {
  name         = var.application
  force_delete = false

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.application
  }
}
