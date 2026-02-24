# AGENTS.md

## Project Overview

This is a simple Sinatra web application containerized with Docker, designed as a learning project for Kubernetes experiments. The application displays environment variables and serves as a minimal example of deploying Ruby web apps to K8s.

## Tech Stack

- **Language**: Ruby 3.2
- **Web Framework**: Sinatra
- **Web Server**: Puma
- **Container Runtime**: Docker
- **Orchestration**: Kubernetes (K8s)

## Project Structure

```
k8s-starting/
├── app/
│   ├── app.rb              # Main Sinatra application
│   ├── Gemfile             # Ruby dependencies
│   ├── Dockerfile          # Docker image definition
│   └── views/
│       └── index.erb       # HTML template for root route
├── k8s/
│   ├── configMaps.yaml     # ConfigMap for environment variables
│   ├── deployment.yaml     # K8s Deployment (3 replicas)
│   └── sinatra-app-ingress.yaml  # Ingress configuration
├── README.md
└── AGENTS.md
```

## Application Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /` | Main page displaying environment variables (message, environment, pod name, hostname) |
| `GET /health` | Health check endpoint for K8s probes, returns `200 OK` |

## Environment Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `APP_MESSAGE` | Custom message displayed on the main page | `"Hola desde K8s!"` |
| `APP_ENV` | Application environment | `"development"` |
| `POD_NAME` | Pod name (injected by K8s) | `"local-container"` |
| `ALLOWED_HOSTS` | Comma-separated list of allowed hosts for Host Authorization | `"sinatra-app.example"` |

## Common Commands

### Local Development (Docker)

```bash
# Build the Docker image
docker build -t sinatra-app ./app

# Run container locally
docker run -p 8080:8080 sinatra-app

# Run with custom environment variables
docker run -p 8080:8080 \
  -e APP_MESSAGE="Hola desde Docker!" \
  -e APP_ENV="production" \
  sinatra-app

# Test the application
curl http://localhost:8080
curl http://localhost:8080/health
```

### Kubernetes Deployment

```bash
# Build and tag the image
docker build -t sinatra-app:1.1.0 ./app

# Apply K8s resources
kubectl apply -f k8s/configMaps.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/sinatra-app-ingress.yaml

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get ingress

# View logs
kubectl logs -l app=sinatra-app

# Port forward for local testing
kubectl port-forward deployment/sinatra-app-deployment 8080:8080

# Cleanup
kubectl delete -f k8s/
```

## Kubernetes Configuration Details

### Deployment (`k8s/deployment.yaml`)
- **Replicas**: 3
- **Image**: `sinatra-app:1.1.0`
- **ImagePullPolicy**: `Never` (for local testing)
- **Container Port**: 8080
- **Environment**: Injected from ConfigMap `sinatra-app-config`

### ConfigMap (`k8s/configMaps.yaml`)
- **Name**: `sinatra-app-config`
- Contains: `ALLOWED_HOSTS`, `APP_MESSAGE`, `APP_ENV`

### Ingress (`k8s/sinatra-app-ingress.yaml`)
- **Ingress Class**: nginx
- **Host**: `sinatra-app.example`
- **Backend Service**: `sinatra-app-svc` on port 8080

> **Note**: The Service resource (`sinatra-app-svc`) referenced in the Ingress is not defined in the current K8s manifests. You may need to create it separately.

## Development Notes

- The application runs on port **8080** and binds to `0.0.0.0`
- Uses `frozen_string_literal` pragma for performance optimization
- Host authorization is configured based on `ALLOWED_HOSTS` environment variable
- The Dockerfile uses `ruby:3.2-alpine` base image for minimal size
- Build tools (`build-base`) are installed for compiling native gem extensions

## Dependencies

- **sinatra**: Web framework
- **puma**: HTTP web server
- **rackup**: Rack server launcher

## Potential Improvements

1. Add a K8s Service manifest (`service.yaml`) to expose the deployment
2. Add liveness and readiness probes to the deployment
3. Implement resource limits and requests in the deployment
4. Add a `.dockerignore` file to optimize build context
5. Consider adding tests for the application
6. Implement CI/CD pipeline for automated builds and deployments