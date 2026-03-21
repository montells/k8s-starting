# Sinatra K8s App

A Kubernetes learning project with two Sinatra (Ruby) applications that communicate with each other within the same cluster.

## Architecture

```
Internet → Ingress → sinatra-app (frontend, :8080) → sinatra-backend (:8081)
```

- **`app/`** — Frontend: serves HTML, displays environment variables and visit counter
- **`backend/`** — Backend: JSON API, intended to be consumed by the frontend within the cluster

## Project Structure

```
k8s-starting/
├── app/                        # Frontend Sinatra app
│   ├── app.rb                  # Sinatra application
│   ├── version.rb              # Centralized version file
│   ├── visit_counter.rb        # File-based persistent visit counter
│   ├── Gemfile
│   ├── Dockerfile
│   └── views/
│       └── index.erb           # HTML template
├── backend/                    # Backend Sinatra app
│   ├── sinatra.rb              # Sinatra application (JSON API)
│   ├── version.rb              # Centralized version file
│   ├── Gemfile
│   └── Dockerfile
├── k8s/
│   ├── deployment.yaml         # Frontend deployment (3 replicas)
│   ├── configMaps.yaml         # Environment variables
│   ├── sinatra-app-ingress.yaml# Nginx ingress
│   ├── nodeport.yaml           # NodePort service
│   ├── fileVolume.yaml         # PersistentVolume for visit counter
│   └── fileVolumeClaim.yaml    # PersistentVolumeClaim
└── README.md
```

## Applications

### Frontend (`app/`) — port 8080

| Endpoint | Description |
|----------|-------------|
| `GET /` | Main page with environment variables and visit counter |
| `GET /health` | Health check endpoint for K8s probes |

**Environment Variables:**

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `APP_MESSAGE` | Custom message to display | `"Hola desde K8s!"` |
| `APP_ENV` | Application environment | `"development"` |
| `POD_NAME` | Pod name (injected by K8s) | `"local-container"` |
| `ALLOWED_HOSTS` | Allowed hosts for authorization | `"sinatra-app.example"` |

### Backend (`backend/`) — port 8081

JSON API consumed by the frontend within the cluster.

| Endpoint | Description |
|----------|-------------|
| `GET /` | Returns `{"message": "ok"}` |
| `GET /health` | Returns `{"status": "healthy", "version": "..."}` |

## Version Management

Each app has its own `version.rb`:

```ruby
module VERSION
  STRING = '1.x.x'
end
```

Modify that file to update the version; the rest of the code uses it automatically.

## Local Development with Docker

```bash
# Frontend
docker build -t sinatra-app ./app
docker run -p 8080:8080 sinatra-app

# Backend
docker build -t sinatra-backend ./backend
docker run -p 8081:8081 sinatra-backend
```

## Kubernetes

```bash
# Apply all resources
kubectl apply -f k8s/

# Check status
kubectl get deployments
kubectl get pods
kubectl get ingress

# View logs
kubectl logs -l app=sinatra-app
```

> The frontend is accessible via Ingress at `sinatra-app.example`. The backend communicates internally through K8s Services.
