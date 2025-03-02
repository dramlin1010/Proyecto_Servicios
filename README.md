# Lanzamiento para el correcto funcionamiento

## PV y PVC:
``` bash
kubectl apply -f pv.yml

kubectl apply -f pvc.yml
```

## Base de Datos (MySQL) y PHP-FPM:
``` bash
kubectl apply -f mysql_deployment.yml

kubectl apply -f php-fpm-deployment.yml

kubectl apply -f services.yml
```

## Arrancar los pods
``` bash
kubectl apply -f deployment_pod_ldap.yml

# Desplegando la pagina web de charneco con nuestro codigo
kubectl apply -f deployment_pod_charneco.yml 

# Desplegando nuestra pagina con espacio de usuarios, ldap, etc
kubectl apply -f deployment_pod_nginx.yml 