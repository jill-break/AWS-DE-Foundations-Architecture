output "vpc_id" {
  description = "ID of the data-platform VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet (us-east-1a)"
  value       = aws_subnet.public_1a.id
}

output "private_subnet_1a_id" {
  description = "ID of private subnet 1a (database tier)"
  value       = aws_subnet.private_1a.id
}

output "private_subnet_1b_id" {
  description = "ID of private subnet 1b (application tier)"
  value       = aws_subnet.private_1b.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_eip" {
  description = "Elastic IP address of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "sg_public_nat_id" {
  description = "ID of the public NAT security group"
  value       = aws_security_group.public_nat.id
}

output "sg_private_compute_id" {
  description = "ID of the private compute security group"
  value       = aws_security_group.private_compute.id
}

output "sg_private_db_id" {
  description = "ID of the private database security group"
  value       = aws_security_group.private_db.id
}
