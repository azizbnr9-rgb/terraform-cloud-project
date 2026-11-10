locals {
  public_subnets = zipmap(var.azs, var.public_subnet_cidrs)
  app_subnets    = zipmap(var.azs, var.app_subnet_cidrs)
  db_subnets     = zipmap(var.azs, var.db_subnet_cidrs)

  # Une seule NAT Gateway (dev/test, économique) ou une par AZ (prod, haute disponibilité)
  nat_azs = var.single_nat_gateway ? [var.azs[0]] : var.azs
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

# ---------------------------------------------------------------------------
# Sous-réseaux
# ---------------------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${substr(each.key, -1, 1)}"
    Tier = "public"
  })
}

resource "aws_subnet" "app" {
  for_each = local.app_subnets

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-${substr(each.key, -1, 1)}"
    Tier = "app"
  })
}

resource "aws_subnet" "db" {
  for_each = local.db_subnets

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-${substr(each.key, -1, 1)}"
    Tier = "db"
  })
}

# ---------------------------------------------------------------------------
# Sortie contrôlée des sous-réseaux privés : NAT Gateway
# ---------------------------------------------------------------------------
resource "aws_eip" "nat" {
  for_each = toset(local.nat_azs)

  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name_prefix}-nat-eip-${substr(each.key, -1, 1)}" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each = toset(local.nat_azs)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, { Name = "${var.name_prefix}-nat-${substr(each.key, -1, 1)}" })

  depends_on = [aws_internet_gateway.this]
}

# ---------------------------------------------------------------------------
# Routage
# ---------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-rt-public" })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Une table par AZ applicative : chaque AZ sort par "sa" NAT (ou la NAT unique)
resource "aws_route_table" "app" {
  for_each = local.app_subnets

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[var.azs[0]].id : aws_nat_gateway.this[each.key].id
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-rt-app-${substr(each.key, -1, 1)}" })
}

resource "aws_route_table_association" "app" {
  for_each = aws_subnet.app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.app[each.key].id
}

# Sous-réseaux DB : aucune route vers Internet (ni IGW, ni NAT)
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-rt-db" })
}

resource "aws_route_table_association" "db" {
  for_each = aws_subnet.db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.db.id
}
