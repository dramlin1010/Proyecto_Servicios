provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc_1" {
  cidr_block = var.VPC_IPS[0]
  tags = {
    Name = "VPC Terraform 1"
  }
}

resource "aws_vpc" "vpc_2" {
  cidr_block = var.VPC_IPS[1]
  tags = {
    Name = "VPC Terraform 2"
  }
}

# Peering entre VPC 1 y VPC 2
resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id        = aws_vpc.vpc_1.id
  peer_vpc_id   = aws_vpc.vpc_2.id
  auto_accept   = true

  tags = {
    Name = "VPC Peering Connection between VPC 1 and VPC 2"
  }
}

# Configurar rutas para que el trafico pase entre las VPCs
resource "aws_route" "vpc_1_to_vpc_2" {
  route_table_id            = aws_vpc.vpc_1.main_route_table_id
  destination_cidr_block    = aws_vpc.vpc_2.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

resource "aws_route" "vpc_2_to_vpc_1" {
  route_table_id            = aws_vpc.vpc_2.main_route_table_id
  destination_cidr_block    = aws_vpc.vpc_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# Gateway VPC 1 
resource "aws_internet_gateway" "igw_vpc_1" {
  vpc_id = aws_vpc.vpc_1.id
  tags = {
    Name = "IGW VPC 1"
  }
}

# Gateway VPC 2
resource "aws_internet_gateway" "igw_vpc_2" {
  vpc_id = aws_vpc.vpc_2.id
  tags = {
    Name = "IGW VPC 2"
  }
}

# Subnet VPC 1
resource "aws_subnet" "public_subnet_vpc_1" {
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = var.Subnet_VPC1
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "Subnet VPC 1"
  }
}

# Subnet Publica VPC 2
resource "aws_subnet" "public_subnet_vpc_2" {
  vpc_id                  = aws_vpc.vpc_2.id
  cidr_block              = var.Subnet_VPC2
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "Subnet VPC 2"
  }
}

# Subnet privada en VPC 2
resource "aws_subnet" "private_subnet_vpc_2" {
  vpc_id            = aws_vpc.vpc_2.id
  cidr_block        = var.Subnet_Private_VPC2
  availability_zone = "us-east-1a"
  tags = {
    Name = "Private Subnet VPC 2"
  }
}


# Tablas de enrutamiento
resource "aws_route_table" "public_route_table_vpc_1" {
  vpc_id = aws_vpc.vpc_1.id
  tags = {
    Name = "Tabla Enrutamiento VPC 1"
  }
}

# Tabla de enrutamiento para VPC2
resource "aws_route_table" "public_route_table_vpc_2" {
  vpc_id = aws_vpc.vpc_2.id
  tags = {
    Name = "Tabla Enrutamiento VPC 2"
  }
}

# Ruta predeterminada
resource "aws_route" "public_route_vpc_1" {
  route_table_id         = aws_route_table.public_route_table_vpc_1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_vpc_1.id
}

# Ruta predeterminada para la tabla de enrutamiento pública de VPC 2
resource "aws_route" "public_route_vpc_2" {
  route_table_id         = aws_route_table.public_route_table_vpc_2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_vpc_2.id
}

# Tabla de enrutamiento privada para VPC 2 (sin ruta de Internet)
resource "aws_route_table" "private_route_table_vpc_2" {
  vpc_id = aws_vpc.vpc_2.id
  tags = {
    Name = "Tabla Enrutamiento Privada VPC 2"
  }
}

# Asociar la subred con la ruta
resource "aws_route_table_association" "public_subnet_association_vpc_1" {
  subnet_id      = aws_subnet.public_subnet_vpc_1.id
  route_table_id = aws_route_table.public_route_table_vpc_1.id
}

# Enrutamiento publica VPC2
resource "aws_route_table_association" "public_subnet_association_vpc_2" {
  subnet_id      = aws_subnet.public_subnet_vpc_2.id
  route_table_id = aws_route_table.public_route_table_vpc_2.id
}

# Enrutamiento privada VPC2
resource "aws_route_table_association" "private_subnet_association_vpc_2" {
  subnet_id      = aws_subnet.private_subnet_vpc_2.id
  route_table_id = aws_route_table.private_route_table_vpc_2.id
}
