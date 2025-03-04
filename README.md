# Rama prinpical

Los archivos usados para la creacion de imagenes son "playbook_ecr.yml" para nginx y "playbook_apache_ecr.yml" para
la imagen de apache.

Los playbook de replicaset no son usados en el despliegue
actual.


# Lanzamientos distintos
## Minikube nodo
En la carpeta de minikube_nodo estan los pods usados cuando
desplegaba en el nodo de minikube.

## eks_nodo
Al movernos del nodo de minikube a eks, pues he diferenciado entre .yml usados para uno y para otro, pero en este momento
se usa solo el de eks ya que queremos trabajar en amazon.


### Lanzamiento Minikube Nodo

#### PV y PVC:
``` bash
kubectl apply -f pv.yml

kubectl apply -f pvc.yml
```

#### Base de Datos (MySQL) y PHP-FPM:
``` bash
kubectl apply -f mysql_deployment.yml

kubectl apply -f php-fpm-deployment.yml

kubectl apply -f ldap-bootstrap-ldif.yml

kubectl apply -f deployment_pod_ldap.yml

kubectl apply -f services.yml
```

#### Arrancar los pods
``` bash

# Desplegando la pagina web de charneco con nuestro codigo
kubectl apply -f deployment_pod_charneco.yml 

# Desplegando nuestra pagina con espacio de usuarios, etc...
kubectl apply -f deployment_pod_nginx.yml 
```

### Lanzamiento Minikube Nodo

#### Primero
``` bash
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.5"

kubectl delete pod -n kube-system -l app=efs-csi-controller # en caso de obtener errores en el "kubectl get pods -n kube-system"
```
#### StorageClass y PV/PVC
``` bash
kubectl apply -f storageclass-efs.yml
kubectl apply -f pv.yml
kubectl apply -f pvc.yml
```

#### MySQL, PHP-FPM, LDAP
``` bash
kubectl apply -f php-fpm-deployment.yml
kubectl apply -f deployment_pod_ldap.yml
```

#### Servicios
``` bash
kubectl apply -f services.yml
```

#### Aplicaciones web
##### Antes de esto, tener en el efs metido la pagina web de charneco.
``` bash
kubectl apply -f deployment_pod_apache.yml
kubectl apply -f deployment_pod_charneco.yml
kubectl apply -f deployment_pod_nginx.yml
```