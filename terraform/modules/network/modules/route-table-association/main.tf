locals {
  subnet_to_route_table_map = zipmap(var.subnet_ids, var.route_table_ids)
}

resource "aws_route_table_association" "this" {
  for_each = local.subnet_to_route_table_map

  subnet_id      = each.key
  route_table_id = each.value
}
