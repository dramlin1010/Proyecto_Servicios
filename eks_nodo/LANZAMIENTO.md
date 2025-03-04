# Primero
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.5"
kubectl delete pod -n kube-system -l app=efs-csi-controller # en caso de obtener errores en el "kubectl get pods -n kube-system"

# StorageClass y PV/PVC
kubectl apply -f storageclass-efs.yml
kubectl apply -f pv.yml
kubectl apply -f pvc.yml

# MySQL, PHP-FPM, LDAP
kubectl apply -f php-fpm-deployment.yml
kubectl apply -f deployment_pod_ldap.yml

# Servicios
kubectl apply -f services.yml

# Aplicaciones web
#### Antes de esto, tener en el efs metido la pagina web de charneco.
kubectl apply -f deployment_pod_apache.yml
kubectl apply -f deployment_pod_charneco.yml
kubectl apply -f deployment_pod_nginx.yml