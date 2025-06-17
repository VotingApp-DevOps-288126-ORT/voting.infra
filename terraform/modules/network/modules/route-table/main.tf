resource "aws_route_table" "routetable" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.gateway_id
  }

  tags = {
    Name = "${var.environment}-${var.subnet_type}-route-table"
  }
}

resource "aws_route_table_association" "subnet_associations" {
  count          = length(var.subnet_ids)
  subnet_id      = var.subnet_ids[count.index]
  route_table_id = aws_route_table.routetable.id
}
