# Implementation Plan: Backend GET /project/:id Endpoint

**Branch**: `001-backend-project-endpoint` | **Date**: 2026-03-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-backend-project-endpoint/spec.md`

---

## Summary

Expose a `GET /project/:id` endpoint on the Sinatra backend that returns a project as JSON from PostgreSQL 14 via ActiveRecord 8. The endpoint must always respond — never crash — covering not-found (404), invalid input (400), and all database failure modes (503). Database connection is configured via `config/database.yml` using ERB interpolation of ENV vars (standard AR convention). Rake tasks provide full migration lifecycle management.

---

## Technical Context

**Language/Version**: Ruby 3.2
**Primary Dependencies**: Sinatra 4.x, Puma 7.x, Rackup 2.x, ActiveRecord 8.x, pg ~> 1.5, Rake ~> 13.0
**Storage**: PostgreSQL 14 — table `projects`, accessed only from `backend/`
**Testing**: None (per constitution — quality through OOP design)
**Target Platform**: Linux server / Docker (`ruby:3.2-alpine`) / Kubernetes
**Project Type**: Web service (JSON REST API)
**Performance Goals**: < 2 seconds response under normal conditions; ≤ 5 seconds under DB failure (connect_timeout)
**Constraints**: `frozen_string_literal: true` on all files; SOLID/DRY; no cross-directory Ruby dependencies; k8s/ untouched; all DB config via ENV vars (interpolated into database.yml)
**Scale/Scope**: Single backend instance; connection pool size configurable via `DB_POOL` (default: 5)

---

## Constitution Check

*GATE: Must pass before implementation.*

| Principle | Status | Notes |
| --- | --- | --- |
| I. Ruby Excellence (SOLID, DRY, frozen_string_literal) | ✅ PASS | All new files use frozen_string_literal; SRP enforced via service/model/route separation |
| II. Simplicity First (YAGNI) | ✅ PASS | No speculative abstractions; minimal Rake tasks; no repository pattern layer |
| III. Kubernetes Boundary | ✅ PASS | k8s/ directory not touched |
| IV. Modularity & Separation of Concerns | ✅ PASS | Route → Service → Model layers; config isolated in config/; version.rb untouched |
| V. Deploy Scripts & Docker in Scope | ✅ PASS | Dockerfile updated for postgresql-dev |
| Tech Stack: Ruby 3.2 only | ✅ PASS | No other languages introduced |
| Tech Stack: Sinatra (no Rails) | ✅ PASS | Only `activerecord` gem added — no `railties` or `rails` |
| Tech Stack: ActiveRecord 8 + PostgreSQL 14 | ✅ PASS | Gems: activerecord ~> 8.0, pg ~> 1.5 |
| Tech Stack: ENV vars for DB config | ✅ PASS | All parameters from ENV via ERB interpolation in database.yml — nothing hardcoded |
| Tech Stack: No test suite | ✅ PASS | No test gems added |

**No violations detected. Gate cleared.**

---

## Project Structure

### Documentation (this feature)

```text
specs/001-backend-project-endpoint/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/
│   └── project-api.md  ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks — not yet created)
```

### Source Code (repository root)

```text
backend/
├── Gemfile                          MODIFY — add activerecord, pg, rake
├── Gemfile.lock                     REGENERATE — bundle install
├── Rakefile                         CREATE — db:create, db:drop, db:migrate, db:rollback, db:schema:dump
├── sinatra.rb                       MODIFY — require database config, add GET /project/:id route
├── version.rb                       NO CHANGE
├── config/
│   ├── database.yml                 CREATE — YAML with ERB ENV interpolation (all environments)
│   └── database.rb                  CREATE — DatabaseConfig module: loads database.yml, calls establish_connection
├── db/
│   ├── migrate/
│   │   └── 20260325000000_create_projects.rb   CREATE — migration
│   └── schema.rb                    GENERATED — by rake db:migrate (not hand-written)
├── models/
│   └── project.rb                   CREATE — ActiveRecord model
├── services/
│   └── project_finder.rb            CREATE — PORO service, DB query, exception rescue
└── Dockerfile                       MODIFY — add postgresql-dev to apk
```

**Structure Decision**: Web service option — backend-only changes. Frontend untouched (per spec). All new files live under `backend/`.

---

## Implementation Steps

### Step 1 — Gemfile: Add new gems

**File**: `backend/Gemfile`

Add to the existing Gemfile:

```ruby
gem 'activerecord', '~> 8.0'
gem 'pg',           '~> 1.5'
gem 'rake',         '~> 13.0'
```

Then run `bundle install` inside `backend/`.

---

### Step 2 — Dockerfile: Add PostgreSQL dev headers

**File**: `backend/Dockerfile`

The `pg` gem requires native compilation against `libpq`. Update the apk install line:

```dockerfile
# Before
RUN apk add --no-cache build-base

