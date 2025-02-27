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
    from_port   = 1100
    to_port     = 1101
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
  vpc_id = aws_vpc.vpc_2.id

  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
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

output "ip_ldap"{
  value = aws_instance.ldap_instancia.private_ip
  description = "IP LDAP"
}


# Asociar IP Elastica
resource "aws_eip_association" "asociar_ip_elastica" {
  instance_id   = aws_instance.ftp_instancia.id
  allocation_id = aws_eip.ip_elastica_ftp.id
}

resource "aws_key_pair" "inst_key" {
  key_name   = "inst_key"
  public_key = var.public_key 
}

# Instancia Bastionado
resource "aws_instance" "bastion_instancia" {
  ami                    = "ami-064519b8c76274859"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_vpc_2.id
  #key_name               = "terra"
  key_name               = aws_key_pair.inst_key.key_name
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
  key_name               = aws_key_pair.inst_key.key_name
  depends_on = [ aws_instance.ldap_instancia ]
  
  vpc_security_group_ids = [aws_security_group.sg_ftp_instancia.id]
  user_data = <<-EOF
#!/bin/bash
sleep 50

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
apt update -y
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

apt install cron -y
apt install rsync -y

mkdir -p /home/admin/ftp

mkdir /mnt/bucket-s3
chmod 777 /mnt/bucket-s3
systemctl enable cron

systemctl start cron
systemctl enable cron

(crontab -l 2>/dev/null; echo "* * * * * rsync -av /home/admin/ftp/ /mnt/bucket-s3/") | crontab -

s3fs copias-router-daniel-ramirez-linares /mnt/bucket-s3 -o allow_other

mkdir -p /home/docker
cd /home/docker

# Crear Dockerfile
cat <<-DOCKERFILE > dockerfile
FROM debian:latest

# Dependencias
RUN apt-get update && apt-get install -y proftpd openssl nano proftpd-mod-crypto proftpd-mod-ldap ldap-utils

# Modulo de Crypto
RUN apt-get update && apt-get install -y proftpd-mod-crypto && apt-get install proftpd-mod-ldap -y

RUN useradd -m -s /bin/bash ${var.ftp_user} && echo "${var.ftp_user}:${var.ftp_password}" | chpasswd

RUN mkdir -p /home/admin/ftp && chown -R ${var.ftp_user}:${var.ftp_user} /home/admin && chmod -R 777 /home/admin && chmod -R 777 /home/

# Certificado ProFTPD
RUN openssl req -x509 -newkey rsa:2048 -sha256 -keyout /etc/ssl/private/proftpd.key -out /etc/ssl/certs/proftpd.crt -nodes -days 365 \
    -subj "/C=ES/ST=España/L=Granada/O=daniel/OU=daniel/CN=ftp.daniel.com"

RUN sed -i '/<IfModule mod_quotatab.c>/,/<\/IfModule>/d' /etc/proftpd/proftpd.conf

RUN echo "DefaultRoot /home/admin/ftp" >> /etc/proftpd/proftpd.conf && \
    echo "Include /etc/proftpd/modules.conf" >> /etc/proftpd/proftpd.conf && \
    echo "LoadModule mod_ldap.c" >> /etc/proftpd/modules.conf && \
    echo "Include /etc/proftpd/ldap.conf" >> /etc/proftpd/proftpd.conf && \
    echo "Include /etc/proftpd/tls.conf" >> /etc/proftpd/proftpd.conf && \
    echo "PassivePorts 1100 1101" >> /etc/proftpd/proftpd.conf && \
    echo "<IfModule mod_tls.c>" >> /etc/proftpd/tls.conf && \
    echo "  TLSEngine on" >> /etc/proftpd/tls.conf && \
    echo "  TLSLog /var/log/proftpd/tls.log" >> /etc/proftpd/tls.conf && \
    echo "  TLSProtocol SSLv23" >> /etc/proftpd/tls.conf && \
    echo "  TLSRSACertificateFile /etc/ssl/certs/proftpd.crt" >> /etc/proftpd/tls.conf && \
    echo "  TLSRSACertificateKeyFile /etc/ssl/private/proftpd.key" >> /etc/proftpd/tls.conf && \
    echo "</IfModule>" >> /etc/proftpd/tls.conf && \
    echo "<Anonymous /home/admin/ftp>" >> /etc/proftpd/proftpd.conf && \
    echo "  User ftp" >> /etc/proftpd/proftpd.conf && \
    echo "  Group nogroup" >> /etc/proftpd/proftpd.conf && \
    echo "  UserAlias anonymous ftp" >> /etc/proftpd/proftpd.conf && \
    echo "  RequireValidShell off" >> /etc/proftpd/proftpd.conf && \
    echo "  MaxClients 10" >> /etc/proftpd/proftpd.conf && \
    echo "  <Directory *>" >> /etc/proftpd/proftpd.conf && \
    echo "    <Limit WRITE>" >> /etc/proftpd/proftpd.conf && \
    echo "      DenyAll" >> /etc/proftpd/proftpd.conf && \
    echo "    </Limit>" >> /etc/proftpd/proftpd.conf && \
    echo "  </Directory>" >> /etc/proftpd/proftpd.conf && \
    echo "</Anonymous>" >> /etc/proftpd/proftpd.conf && \
    echo " LoadModule mod_tls.c" >> /etc/proftpd/modules.conf

# Cuotas
RUN echo "<IfModule mod_quotatab.c>" >> /etc/proftpd/proftpd.conf && \
    echo "QuotaEngine on" >> /etc/proftpd/proftpd.conf && \
    echo "QuotaLog /var/log/proftpd/quota.log" >> /etc/proftpd/proftpd.conf && \
    echo "<IfModule mod_quotatab_file.c>" >> /etc/proftpd/proftpd.conf && \
    echo "     QuotaLimitTable file:/etc/proftpd/ftpquota.limittab" >> /etc/proftpd/proftpd.conf && \
    echo "     QuotaTallyTable file:/etc/proftpd/ftpquota.tallytab" >> /etc/proftpd/proftpd.conf && \
    echo "</IfModule>" >> /etc/proftpd/proftpd.conf && \
    echo "</IfModule>" >> /etc/proftpd/proftpd.conf


# Tablas y Registros

RUN cd /etc/proftpd
RUN cd /etc/proftpd && ftpquota --create-table --type=limit --table-path=/etc/proftpd/ftpquota.limittab && \
    ftpquota --create-table --type=tally --table-path=/etc/proftpd/ftpquota.tallytab && \
    ftpquota --add-record --type=limit --name=daniel --quota-type=user --bytes-upload=20 --bytes-download=400 --units=Mb --files-upload=15 --files-download=50 --table-path=/etc/proftpd/ftpquota.limittab && \
    ftpquota --add-record --type=tally --name=daniel --quota-type=user

# LDAP Config en /etc/proftpd/proftpd.conf
RUN echo "<IfModule mod_ldap.c>" >> /etc/proftpd/proftpd.conf && \
    echo "    LDAPLog /var/log/proftpd/ldap.log" >> /etc/proftpd/proftpd.conf && \
    echo "    LDAPAuthBinds on" >> /etc/proftpd/proftpd.conf && \
    echo "    LDAPServer ldap://${aws_instance.ldap_instancia.private_ip}:389" >> /etc/proftpd/proftpd.conf && \
    echo "    LDAPBindDN \"cn=admin,dc=danielftp,dc=com\" \"admin_password\"" >> /etc/proftpd/proftpd.conf && \
    echo "    LDAPUsers \"dc=danielftp,dc=com\" \"(uid=%u)\"" >> /etc/proftpd/proftpd.conf && \
    echo "</IfModule>" >> /etc/proftpd/proftpd.conf

#LDAP Config en /etc/proftpd/ldap.conf
RUN echo "<IfModule mod_ldap.c>" >> /etc/proftpd/ldap.conf && \
    echo "    # Dirección del servidor LDAP" >> /etc/proftpd/ldap.conf && \
    echo "    LDAPServer ${aws_instance.ldap_instancia.private_ip}" >> /etc/proftpd/ldap.conf && \
    echo "    LDAPBindDN \"cn=admin,dc=danielftp,dc=com\" \"admin_password\"" >> /etc/proftpd/ldap.conf && \
    echo "    LDAPUsers ou=users,dc=danielftp,dc=com (uid=%u)" >> /etc/proftpd/ldap.conf && \
    echo "    CreateHome on 755" >> /etc/proftpd/ldap.conf && \
    echo "    LDAPGenerateHomedir on 755" >> /etc/proftpd/ldap.conf && \
    echo "    LDAPForceGeneratedHomedir on 755" >> /etc/proftpd/ldap.conf && \
    echo "    LDAPGenerateHomedirPrefix /home" >> /etc/proftpd/ldap.conf && \
    echo "</IfModule>" >> /etc/proftpd/ldap.conf

RUN echo "<Directory /home/admin/ftp>" >> /etc/proftpd/proftpd.conf && \
    echo "<Limit WRITE>" >> /etc/proftpd/proftpd.conf && \
    echo "  DenyUser carlos" >> /etc/proftpd/proftpd.conf && \
    echo "</Limit>" >> /etc/proftpd/proftpd.conf && \
    echo "</Directory>" >> /etc/proftpd/proftpd.conf 

EXPOSE 20 21 990 1100 1101
CMD ["sh", "-c", "chmod -R 777 /home/admin/ftp && proftpd --nodaemon"]
DOCKERFILE

docker build -t mi_proftpd .
docker run -d --name proftpd_server -p 20:20 -p 21:21 -p 990:990 -p 1100:1100 -p 1101:1101 -v /home/admin/ftp:/home/admin/ftp mi_proftpd
              EOF

  
  tags = {
    Name = "Proftpd"
  }
}

