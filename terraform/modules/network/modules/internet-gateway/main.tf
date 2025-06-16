resource "aws_internet_gateway" "ac1-gw" {
  vpc_id = var.vpc_id
  tags = {
    Name = "igw-${var.vpc_id}-${var.environment}"
  }
}
