output "ids" {
  value = [for s in aws_subnet.subnet-ac1 : s.id]
}