resource "aws_instance" "ldap_instancia" {
  ami                    = "ami-064519b8c76274859"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet_vpc_2.id
  key_name               = aws_key_pair.inst_key.key_name
  vpc_security_group_ids = [aws_security_group.sg_ldap_instancia.id]
  depends_on = [aws_nat_gateway.vpc2_nat_gateway]

user_data = <<-EOF
#!/bin/bash
sleep 30
apt-get update -y
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

mkdir -p /home/admin/ldap

cat <<-EOT > /home/admin/ldap/Dockerfile

FROM osixia/openldap:1.5.0

# Variables de entorno
ENV LDAP_ORGANISATION="Daniel FTP"
ENV LDAP_DOMAIN="danielftp.com"
ENV LDAP_ADMIN_PASSWORD="admin_password"

EOT

cat <<-BOOT > /home/admin/ldap/bootstrap.ldif
# Unidad organizativa para usuarios
dn: ou=users,dc=danielftp,dc=com
objectClass: top
objectClass: organizationalUnit
ou: users

# Usuario: Carlos
dn: uid=carlos,ou=users,dc=danielftp,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
cn: carlos
sn: Bullejos
uid: carlos
mail: carlos@danielftp.com
userPassword: carlos
uidNumber: 1001
gidNumber: 1001
homeDirectory: /home/ftp/
loginShell: /bin/bash

# Usuario: Alejandro
dn: uid=alejandro,ou=users,dc=danielftp,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
cn: alejandro
sn: Cortes
uid: alejandro
mail: alejandro@danielftp.com
userPassword: alejandro
uidNumber: 1002
gidNumber: 1002
homeDirectory: /home/ftp/
loginShell: /bin/bash

BOOT

cd /home/admin/ldap
docker build -t myldap .

docker run -d -p 389:389 -p 636:636 --name ldap myldap --loglevel debug
sleep 10

docker cp bootstrap.ldif ldap:/tmp

docker exec ldap ldapadd -x -D "cn=admin,dc=danielftp,dc=com" -w admin_password -f /tmp/bootstrap.ldif

docker exec ldap ldappasswd -x -D "cn=admin,dc=danielftp,dc=com" -w admin_password -s "carlos" "uid=carlos,ou=users,dc=danielftp,dc=com"
docker exec ldap ldappasswd -x -D "cn=admin,dc=danielftp,dc=com" -w admin_password -s "alejandro" "uid=alejandro,ou=users,dc=danielftp,dc=com"

docker stop ldap
docker start ldap
EOF

# PARA GENERAR LA PASS HASHEADA HAY QUE HACER LO SIGUIENTE

#slappasswd -s usuario
# DELVOLVERA ALGO ASI {SSHA}3q2+7w==usuario==
# PONER ESTO: userPassword: {SSHA}3q2+7w==usuario==
  tags = {
    Name = "LDAP"
  }
}