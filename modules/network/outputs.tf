output "vpc_id" {
  description = "Identifiant du VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR du VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Identifiants des sous-réseaux publics (ALB, NAT)."
  value       = [for az in var.azs : aws_subnet.public[az].id]
}

output "app_subnet_ids" {
  description = "Identifiants des sous-réseaux privés applicatifs."
  value       = [for az in var.azs : aws_subnet.app[az].id]
}

output "db_subnet_ids" {
  description = "Identifiants des sous-réseaux privés base de données."
  value       = [for az in var.azs : aws_subnet.db[az].id]
}

output "nat_public_ips" {
  description = "Adresses IP publiques de sortie des NAT Gateways."
  value       = [for eip in aws_eip.nat : eip.public_ip]
}