# After
RUN apk add --no-cache build-base postgresql-dev
```

---

### Step 3 — config/database.yml: Connection parameters via ERB

**File**: `backend/config/database.yml` *(new file)*

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

**Key points**:

- `ENV.fetch('DB_NAME')` raises `KeyError` at boot if not set — intentional fail-fast.
- `connect_timeout: 5` — PostgreSQL will abort a connection attempt after 5 seconds, triggering `DatabaseConnectionError` that the service rescues.
- `<<: *default` YAML anchors reduce duplication across environments.
- The active environment is selected by the `RACK_ENV` ENV var (default: `development`).
- `erb` and `yaml` are Ruby stdlib — no extra gems required.

---

### Step 4 — config/database.rb: YAML loader module

**File**: `backend/config/database.rb` *(new file)*

```ruby
# frozen_string_literal: true

require 'active_record'
require 'yaml'
require 'erb'

module DatabaseConfig
  CONFIG_FILE = File.join(__dir__, 'database.yml')

  def self.load_config
    env = ENV.fetch('RACK_ENV', 'development')
    raw = ERB.new(File.read(CONFIG_FILE)).result
    YAML.safe_load(raw, aliases: true).fetch(env)
  end

  def self.establish!
    ActiveRecord::Base.establish_connection(load_config)
  end
end

DatabaseConfig.establish!
```

**Key points**:

- `ERB.new(...).result` processes the `<%= %>` interpolations before YAML parsing.
- `YAML.safe_load(..., aliases: true)` enables the `<<: *default` anchor/alias syntax.
- `establish_connection` is lazy — no socket opened at require time; connection occurs on first query.
- `DatabaseConfig.load_config` returns a plain `Hash` (string keys from YAML) — used by Rakefile for `db:create`/`db:drop`.

---

### Step 5 — models/project.rb: ActiveRecord model

**File**: `backend/models/project.rb` *(new file)*

```ruby
# frozen_string_literal: true

require 'active_record'

class Project < ActiveRecord::Base
  validates :name,   presence: true
  validates :status, inclusion: { in: %w[active inactive] }
end
```

---

### Step 6 — services/project_finder.rb: Query service (PORO)

**File**: `backend/services/project_finder.rb` *(new file)*

```ruby
# frozen_string_literal: true

require_relative '../models/project'

class ProjectFinder
  def find(id)
    project = Project.find(id)
    { success: true, project: project.as_json(only: %i[id name description status]) }
  rescue ActiveRecord::RecordNotFound
    $stdout.puts "[ERROR] Project not found: id=#{id}"
    { success: false, status: 404, error: 'Project not found' }
  rescue ActiveRecord::NoDatabaseError => e
    $stdout.puts "[ERROR] Database does not exist: #{e.message}"
    { success: false, status: 503, error: 'Database does not exist' }
  rescue ActiveRecord::DatabaseConnectionError => e
    $stdout.puts "[ERROR] Database connection failed: #{e.message}"
    { success: false, status: 503, error: 'Database connection failed' }
  rescue ActiveRecord::ActiveRecordError => e
    $stdout.puts "[ERROR] Database error: #{e.message}"
    { success: false, status: 503, error: 'Database error' }
  end
end
```

**Exception ordering** (most-specific first):

1. `RecordNotFound` — find returned nothing → 404
2. `NoDatabaseError` — DB name doesn't exist → 503 (inherits from `DatabaseConnectionError` in AR 8; must precede it)
3. `DatabaseConnectionError` — server unreachable, timeout exceeded → 503
4. `ActiveRecordError` — any other AR error → 503

---

### Step 7 — db/migrate/20260325000000_create_projects.rb: Migration

**File**: `backend/db/migrate/20260325000000_create_projects.rb` *(new file)*

```ruby
# frozen_string_literal: true

class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :name,        null: false
      t.text   :description
      t.string :status,      null: false, default: 'active'
      t.timestamps
    end
  end
end
```

---

### Step 8 — Rakefile: Migration tasks

**File**: `backend/Rakefile` *(new file)*

```ruby
# frozen_string_literal: true

require 'active_record'
require 'pg'
require_relative 'config/database'

MIGRATIONS_PATH = File.join(__dir__, 'db', 'migrate')
SCHEMA_PATH     = File.join(__dir__, 'db', 'schema.rb')

