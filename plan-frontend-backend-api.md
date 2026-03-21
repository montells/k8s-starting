# Plan de Implementación: Frontend invoca Backend API

## Objetivo
Agregar un nuevo elemento visual en la página index del frontend que muestre la respuesta del backend API con un color diferente a los elementos existentes.

## Requisitos
- El nuevo elemento debe aparecer al final de los elementos existentes
- Debe tener un color diferente (verde en lugar de azul claro)
- Debe mostrar "backend response:" como label
- El valor debe ser lo que devuelva el backend al invocar la ruta `backend/`
- La ruta del backend debe ser configurable mediante variable de entorno
- NO modificar archivos del backend ni de despliegue Docker/K8s

## Análisis del Estado Actual

### Frontend (`frontend/`)
- **app.rb**: Aplicación Sinatra que renderiza `index.erb` con variables de instancia
- **views/index.erb**: Vista HTML con 5 elementos `.env-var` (Code Name, Environment, Pod Name, Hostname, Visit Count)
- **Gemfile**: Dependencias básicas (sinatra, puma, rackup)
- **Estilos CSS**:
  - `.env-var`: fondo azul claro (#e8f4f8)
  - `.value`: color azul (#0066cc)

### Backend (`backend/`)
- **sinatra.rb**: API JSON en puerto 8081
- **Endpoint GET `/`**: Devuelve `{"message": "ok"}`
- **Endpoint GET `/health`**: Devuelve `{"status": "healthy", "version": "..."}`

## Plan de Implementación

### Paso 1: Agregar dependencia HTTParty al Gemfile

**Archivo**: `frontend/Gemfile`

Agregar la gema `httparty` para facilitar las peticiones HTTP:

```ruby
# frozen_string_literal: true

source 'https://rubygems.org'

gem 'httparty'
gem 'puma'
gem 'rackup'
gem 'sinatra'
```

### Paso 2: Crear módulo para invocar al backend

**Archivo nuevo**: `frontend/backend_client.rb`

Crear un módulo que encapsule la lógica de invocación al backend usando HTTParty:

```ruby
# frozen_string_literal: true

require 'httparty'

module BackendClient
  # Fetches data from the backend API
  # @param backend_url [String] The base URL of the backend service
  # @param path [String] The API path to call (default: '/')
  # @return [Hash] The parsed JSON response or error information
  def self.fetch(backend_url, path = '/')
    url = "#{backend_url}#{path}"
    
    response = HTTParty.get(url)
    
    if response.success?
      response.parsed_response
    else
      { error: "HTTP #{response.code}: #{response.message}" }
    end
  rescue StandardError => e
    { error: e.message }
  end
end
```

### Paso 3: Modificar app.rb para invocar al backend

**Archivo**: `frontend/app.rb`

Agregar la importación del módulo BackendClient y modificar la ruta raíz para obtener la respuesta del backend:

```ruby
# frozen_string_literal: true

require 'sinatra'
require_relative 'visit_counter'
require_relative 'version'
require_relative 'backend_client'

# Configure server to run on port 8080
set :port, 8080
set :bind, '0.0.0.0'

# Initialize VisitCounter
visit_counter = VisitCounter.new(ENV.fetch('VISIT_COUNT_FILE', '/data/visits.txt'))

allowed_hosts = ENV.fetch("ALLOWED_HOSTS", "localhost")

unless allowed_hosts.empty?
  set :host_authorization, {
    permitted_hosts: allowed_hosts.split(",")
  }
end

# Root route - renders the index template
get '/' do
  # Increment the visit count
  @visit_count = visit_counter.increment

  @version = VERSION::STRING
  @message = ENV.fetch('APP_MESSAGE', 'Hola desde K8s!')
  @environment = ENV.fetch('APP_ENV', 'development')
  @pod_name = ENV.fetch('POD_NAME', 'local-container')
  @hostname = `hostname`.strip
  
  # Fetch backend response
  backend_url = ENV.fetch('BACKEND_URL', 'http://localhost:8081')
  @backend_response = BackendClient.fetch(backend_url, '/')
  
  erb :index
end

# Health check endpoint
get '/health' do
  status 200
  'OK'
end
```

### Paso 4: Modificar index.erb para mostrar el nuevo elemento

**Archivo**: `frontend/views/index.erb`

Agregar un nuevo div con clase `.env-var` al final, con un color diferente (verde):

```erb
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sinatra K8s App</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 50px auto;
      padding: 20px;
      background-color: #f5f5f5;
    }
    h1 {
      color: #333;
    }
    .info {
      background-color: white;
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .env-var {
      margin: 10px 0;
      padding: 10px;
      background-color: #e8f4f8;
      border-radius: 4px;
    }
    .env-var.backend {
      background-color: #e8f8e8; /* Verde claro para diferenciar */
    }
    .label {
      font-weight: bold;
      color: #666;
    }
    .value {
      color: #0066cc;
    }
    .value.backend {
      color: #006600; /* Verde oscuro para el valor del backend */
    }
  </style>
</head>
<body>
  <div class="info">
    <h1><%= @message %></h1>

    <div class="env-var">
      <span class="label">Code Name:</span>
      <span class="value">app-sinatra-<%= @version %></span>
    </div>
    
    <div class="env-var">
      <span class="label">Environment:</span>
      <span class="value"><%= @environment %></span>
    </div>
    
    <div class="env-var">
      <span class="label">Pod Name:</span>
      <span class="value"><%= @pod_name %></span>
    </div>
    
    <div class="env-var">
      <span class="label">Hostname:</span>
      <span class="value"><%= @hostname %></span>
    </div>
    
    <div class="env-var">
      <span class="label">Visit Count:</span>
      <span class="value"><%= @visit_count.nil? ? 'N/A' : @visit_count %></span>
    </div>
    
    <!-- Nuevo elemento: Backend Response -->
    <div class="env-var backend">
      <span class="label">backend response:</span>
      <span class="value backend"><%= @backend_response.to_json %></span>
    </div>
  </div>
</body>
</html>
```

### Paso 5: Actualizar Gemfile.lock

**Comando**: Ejecutar `bundle install` en el directorio `frontend/` para actualizar las dependencias.

## Variables de Entorno Nuevas

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `BACKEND_URL` | URL base del servicio backend | `http://localhost:8081` |

## Archivos a Modificar

1. ✅ `frontend/Gemfile` - Agregar dependencia HTTP (opcional si se usa net/http)
2. ✅ `frontend/backend_client.rb` - Nuevo módulo para invocar al backend
3. ✅ `frontend/app.rb` - Importar módulo y obtener respuesta del backend
4. ✅ `frontend/views/index.erb` - Agregar nuevo elemento visual con color diferente

## Archivos NO Modificados

- ❌ `backend/` - No tocar
- ❌ `k8s/` - No tocar
- ❌ `frontend/Dockerfile` - No tocar (a menos que se agregue httparty)

## Notas de Implementación

1. **Manejo de errores**: El módulo `BackendClient` captura excepciones y devuelve un hash con clave `:error` si algo falla
2. **Configurabilidad**: La URL del backend se lee de la variable de entorno `BACKEND_URL`
3. **Color diferenciado**: Se usa verde claro (#e8f8e8) para el fondo y verde oscuro (#006600) para el valor
4. **Formato de respuesta**: Se muestra como JSON stringificado para depuración
5. **Dependencia HTTParty**: Se usa la gema `httparty` para simplificar las peticiones HTTP

## Orden de Ejecución

1. Modificar `frontend/Gemfile` - Agregar gema `httparty`
2. Crear `frontend/backend_client.rb` - Módulo con HTTParty
3. Modificar `frontend/app.rb` - Importar módulo y obtener respuesta del backend
4. Modificar `frontend/views/index.erb` - Agregar nuevo elemento visual con color verde
5. Ejecutar `bundle install` en `frontend/` para instalar httparty
6. Probar localmente con Docker
