# Voting App - Kubernetes Deployment

Este repositorio contiene los archivos de configuración de Kubernetes necesarios para desplegar la aplicación voting-app (https://github.com/camesa/SRE-challenge-infra) utilizando ArgoCD para la gestión continua de la implementación.
El script `setup-argocd.sh` realiza la instalación integra de ArgoCD en un cluster de `Minikube` y la configuración necesaria desplegar la aplicación voting-app.

## Requerimientos Previos

1. [Docker](https://app.docker.com)
2. [Minikube](https://minikube.sigs.k8s.io/docs/start/)
3. [kubectl](https://kubernetes.io/docs/tasks/tools/)
4. [curl](https://curl.se/)

## Componentes

### 1. Componente de Votación (vote.yaml)

- **Deployment**: `despliegue-vote`
  - Imagen: `camesa/voting-app-vote:latest`
  - Puerto: 80
  - Recursos:
    - Requests: 100m CPU, 128Mi memoria
    - Límites: 500m CPU, 512Mi memoria
- **Service**: `servicio-vote`
  - Tipo: NodePort
  - Puerto expuesto: 30000
- **HPA**: Escala de 1 a 3 réplicas basado en el uso de CPU (objetivo: 50%)

### 2. Componente de Resultados (result.yaml)

- **Deployment**: `despliegue-result`
  - Imagen: `camesa/voting-app-result:latest`
  - Puerto: 80
  - Recursos:
    - Requests: 100m CPU, 128Mi memoria
    - Límites: 500m CPU, 512Mi memoria
- **Service**: `servicio-result`
  - Tipo: NodePort
- **HPA**: Escala de 1 a 3 réplicas basado en el uso de CPU (objetivo: 50%)

### 3. Componente Worker (worker.yaml)

- **Deployment**: `despliegue-worker`
  - Imagen: `camesa/voting-app-worker:latest`
  - Recursos:
    - Requests: 100m CPU, 128Mi memoria
    - Límites: 500m CPU, 512Mi memoria
- **HPA**: Escala de 1 a 3 réplicas basado en el uso de CPU (objetivo: 50%)

## Características

1. **Despliegue Continuo**: Utiliza ArgoCD para mantener el estado deseado en el cluster.
2. **Escalado Automático**: Todos los componentes tienen HPA configurados.
3. **Gestión de Recursos**: Límites y requests de recursos definidos para todos los contenedores.
4. **Exposición de Servicios**: Los servicios de votación y resultados están expuestos mediante NodePort.

## Instrucciones de Uso

1. Clonar el repositorio:
   ```
   git clone https://github.com/camesa/voting-app-k8s.git
   cd voting-app-k8s
   ```

2. Ejecutar el script `setup-argocd.sh` para configurar ArgoCD y desplegar la aplicación:
   ```
   chmod +x setup-argocd.sh
   ./setup-argocd.sh
   ```

   El script realiza las siguientes acciones:
   - Inicia Minikube si no está en funcionamiento
   - Instala ArgoCD en el cluster
   - Instala la CLI de ArgoCD
   - Configura el port-forward para acceder a la interfaz de ArgoCD
   - Crea la aplicación voting-app en ArgoCD y la sincroniza

4. Una vez que el script haya terminado, se puede acceder a:
   - Interfaz de ArgoCD: https://localhost:8000
     - Usuario: admin
     - Contraseña: (proporcionada por el script)
   - Aplicación de votación (vote): (usar `minikube service servicio-vote --url` para obtener la URL)
   - Aplicación de resultados (result): (usar `minikube service servicio-result --url` para obtener la URL)

## Monitoreo y Gestión

- Para ver el estado de la aplicación en ArgoCD:
  ```
  argocd app get voting-app
  ```

- Para forzar una sincronización:
  ```
  argocd app sync voting-app
  ```

- Para ver los pods en ejecución:
  ```
  kubectl get pods -n voting
  ```

## Limpieza

Para eliminar la aplicación y todos los recursos asociados:

1. Eliminar la aplicación de ArgoCD:
   ```
   argocd app delete voting-app
   ```

2. Eliminar el namespace de voting:
   ```
   kubectl delete namespace voting
   ```

3. Si queremos eliminar ArgoCD:
   ```
   kubectl delete namespace argocd
   ```

## Notas

- Las imagenes a utilizar se encuentran en el registry de DockerHub camesa/voting-app-*
  Estas seran construidas y pusheadas al registry a través del CI implementado en el repositorio de la aplicación (https://github.com/camesa/SRE-challenge-infra)
