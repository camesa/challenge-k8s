#!/bin/bash

# Función para manejar errores
handle_error() {
  echo "❌ Error en el paso: $1"
  exit 1
}

# Asegurarse de que Minikube está en funcionamiento
minikube status || minikube start

# Cambiar al contexto de Minikube
echo "🔄 Cambiando al contexto de Minikube..."
kubectl config use-context minikube


# Instalar ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

sleep 20
# Esperar que ArgoCD este listo
echo "🔄 Esperando que los pods de ArgoCD esten listos"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s || handle_error "Esperando que los pods de ArgoCD esten listos"
echo "✅ Los pods de ArgoCD estan listos"

# Instalar ArgoCD CLI
echo "🔄 Instalando CLI de ArgoCD..."
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd
echo "✅ CLI de ArgoCD Instalado"

# Port forward del server ArgoCD
echo "🔄 Realizando port-forward al puerto 8000 de localhost"
sleep 10
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8000:443 &

# Obtener admin password de ArgoCD
ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) || handle_error "Obtener admin password de ArgoCD"
echo "ArgoCD Admin Password: $ARGO_PWD"

# Login a ArgoCD
argocd login localhost:8000 --insecure --username admin --password $ARGO_PWD  || handle_error "Login a ArgoCD"

# Crear la aplicación en ArgoCD
echo "🔄 Creando aplicación en ArgoCD..."
kubectl create namespace voting
argocd app create voting-app \
  --repo https://github.com/camesa/voting-app-k8s.git \
  --path k8s-manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace voting \
  --sync-policy automated

# Sync the application
argocd app sync voting-app

echo "✅ Instalacion y configuración de ArgoCD terminada. La aplicación ha sido desplegada"
echo "✨ Puedes acceder a la interfaz de ArgoCD en: https://localhost:8000"
echo "⭐ Usuario: admin"
echo "⭐ Contraseña: $ARGO_PWD"
