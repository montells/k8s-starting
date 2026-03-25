# Research: Backend GET /project/:id Endpoint

**Branch**: `001-backend-project-endpoint` | **Date**: 2026-03-25

---

## Decision 1 — Standalone ActiveRecord 8 with Sinatra

**Decision**: Use the `activerecord` gem (8.x) directly with Sinatra, without Rails.

**Rationale**: Rails is prohibited by the constitution. Standalone ActiveRecord is fully supported — `establish_connection` works independently of Rails. No Rails dependencies are pulled in when requiring just `activerecord`.

**Gems required**:
- `activerecord` (~> 8.0) — ORM
- `pg` (~> 1.5) — PostgreSQL adapter (native extension)
- `rake` (~> 13.0) — migration task runner

**Alternatives considered**:
- Sequel: rejected — constitution mandates ActiveRecord 8.
- ROM: rejected — same reason.

---

## Decision 2 — Database Connection Setup

**Decision**: Use `config/database.yml` with ERB interpolation for all connection parameters. A thin `DatabaseConfig` module in `config/database.rb` loads and parses the YAML file, then calls `establish_connection`.

**File**: `backend/config/database.yml`

```yaml
default: &default
  adapter: postgresql
  host: <%= ENV.fetch('DB_HOST', 'localhost') %>
  port: <%= ENV.fetch('DB_PORT', '5432').to_i %>
  database: <%= ENV.fetch('DB_NAME') %>
  username: <%= ENV.fetch('DB_USER', 'postgres') %>
  password: <%= ENV.fetch('DB_PASSWORD', '') %>
  connect_timeout: 5
  pool: <%= ENV.fetch('DB_POOL', '5').to_i %>

development:
  <<: *default

production:
  <<: *default
```

**ENV vars**:

| Variable | Default | Required |
|---|---|---|
| `DB_HOST` | `localhost` | No |
| `DB_PORT` | `5432` | No |
| `DB_NAME` | _(none)_ | **Yes** — raises `KeyError` at boot if absent |
| `DB_USER` | `postgres` | No |
| `DB_PASSWORD` | `''` | No |
| `DB_POOL` | `5` | No |
| `RACK_ENV` | `development` | No — selects YAML environment block |

**Connection timeout**: `connect_timeout: 5` (seconds). Passed through `pg` gem to `PQconnectdb`. Controls how long AR waits for a TCP connection before raising `ActiveRecord::DatabaseConnectionError`.

**Rationale**: `database.yml` with ERB is the canonical ActiveRecord convention. It satisfies the constitution's ENV var requirement (all values come from ENV via ERB), keeps configuration declarative and readable, supports multiple environments cleanly, and is familiar to any AR user. `erb` and `yaml` are Ruby stdlib — no new gems required.

**Loading mechanism**: `ERB.new(File.read('config/database.yml')).result` processes `<%= %>` tags first, then `YAML.safe_load(..., aliases: true)` parses the result (the `aliases: true` flag enables `<<: *default` anchor syntax in Ruby 3.2).

**Alternatives considered**:

- Pure Ruby hash in `config/database.rb`: simpler but non-standard; loses environment blocks and declarative YAML structure; rejected in favour of AR convention.
- Rails-style `database_configuration` with `DatabaseTasks`: requires `railties`; rejected (constitution prohibits Rails).

---

## Decision 3 — Rake Migration Tasks

**Decision**: Custom `Rakefile` with a `db` namespace. Use `ActiveRecord::MigrationContext` for `migrate`/`rollback`. Use `pg` gem directly for `db:create`/`db:drop` (connect to `postgres` maintenance DB).

**Rake tasks provided**:

| Task | Purpose |
|---|---|
| `rake db:create` | Creates the application database (connects to `postgres` DB first) |
| `rake db:drop` | Drops the application database |
| `rake db:migrate` | Runs all pending migrations; dumps schema afterwards |
| `rake db:rollback` | Rolls back the last migration step; dumps schema afterwards |
| `rake db:schema:dump` | Writes current schema to `db/schema.rb` |

**ActiveRecord 8 API used**:
- `ActiveRecord::MigrationContext.new('db/migrate').migrate` — runs pending migrations
- `ActiveRecord::MigrationContext.new('db/migrate').rollback` — rolls back one step
- `ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)` — dumps schema

**Rationale**: Custom tasks avoid pulling in `railties` or `rails` gems. `ActiveRecord::MigrationContext` is the stable public API for standalone use in AR 7+/8.

**Alternatives considered**:
- `load 'active_record/railties/databases.rake'`: requires `railties` gem and non-trivial `DatabaseTasks` setup; rejected for YAGNI.
- Shell scripts wrapping `psql`: rejected — Rake is already a dependency; keep tooling consistent.

---

## Decision 4 — Error Rescue Hierarchy

**Decision**: Rescue specific ActiveRecord exceptions in `ProjectFinder` service. Fall through to a catch-all `StandardError` at the route level to guarantee no crash.

**Exception → HTTP mapping**:

| Exception | HTTP | Error message |
|---|---|---|
| `ActiveRecord::RecordNotFound` | 404 | `"Project not found"` |
| `ActiveRecord::NoDatabaseError` | 503 | `"Database does not exist"` |
| `ActiveRecord::DatabaseConnectionError` | 503 | `"Database connection failed"` |
| `ActiveRecord::ActiveRecordError` (catch-all) | 503 | `"Database error"` |

**Note on `NoDatabaseError`**: Raised when the configured database name does not exist in PostgreSQL. Inherits from `ActiveRecord::ConnectionFailed` in AR 8.

**Note on `DatabaseConnectionError`**: Raised when the PostgreSQL server is unreachable (e.g., server down, wrong host, port blocked). AR wraps the underlying `PG::ConnectionBad`.

**Rationale**: Specific rescue ordering matters — `NoDatabaseError` must be rescued before `DatabaseConnectionError` and `ActiveRecordError` since it inherits from them. Most-specific first.

---

## Decision 5 — Modularity Layout (Constitution §IV)

**Decision**: Three-layer separation:

1. **Route** (`sinatra.rb`): input validation, call service, format JSON response, log errors.
2. **Service** (`services/project_finder.rb`): database query, exception rescue, return plain Hash result.
3. **Model** (`models/project.rb`): ActiveRecord model, validations.

**Rationale**: Satisfies SRP — route handles HTTP concerns, service handles domain query, model handles data mapping. Business logic is not embedded in route blocks.

---

## Decision 6 — Docker: Alpine Package for pg Gem

**Decision**: Add `postgresql-dev` to the `apk add` line in `backend/Dockerfile`.

**Rationale**: The `pg` gem requires native compilation against `libpq`. On `ruby:3.2-alpine` (Alpine 3.19), `postgresql-dev` is a virtual package that installs `libpq-dev` and `pg_config`. `build-base` (already present) provides the C compiler.

**Dockerfile change**:
```
# Before
RUN apk add --no-cache build-base
# After
RUN apk add --no-cache build-base postgresql-dev
```

---

## Decision 7 — ID Format Validation

**Decision**: Validate `:id` in the route handler with a regex (`/\A\d+\z/`) before calling the service. Return HTTP 400 immediately for non-numeric values.

**Rationale**: Input validation is a routing/HTTP concern, not a domain concern. Keeping it in the route keeps the service clean. Regex `\A\d+\z` matches only positive integers (no negatives, no floats, no letters).

**Edge case**: `:id` = `"0"` passes the regex, passes to `Project.find(0)`, returns `RecordNotFound` → 404. This is correct behaviour.
