FROM rockylinux:9

RUN dnf update -y --setopt=sslverify=false && \
    dnf install -y nginx httpd-tools --setopt=sslverify=false

# Crear directorios necesarios
RUN mkdir -p /etc/nginx/certs /var/www/sitio1 /var/www/sitio2
RUN chown -R nginx:nginx /var/www/sitio1 /var/www/sitio2 /etc/nginx/certs

# Copiar certificados SSL y renombrar si es necesario
COPY certs/server.crt /etc/nginx/certs/server.crt
COPY certs/server.key /etc/nginx/certs/server.key

# Copiar configuración de Nginx desde la plantilla procesada
COPY conf.d/default.conf /etc/nginx/conf.d/

# Copiar contenido de los sitios
COPY sitio1 /var/www/sitio1/
COPY sitio2 /var/www/sitio2/

# Copiar otros directorios (HTML y configuraciones adicionales)
COPY html /etc/nginx/html

# Crear usuarios y configurar htpasswd
RUN useradd -m -d /home/test -s /bin/bash test && echo "test:test" | chpasswd && \
    useradd -m -d /home/maria -s /bin/bash maria && echo "maria:1234" | chpasswd && \
    htpasswd -cb /etc/nginx/.htpasswd test "test" && \
    htpasswd -b /etc/nginx/.htpasswd maria "1234" && \
    mkdir /home/test/public_html/ && \
    echo "<h1> Hola soy test </h2>" >/home/test/public_html/index.html && \
    mkdir /home/maria/public_html/ && \
    echo "<h1> Hola soy maria </h2>" >/home/maria/public_html/index.html && \
    chown -R nginx:nginx /home/test /home/maria

EXPOSE 80 32000

ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
