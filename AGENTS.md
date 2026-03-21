# AGENTS.md

## Project Overview

This is a Kubernetes learning project with two Sinatra (Ruby) applications that communicate with each other inside the same cluster. The **frontend** (`app/`) serves an HTML page with environment info and a visit counter. The **backend** (`backend/`) is a JSON API consumed by the frontend, used to experiment with inter-service communication in K8s.

## Tech Stack

- **Language**: Ruby 3.2
- **Web Framework**: Sinatra
- **Web Server**: Puma
- **Container Runtime**: Docker
- **Orchestration**: Kubernetes (K8s)

## Project Structure

```
k8s-starting/
├── app/                        # Frontend Sinatra app (port 8080)
│   ├── app.rb                  # Main Sinatra application
│   ├── version.rb              # Centralized version file
│   ├── visit_counter.rb        # File-based persistent visit counter
│   ├── Gemfile
│   ├── Dockerfile
│   └── views/
│       └── index.erb           # HTML template
├── backend/                    # Backend Sinatra app (port 8081)
│   ├── sinatra.rb              # JSON API application
│   ├── version.rb              # Centralized version file
│   ├── Gemfile
│   └── Dockerfile
├── k8s/
│   ├── frontend/
│   │   ├── deployment.yaml         # K8s Deployment (3 replicas)
│   │   ├── configMaps.yaml         # ConfigMap for environment variables
│   │   ├── sinatra-app-ingress.yaml# Ingress (nginx, host: sinatra-app.example)
│   │   ├── nodeport.yaml           # NodePort Service
│   │   ├── fileVolume.yaml         # PersistentVolume for visit counter
│   │   └── fileVolumeClaim.yaml    # PersistentVolumeClaim
│   └── backend/
│       ├── deployment.yaml         # Backend Deployment (pending)
│       └── service.yaml            # Backend Service (pending)
├── README.md
└── AGENTS.md
```

## Applications

### Frontend (`app/`) — port 8080

| Endpoint | Description |
|----------|-------------|
| `GET /` | Main page: environment variables + visit counter |
| `GET /health` | Health check, returns `200 OK` |

### Backend (`backend/`) — port 8081

JSON API, intended to be called by the frontend inside the cluster.

| Endpoint | Description |
|----------|-------------|
| `GET /` | Returns `{"message": "ok"}` |
| `GET /health` | Returns `{"status": "healthy", "version": "..."}` |

## Environment Variables (Frontend)

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `APP_MESSAGE` | Custom message displayed on the main page | `"Hola desde K8s!"` |
| `APP_ENV` | Application environment | `"development"` |
| `POD_NAME` | Pod name (injected by K8s) | `"local-container"` |
| `ALLOWED_HOSTS` | Comma-separated list of allowed hosts for Host Authorization | `"sinatra-app.example"` |

## Common Commands

### Local Development (Docker)

```bash
# Frontend
docker build -t sinatra-app ./app
docker run -p 8080:8080 sinatra-app
curl http://localhost:8080
curl http://localhost:8080/health

# Backend
docker build -t sinatra-backend ./backend
docker run -p 8081:8081 sinatra-backend
curl http://localhost:8081
curl http://localhost:8081/health
```

### Kubernetes Deployment

```bash
# Apply frontend resources
kubectl apply -f k8s/frontend/

# Apply backend resources (once created)
kubectl apply -f k8s/backend/

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get ingress

# View logs
kubectl logs -l app=sinatra-app       # Frontend
kubectl logs -l app=sinatra-backend   # Backend (once deployed)

# Port forward for local testing
kubectl port-forward deployment/sinatra-app-deployment 8080:8080

# Cleanup
kubectl delete -f k8s/
```

## Kubernetes Configuration Details

### Frontend Deployment (`k8s/frontend/deployment.yaml`)
- **Replicas**: 3
- **ImagePullPolicy**: `Never` (for local testing)
- **Container Port**: 8080
- **Environment**: Injected from ConfigMap `sinatra-app-config`

### Backend Deployment (`k8s/backend/deployment.yaml` - pending)
- To be created by you during the study
- **Container Port**: 8081
- Will be reachable by the frontend via its K8s Service name (cluster-internal DNS)

### ConfigMap (`k8s/frontend/configMaps.yaml`)
- **Name**: `sinatra-app-config`
- Contains: `ALLOWED_HOSTS`, `APP_MESSAGE`, `APP_ENV`

### Ingress (`k8s/frontend/sinatra-app-ingress.yaml`)
- **Ingress Class**: nginx
- **Host**: `sinatra-app.example`
- **Backend Service**: `sinatra-app-svc` on port 8080

### Persistent Storage (`k8s/frontend/`)
- `fileVolume.yaml` — PersistentVolume backed by a local host path
- `fileVolumeClaim.yaml` — PVC bound to the above volume
- Used by the frontend to persist visit count across pod restarts

### Backend Service (`k8s/backend/service.yaml` - pending)
- To be created by you during the study
- Will expose the backend deployment to other pods in the cluster

## Development Notes

- Frontend runs on port **8080**, backend on **8081**, both bind to `0.0.0.0`
- Both apps use `frozen_string_literal` pragma
- Both Dockerfiles use `ruby:3.2-alpine` for minimal image size
- Frontend: host authorization configured via `ALLOWED_HOSTS` env var
- Visit counter persists to a file; requires a PVC when running in K8s

## Dependencies (both apps)

- **sinatra**: Web framework
- **puma**: HTTP web server
- **rackup**: Rack server launcher

## Potential Improvements

1. Add K8s Deployment + Service manifests for the backend
2. Configure frontend to call the backend via its K8s Service DNS name
3. Add liveness and readiness probes to both deployments
4. Implement resource limits and requests
5. Add a `.dockerignore` to both apps
6. Implement CI/CD pipeline for automated builds and deployments