namespace :db do
  desc 'Create the application database'
  task :create do
    config = DatabaseConfig.load_config
    conn = PG.connect(
      host:     config['host'],
      port:     config['port'],
      user:     config['username'],
      password: config['password'],
      dbname:   'postgres'
    )
    db_name = config['database']
    conn.exec("CREATE DATABASE #{conn.escape_identifier(db_name)}")
    conn.close
    puts "Database '#{db_name}' created."
  rescue PG::DuplicateDatabase
    puts "Database '#{config['database']}' already exists."
  end

  desc 'Drop the application database'
  task :drop do
    config = DatabaseConfig.load_config
    conn = PG.connect(
      host:     config['host'],
      port:     config['port'],
      user:     config['username'],
      password: config['password'],
      dbname:   'postgres'
    )
    db_name = config['database']
    conn.exec("DROP DATABASE IF EXISTS #{conn.escape_identifier(db_name)}")
    conn.close
    puts "Database '#{db_name}' dropped."
  end

  desc 'Run all pending migrations'
  task :migrate do
    ActiveRecord::MigrationContext.new(MIGRATIONS_PATH).migrate
    Rake::Task['db:schema:dump'].invoke
    puts 'Migrations complete.'
  end

  desc 'Rollback the last migration'
  task :rollback do
    ActiveRecord::MigrationContext.new(MIGRATIONS_PATH).rollback
    Rake::Task['db:schema:dump'].invoke
    puts 'Rolled back.'
  end

  namespace :schema do
    desc 'Dump current schema to db/schema.rb'
    task :dump do
      File.open(SCHEMA_PATH, 'w') do |f|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, f)
      end
      puts "Schema dumped to #{SCHEMA_PATH}."
    end
  end
end
```

**Notes**:

- `DatabaseConfig.load_config` returns a Hash with **string keys** (from YAML) — the Rakefile accesses them as `config['host']`, etc.
- `db:create`/`db:drop` connect to the `postgres` maintenance database; `escape_identifier` prevents SQL injection on the database name.
- `db:migrate` and `db:rollback` invoke `db:schema:dump` automatically to keep `schema.rb` in sync.
- `DatabaseConfig.establish!` runs at require time (via `require_relative 'config/database'`), setting up the AR connection used by `MigrationContext`.

---

### Step 9 — sinatra.rb: Add /project/:id route

**File**: `backend/sinatra.rb` *(modify)*

```ruby
# frozen_string_literal: true

require 'sinatra'
require_relative 'version'
require_relative 'config/database'
require_relative 'services/project_finder'

set :port, 8081
set :bind, '0.0.0.0'

allowed_hosts = ENV.fetch('ALLOWED_HOSTS', 'sinatra-backend-svc')
unless allowed_hosts.empty?
  set :host_authorization, { permitted_hosts: allowed_hosts.split(',') }
end

before do
  content_type :json
end

get '/' do
  { message: 'ok' }.to_json
end

get '/health' do
  status 200
  { status: 'healthy', version: VERSION::STRING }.to_json
end

get '/project/:id' do
  unless params[:id] =~ /\A\d+\z/
    $stdout.puts "[ERROR] Invalid project ID format: #{params[:id]}"
    halt 400, { error: 'Invalid project ID format' }.to_json
  end

  result = ProjectFinder.new.find(params[:id].to_i)

  if result[:success]
    status 200
    { project: result[:project] }.to_json
  else
    status result[:status]
    { error: result[:error] }.to_json
  end
end
```

**Key changes from original**:

1. Added `require_relative 'config/database'` and `require_relative 'services/project_finder'`.
2. Added `GET /project/:id` route with numeric input validation and service delegation.
3. Logging for invalid ID happens in the route; all DB-related error logging happens in the service.
4. Existing routes (`/`, `/health`) are preserved unchanged.

---

## Complexity Tracking

No constitution violations. Table not required.

---

## Phase 1 Artifacts

| Artifact | Path | Status |
| --- | --- | --- |
| Research | `specs/001-backend-project-endpoint/research.md` | ✅ Complete |
| Data Model | `specs/001-backend-project-endpoint/data-model.md` | ✅ Complete |
| API Contract | `specs/001-backend-project-endpoint/contracts/project-api.md` | ✅ Complete |
| Quickstart | `specs/001-backend-project-endpoint/quickstart.md` | ✅ Complete |

---

## Post-Constitution Re-check (Post-Design)

| Principle | Status | Design Decisions Verified |
| --- | --- | --- |
| I. Ruby Excellence | ✅ PASS | All files: frozen_string_literal; SRP: route/service/model/config/yaml each one concern |
| II. Simplicity First | ✅ PASS | No repository layer; no abstract base classes; database.yml is standard AR convention, not overengineering |
| III. Kubernetes Boundary | ✅ PASS | k8s/ untouched throughout design |
| IV. Modularity | ✅ PASS | Routes in sinatra.rb; business query in ProjectFinder; AR model in Project; DB config in DatabaseConfig + database.yml |
| V. Deploy & Docker | ✅ PASS | Dockerfile updated; Rakefile covers migration lifecycle |
| Tech Stack | ✅ PASS | Only activerecord, pg, rake added; no Rails; ENV vars interpolated via ERB in database.yml |
