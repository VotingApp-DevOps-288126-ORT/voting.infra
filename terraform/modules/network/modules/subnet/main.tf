locals {
  az_to_cidr = zipmap(var.azs, var.subnet_cidrs)
}

resource "aws_subnet" "subnet-ac1" {
  for_each                = local.az_to_cidr
  vpc_id                  = var.vpc_id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = var.map_public_ip

  tags = {
    Name = "${var.subnet_type}-${each.key}-${var.environment}"
  }
}
