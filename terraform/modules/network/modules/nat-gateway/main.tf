
resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name = "${var.environment}-eip-${var.subnet_id}"
  }
}

resource "aws_nat_gateway" "nat" {
  subnet_id     = var.subnet_id
  allocation_id = aws_eip.eip.id

  tags = {
    Name = "${var.environment}-nat-gw-${var.subnet_id}"
  }

  depends_on = [var.igw_id]
}
