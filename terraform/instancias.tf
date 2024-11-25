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

  # TLS
  ingress {
    from_port = 990
    to_port = 990
    protocol = "tcp"
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
  vpc_id = aws_vpc.vpc_1.id

  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow LDAP"
    from_port        = 389
    to_port          = 389
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
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

output "ip_elastica_proftpd" {
  value = aws_eip.ip_elastica_ftp.public_ip
  description = "IP Elastica Proftpd"
}

output "ip_bastionado"{
  value = aws_instance.bastion_instancia.public_ip
  description = "IP Bastionado"
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

  user_data = <<-EOF
#!/bin/bash
apt update -y
  EOF

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
apt update -y
apt install vim -y
# DOCKER
apt install ca-certificates curl -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose -y
apt install jq -y

# AWS
apt install s3fs -y
mkdir /root/.aws

cat <<-CREDENTIALS > /root/.aws/credentials
[default]
aws_access_key_id=${var.aws_access_key_id}
aws_secret_access_key=${var.aws_secret_access_key}
aws_session_token=${var.aws_session_token}
CREDENTIALS


mkdir /home/admin/bucket-s3
chmod -R 755 /home/admin/bucket-s3
s3fs s3-test-daniel-bucket-lol /home/admin/bucket-s3 -o allow_other

# FTP DOCKER
mkdir /home/admin/ftp-docker
cd /home/admin/ftp-docker

# Crear Dockerfile
cat <<-DOCKERFILE > dockerfile
FROM debian:12

RUN apt update && \
    apt install proftpd-core openssl proftpd-mod-crypto -y

RUN echo "PassivePorts 1024 1048" >> /etc/proftpd/proftpd.conf && \
    echo "MasqueradeAddress $(curl -s https://api.myip.com | jq -r '.ip')" >> /etc/proftpd/proftpd.conf && \
    echo "UseIPv6 off" >> /etc/proftpd/proftpd.conf

RUN sed -i '/<IfModule mod_quotatab.c>/,/<\/IfModule>/d' /etc/proftpd/proftpd.conf

# Configuración de cuotas
RUN echo "LoadModule mod_quotatab.c" >> /etc/proftpd/modules.conf && \
    echo "LoadModule mod_quotatab_file.c" >> /etc/proftpd/modules.conf && \
    echo "<IfModule mod_quotatab.c>" >> /etc/proftpd/proftpd.conf && \
    echo "  QuotaEngine on" >> /etc/proftpd/proftpd.conf && \
    echo "  QuotaLog /var/log/proftpd/quota.log" >> /etc/proftpd/proftpd.conf && \
    echo "</IfModule>" >> /etc/proftpd/proftpd.conf && \
    echo "<IfModule mod_quotatab_file.c>" >> /etc/proftpd/proftpd.conf && \
    echo "  QuotaLimitTable file:/etc/proftpd/ftpquota.limittab" >> /etc/proftpd/proftpd.conf && \
    echo "  QuotaTallyTable file:/etc/proftpd/ftpquota.tallytab" >> /etc/proftpd/proftpd.conf && \
    echo "</IfModule>" >> /etc/proftpd/proftpd.conf && \
    echo "Include /etc/proftpd/modules.conf" >> /etc/proftpd/proftpd.conf

RUN cd /etc/proftpd && \
    ftpquota --create-table --type=limit --table-path=/etc/proftpd/ftpquota.limittab && \
    ftpquota --create-table --type=tally --table-path=/etc/proftpd/ftpquota.tallytab

RUN cd /etc/proftpd/ && ftpquota --add-record --type=limit --name=daniel --quota-type=user --bytes-upload=1 --bytes-download=400 --units=Mb --files-upload=1 --files-download=50 --table-path=/etc/proftpd/ftpquota.limittab
RUN cd /etc/proftpd/ && ftpquota --add-record --type=tally --name=daniel --quota-type=user

# certificado TLS autofirmado
RUN mkdir -p /etc/proftpd/ssl && \
    openssl req -x509 -newkey rsa:2048 -sha256 -keyout /etc/ssl/private/proftpd.key -out /etc/ssl/certs/proftpd.crt -nodes -days 365 \
    -subj "/C=ES/ST=España/L=Granada/O=daniel/OU=daniel/CN=ftp.daniel.com"

# Configuración TLS
RUN echo "LoadModule mod_tls.c" >> /etc/proftpd/modules.conf && \
    echo "DefaultRoot ~" >> /etc/proftpd/proftpd.conf && \
    echo "Include /etc/proftpd/tls.conf" >> /etc/proftpd/proftpd.conf && \
    echo "<IfModule mod_tls.c>" >> /etc/proftpd/tls.conf && \
    echo "  TLSEngine on" >> /etc/proftpd/tls.conf && \
    echo "  TLSLog /var/log/proftpd/tls.log" >> /etc/proftpd/tls.conf && \
    echo "  TLSProtocol SSLv23" >> /etc/proftpd/tls.conf && \
    echo "  TLSRSACertificateFile /etc/ssl/certs/proftpd.crt" >> /etc/proftpd/tls.conf && \
    echo "  TLSRSACertificateKeyFile /etc/ssl/private/proftpd.key" >> /etc/proftpd/tls.conf && \
    echo "</IfModule>" >> /etc/proftpd/tls.conf

# Creación de usuario FTP
RUN useradd -m -s /bin/bash ${var.ftp_user} && echo "${var.ftp_user}:${var.ftp_password}" | chpasswd
RUN mkdir /home/${var.ftp_user}/s3
RUN chown -R ${var.ftp_user}:${var.ftp_user} /home/${var.ftp_user}/s3
RUN chmod 755 -R /home/${var.ftp_user}/s3

EXPOSE 20 21 990 1024-1048
CMD ["/usr/sbin/proftpd", "--nodaemon"]
DOCKERFILE

docker build -t mi_proftpd /home/admin/ftp-docker
docker run -d  --name proftpd_server -v /home/admin/bucket-s3:/home/daniel/s3 -p 21:21 -p 20:20 -p 990:990 -p 1024-1048:1024-1048 mi_proftpd
chown admin:admin /home/admin/ftp-docker
chmod 700 /home/admin/ftp-docker
              EOF

  
  tags = {
    Name = "Proftpd"
  }
}

resource "aws_instance" "ldap_instancia" {
  ami                    = "ami-064519b8c76274859"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_vpc_1.id
  key_name               = "Terraform"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.sg_ldap_instancia.id]

user_data = <<-EOF
#!/bin/bash
apt update -y
apt install vim -y
# DOCKER
apt install ca-certificates curl -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose -y

# Crea y ejecuta el contenedor LDAP
docker run -d \
  --name openldap \
  --restart always \
  -p 389:389 -p 636:636 \
  -e LDAP_ORGANISATION="Daniel S.L" \
  -e LDAP_DOMAIN="daniel.com" \
  -e LDAP_ADMIN_PASSWORD="daniel" \
  -v /home/admin/ldap_data:/var/lib/ldap \
  -v /home/admin/ldap_config:/etc/ldap/slapd.d \
  osixia/openldap:latest

# Espera a que el contenedor esté listo
sleep 30

# Crea un archivo LDIF con usuarios
cat <<'LDIF' > /home/admin/add_users.ldif
dn: ou=people,dc=daniel,dc=com
objectClass: organizationalUnit
ou: people

dn: uid=usuario1,ou=people,dc=daniel,dc=com
objectClass: inetOrgPerson
cn: Usuario1
sn: Apellido1
uid: usuario1
mail: usuario1@daniel.com
userPassword: usuario1

dn: uid=usuario2,ou=people,dc=daniel,dc=com
objectClass: inetOrgPerson
cn: Usuario2
sn: Apellido2
uid: usuario2
mail: usuario2@daniel.com
userPassword: usuario2
LDIF

# Añade usuarios al servidor LDAP
docker exec -i openldap ldapadd -x -D "cn=admin,dc=daniel,dc=com" -w daniel -f /home/admin/add_users.ldif

EOF

# PARA GENERAR LA PASS HASHEADA HAY QUE HACER LO SIGUIENTE

#slappasswd -s usuario
# DELVOLVERA ALGO ASI {SSHA}3q2+7w==usuario==
# PONER ESTO: userPassword: {SSHA}3q2+7w==usuario==
  tags = {
    Name = "LDAP"
  }
}