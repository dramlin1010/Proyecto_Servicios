resource "aws_security_group" "sg_ftp_instancia" {
  vpc_id = aws_vpc.vpc_1.id

  # FTP
  ingress {
    from_port   = 21
    to_port     = 21
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto de Datos (FTP)
  ingress {
    from_port   = 20
    to_port     = 20
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # FTP Pasivo
  ingress {
    from_port   = 1024
    to_port     = 1048
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Trafico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG para FTP Server"
  }
}

# IP Elastica
resource "aws_eip" "ip_elastica_ftp" {
  instance = aws_instance.ftp_instancia.id

  tags = {
    Name = "EIP FTP"
  }
}

# Asociar IP Elastica
resource "aws_eip_association" "asociar_ip_elastica" {
  instance_id   = aws_instance.ftp_instancia.id
  allocation_id = aws_eip.ip_elastica_ftp.id
}

# Instancia para la subnet 1
resource "aws_instance" "ftp_instancia" {
  ami           = "ami-064519b8c76274859" # Debian 12
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_vpc_1.id
  key_name      = "Terraform"
  vpc_security_group_ids = [aws_security_group.sg_ftp_instancia.id]
  
  tags = {
    Name = "FTP VPC 1"
  }
}