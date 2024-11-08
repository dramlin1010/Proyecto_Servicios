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

  # Puertos Pasivo
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

# Security Group para la instancia bastión
resource "aws_security_group" "bastionado_sg" {
  name   = "bastionado_sg"
  vpc_id = aws_vpc.vpc_1.id

  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG para Bastion"
  }
}

resource "aws_security_group" "sg_ldap_instancia" {
  name   = "ldap_sg"
  vpc_id = aws_vpc.vpc_2.id

  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "SG para LDAP"
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

# Instancia Bastionado
resource "aws_instance" "bastion_instancia" {
  ami                    = "ami-064519b8c76274859"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_vpc_1.id
  key_name               = "Terraform"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.bastionado_sg.id]

  #security_groups = [aws_security_group.bastionado_sg.name]

  tags = {
    Name = "Bastionado"
  }
}


# Instancia para la subnet 1
resource "aws_instance" "ftp_instancia" {
  ami           = "ami-064519b8c76274859" # Debian 12
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_vpc_1.id
  key_name      = "Terraform"
  vpc_security_group_ids = [aws_security_group.sg_ftp_instancia.id]
  user_data = <<-EOF
#!/bin/bash
sudo apt update -y
sudo apt install vim -y
# DOCKER
sudo apt install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose -y
sudo apt install jq -y

# AWS
sudo apt install s3fs -y
mkdir /root/.aws

cat <<-CREDENTIALS > /root/.aws/credentials
[default]
aws_access_key_id=ASIA45IISLW2GI4OKNPY
aws_secret_access_key=0wiwhCGlzeOEKXgImUZOeHtHdgrcN4m+585ZjTdz
aws_session_token=IQoJb3JpZ2luX2VjENX//////////wEaCXVzLXdlc3QtMiJHMEUCICN6ovfy+0fDzOlD2KSoYy1yAZ4eBi3FYic3mZb2zrNPAiEA7fikbztmWXj4J9vpcoQC68U8s8bYneLI2ICFeBBv7CwqqQIIXhAAGgw4ODc0NjU1OTgzODgiDEXSt4Bu9mFMxwriTyqGApdSbOKHnrGipDJE+PNOjoRy45i9WR0dQaMhxyl7VbRasFGQ1SvAHNUthTvSgY7nEN/m6HIFrnfwHPPMGfO2c1uJ7fPFBI7BOrUVs8J882khhV004UNfP2Op6Wm7UGXki7P/aq2Uatm7o5F7tM5b5v2Cbk7EVQoP0hHfQdP/MeuRsgBZ9iK0smzid05jnr9ILA+3veuctPZpIN2gV1L8L5bziNdwH5JrXjpkLQwOAAPa9rnJUgwjvQR4hWfONpHAdPrY4fanqR7RrozFhO6c7G7dVzpW6pnbq7urwYVIL+9uDy1UXpNg0A8GeAWkXj8Iaw5Zr2/sCHEiDWnQZL1oic84AZCpZyQwz4u4uQY6nQFak+GO3VXYL6HnnNGB9Df5SEFYHL68k2yOG6TeD/DNIq62B0dOQuH261kFf9x7nDjvTdOPP6mUVRWCcR+6nwWluwwO36rSNCOH62Yo+Fw/RFM3Ceu2Yx+vjN4FMT651CKM3uB4OGv0lJ7V7zxEOwjUS+DGE//eJglMcLTYWR58NYHx+athctx6ThB1SmJySz9ZaGTU9tjOjbgrhxLA
CREDENTIALS


mkdir /home/admin/bucket-s3
sudo chmod -R 755 /home/admin/bucket-s3
s3fs s3-test-daniel-bucket-lol /home/admin/bucket-s3 -o allow_other

# FTP DOCKER
mkdir /home/admin/ftp-docker
cd /home/admin/ftp-docker

# Crear Dockerfile
cat <<-DOCKERFILE > dockerfile
FROM debian:12
RUN apt update && \\
    apt install proftpd -y
RUN echo "PassivePorts 1024 1048" >> /etc/proftpd/proftpd.conf && \\
    echo "MasqueradeAddress $(curl -s https://api.myip.com | jq -r '.ip')" >> /etc/proftpd/proftpd.conf && \\
    echo "DefaultRoot ~" >> /etc/proftpd/proftpd.conf && \\
    echo "UseIPv6 off" >> /etc/proftpd/proftpd.conf
RUN useradd -m -s /bin/bash ${var.ftp_user} && echo "${var.ftp_user}:${var.ftp_password}" | chpasswd
RUN mkdir /home/${var.ftp_user}/s3
RUN chown -R daniel:daniel /home/daniel/s3
RUN chmod 755 -R /home/daniel/s3
EXPOSE 20 21 990 1024-1048
CMD ["/usr/sbin/proftpd", "--nodaemon"]
DOCKERFILE

sudo docker build -t mi_proftpd /home/admin/ftp-docker
sudo docker run -d  --name proftpd_server -v /home/admin/bucket-s3:/home/daniel/s3 -p 21:21 -p 20:20 -p 990:990 -p 1024-1048:1024-1048 mi_proftpd
sudo chown admin:admin /home/admin/ftp-docker
sudo chmod 700 /home/admin/ftp-docker

              EOF

  
  tags = {
    Name = "Proftpd"
  }
}

# LDAP
resource "aws_instance" "ldap_instancia" {
  ami           = "ami-064519b8c76274859"  # Debian 12
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_vpc_2.id
  key_name      = "Terraform"
  vpc_security_group_ids = [aws_security_group.sg_ldap_instancia.id]

  user_data = <<-EOF
#!/bin/bash

# Variables de configuración
DOMAIN="example.com"
ORGANIZATION="ExampleCorp"
LDAP_PASSWORD="Toor2024"
BASE_DN="dc=example,dc=com"

# Actualizar el sistema
sudo apt update -y

echo "slapd slapd/internal/generated_adminpw password $LDAP_PASSWORD" | sudo debconf-set-selections
echo "slapd slapd/internal/adminpw password $LDAP_PASSWORD" | sudo debconf-set-selections
echo "slapd slapd/password2 password $LDAP_PASSWORD" | sudo debconf-set-selections
echo "slapd slapd/password1 password $LDAP_PASSWORD" | sudo debconf-set-selections
echo "slapd slapd/domain string $DOMAIN" | sudo debconf-set-selections
echo "slapd shared/organization string $ORGANIZATION" | sudo debconf-set-selections

# Instalar OpenLDAP y utils sin interfaz
DEBIAN_FRONTEND=noninteractive sudo apt install -y slapd ldap-utils
              EOF

  tags = {
    Name = "Server LDAP"
  }
}