# Quickstart: Backend GET /project/:id

**Branch**: `001-backend-project-endpoint`

---

## Prerequisites

- Ruby 3.2
- PostgreSQL 14 running and accessible
- `bundle` available

---

## 1. Install dependencies

```bash
cd backend/
bundle install
```

---

## 2. Set environment variables

Connection parameters are interpolated into `config/database.yml` via ERB at runtime:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=backend_development
export DB_USER=postgres
export DB_PASSWORD=secret
export RACK_ENV=development   # selects the database.yml environment block (default: development)
# Optional:
export DB_POOL=5
```

`DB_NAME` is the only required variable — the app raises `KeyError` at boot if it is absent.

---

## 3. Create the database

```bash
cd backend/
rake db:create
```

---

## 4. Run migrations

```bash
cd backend/
rake db:migrate
```

This creates the `projects` table and dumps `db/schema.rb`.

---

## 5. (Optional) Seed a project for manual testing

```bash
cd backend/
ruby -e "
  require_relative 'config/database'
  require_relative 'models/project'
  Project.create!(name: 'Test Project', description: 'A sample project', status: 'active')
  puts 'Seeded project id=' + Project.last.id.to_s
"
```

---

## 6. Start the backend

```bash
cd backend/
ruby sinatra.rb
```

Server listens on `http://0.0.0.0:8081`.

---

## 7. Test the endpoint

```bash
# Found project
curl http://localhost:8081/project/1

# Not found
curl http://localhost:8081/project/999

# Invalid ID format
curl http://localhost:8081/project/abc
```

---

## Rake task reference

| Command | Description |
| --- | --- |
| `rake db:create` | Creates the PostgreSQL database |
| `rake db:drop` | Drops the PostgreSQL database |
| `rake db:migrate` | Runs all pending migrations |
| `rake db:rollback` | Rolls back the last migration |
| `rake db:schema:dump` | Writes `db/schema.rb` from current DB state |

---

## Running migrations inside Docker / Kubernetes

The Rakefile is at `/sinatra/app/Rakefile` inside the container. Run migrations as a one-off command or init container:

```bash
docker run --rm \
  -e DB_HOST=... -e DB_NAME=... -e DB_USER=... -e DB_PASSWORD=... \
  <image> \
  ruby /sinatra/app/Rakefile db:migrate
```

Or using `rake` directly:

```bash
docker run --rm \
  -e DB_HOST=... -e DB_NAME=... -e DB_USER=... -e DB_PASSWORD=... \
  --workdir /sinatra/app \
  <image> \
  rake db:migrate
```

---

## Rollback last migration

```bash
cd backend/
rake db:rollback
```
