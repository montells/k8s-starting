# Sinatra K8s App

Aplicación web mínima con Sinatra (Ruby) para aprender Kubernetes.

## Estructura del Proyecto

```
k8s-starting/
├── app/
│   ├── app.rb              # Aplicación Sinatra
│   ├── version.rb          # Archivo de versión centralizado
│   ├── Gemfile             # Dependencias Ruby
│   ├── Dockerfile          # Imagen Docker
│   └── views/
│       └── index.erb       # Plantilla HTML
├── k8s/
│   └── ...                 # Manifestos K8s
└── README.md               # Este archivo
```

## Gestión de Versiones

La versión de la aplicación se gestiona en un único archivo: [`app/version.rb`](app/version.rb)

```ruby
module VERSION
  STRING = '1.4.0'
end
```

Para actualizar la versión, solo necesitas modificar este archivo y la aplicación lo utilizará automáticamente.

## Variables de Entorno

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `APP_MESSAGE` | Mensaje personalizado a mostrar | "Hola desde K8s!" |
| `APP_ENV` | Entorno de la aplicación | "development" |
| `POD_NAME` | Nombre del pod (inyectado por K8s) | "local-container" |

## Uso Local con Docker

### Construir la imagen

```bash
docker build -t sinatra-app ./app
```

### Ejecutar el contenedor

```bash
# Básico
docker run -p 8080:8080 sinatra-app

# Con variables de entorno
docker run -p 8080:8080 \
  -e APP_MESSAGE="Hola desde Docker!" \
  -e APP_ENV="production" \
  sinatra-app
```

### Probar la aplicación

Abre en el navegador: http://localhost:8080

Health check: http://localhost:8080/health

## Próximos Pasos para Kubernetes

1. Crear un Deployment YAML
2. Crear un Service YAML
3. Configurar ConfigMaps para variables de entorno
4. Crear Ingress (opcional)

## Endpoints

- `GET /` - Página principal con información de variables de entorno
- `GET /health` - Health check para probes de K8s
