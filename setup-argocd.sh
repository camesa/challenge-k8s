#!/bin/bash

# Instalar ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar que ArgoCD este listo
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Port forward del server ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Obtener admin password de ArgoCD
ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Admin Password: $ARGO_PWD"

# Instalar ArgoCD CLI
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Login a ArgoCD
argocd login localhost:8080 --username admin --password $ARGO_PWD --insecure

# Crear la aplicacion en ArgoCD
argocd app create voting-app --repo https://github.com/camesa/challenge-k8s.git --path . --dest-server https://kubernetes.default.svc --dest-namespace default

# Sync the application
argocd app sync voting-app

echo "Instalacion y configuración de ArgoCD terminada. La aplicación ha sido desplegada"
