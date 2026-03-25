# Tasks: Backend GET /project/:id Endpoint

**Input**: Design documents from `/specs/001-backend-project-endpoint/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/project-api.md ✅, quickstart.md ✅

**Tests**: No test tasks generated (no automated test suite per constitution).

**Organization**: Tasks grouped by user story for independent implementation and verification.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story this task belongs to (US1–US4)
- Paths are relative to repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add new dependencies and prepare the environment.

- [x] T001 Modify `backend/Gemfile` — add `gem 'activerecord', '~> 8.0'`, `gem 'pg', '~> 1.5'`, `gem 'rake', '~> 13.0'` in the main group
- [x] T002 [P] Modify `backend/Dockerfile` — extend the `apk add` line to include `postgresql-dev` alongside `build-base` so the `pg` native gem compiles

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core AR infrastructure that MUST be complete before any user story begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T003 Create `backend/config/database.yml` — YAML file with `default: &default` anchor block using ERB for all connection parameters: `adapter: postgresql`, `host: <%= ENV.fetch('DB_HOST', 'localhost') %>`, `port: <%= ENV.fetch('DB_PORT', '5432').to_i %>`, `database: <%= ENV.fetch('DB_NAME') %>`, `username: <%= ENV.fetch('DB_USER', 'postgres') %>`, `password: <%= ENV.fetch('DB_PASSWORD', '') %>`, `connect_timeout: 5`, `pool: <%= ENV.fetch('DB_POOL', '5').to_i %>` — with `development:` and `production:` blocks both merging via `<<: *default`
- [x] T004 Create `backend/config/database.rb` — `DatabaseConfig` module with `CONFIG_FILE` constant pointing to `database.yml`, `self.load_config` method that processes the YAML with `ERB.new(File.read(CONFIG_FILE)).result` then `YAML.safe_load(raw, aliases: true).fetch(ENV.fetch('RACK_ENV', 'development'))`, and `self.establish!` that calls `ActiveRecord::Base.establish_connection(load_config)` — call `DatabaseConfig.establish!` at end of file; add `# frozen_string_literal: true`
- [x] T005 [P] Create `backend/db/migrate/20260325000000_create_projects.rb` — `CreateProjects < ActiveRecord::Migration[8.0]` with `change` method creating table `projects`: `t.string :name, null: false`, `t.text :description`, `t.string :status, null: false, default: 'active'`, `t.timestamps`; add `# frozen_string_literal: true`
- [x] T006 Create `backend/Rakefile` — with `require 'active_record'`, `require 'pg'`, `require_relative 'config/database'`; define `MIGRATIONS_PATH = File.join(__dir__, 'db', 'migrate')` and `SCHEMA_PATH = File.join(__dir__, 'db', 'schema.rb')`; implement `namespace :db` with tasks: `db:create` (connects to maintenance DB `postgres` using `DatabaseConfig.load_config` string keys, executes `CREATE DATABASE` via `PG.connect`, rescues `PG::DuplicateDatabase`), `db:drop` (same pattern, `DROP DATABASE IF EXISTS`), `db:migrate` (`ActiveRecord::MigrationContext.new(MIGRATIONS_PATH).migrate`, then invoke `db:schema:dump`), `db:rollback` (`MigrationContext.new(...).rollback`, then invoke `db:schema:dump`), `db:schema:dump` (`ActiveRecord::SchemaDumper.dump` to `SCHEMA_PATH`); add `# frozen_string_literal: true`
- [x] T007 Create `backend/models/project.rb` — `Project < ActiveRecord::Base` with `validates :name, presence: true` and `validates :status, inclusion: { in: %w[active inactive] }`; add `# frozen_string_literal: true`

**Checkpoint**: Run `bundle install` in `backend/`, then `rake db:create && rake db:migrate` — `db/schema.rb` should be generated with a `projects` table.

---

## Phase 3: User Story 1 — Retrieve Existing Project (Priority: P1) 🎯 MVP

**Goal**: `GET /project/:id` with a valid numeric ID that exists in the database returns HTTP 200 with the project data wrapped under the `"project"` key.

**Independent Test**: Seed one project row, send `GET /project/1`, verify response is `{"project":{"id":1,"name":"...","description":"...","status":"active"}}` with status 200 and `Content-Type: application/json`.

### Implementation for User Story 1

- [x] T008 [US1] Create `backend/services/project_finder.rb` — `ProjectFinder` class with `find(id)` method: call `Project.find(id)` and return `{ success: true, project: project.as_json(only: %i[id name description status]) }`; add `require_relative '../models/project'` and `# frozen_string_literal: true`
- [x] T009 [US1] Modify `backend/sinatra.rb` — add `require_relative 'config/database'` and `require_relative 'services/project_finder'`; add `before` block setting `content_type :json`; add `GET /project/:id` route: validate `params[:id]` matches `/\A\d+\z/` (halt 400 with `{error: 'Invalid project ID format'}.to_json` and log `[ERROR] Invalid project ID format: #{params[:id]}` to `$stdout` if invalid); call `ProjectFinder.new.find(params[:id].to_i)`; if `result[:success]` return status 200 with `{ project: result[:project] }.to_json`; else return `status result[:status]` with `{ error: result[:error] }.to_json`

**Checkpoint**: `GET /project/1` returns 200 JSON project. `GET /project/abc` returns 400 JSON error. Application does not crash.

---

## Phase 4: User Story 2 — Project Not Found (Priority: P1)

**Goal**: `GET /project/:id` with a valid numeric ID that does not exist returns HTTP 404 with `{"error": "Project not found"}` without crashing.

**Independent Test**: Send `GET /project/99999` (non-existent ID), verify HTTP 404, body `{"error":"Project not found"}`, application still responds to a subsequent valid request.

### Implementation for User Story 2

- [x] T010 [US2] Extend `backend/services/project_finder.rb` — add `rescue ActiveRecord::RecordNotFound` clause after the happy-path return: log `$stdout.puts "[ERROR] Project not found: id=#{id}"`, return `{ success: false, status: 404, error: 'Project not found' }`

**Checkpoint**: `GET /project/99999` returns 404 `{"error":"Project not found"}`. A subsequent `GET /project/1` still returns 200.

---

## Phase 5: User Story 3 — Database Connection Failure (Priority: P2)

**Goal**: When the database server is unreachable, `GET /project/:id` returns HTTP 503 with `{"error": "Database connection failed"}` within 5 seconds without crashing.

**Independent Test**: Stop the PostgreSQL server (or set `DB_HOST=invalid`), send `GET /project/1`, verify HTTP 503, body `{"error":"Database connection failed"}`, response arrives within 5 seconds, application is still alive after.

### Implementation for User Story 3

- [x] T011 [US3] Extend `backend/services/project_finder.rb` — add `rescue ActiveRecord::DatabaseConnectionError` clause (after `RecordNotFound`): log `$stdout.puts "[ERROR] Database connection failed: #{e.message}"`, return `{ success: false, status: 503, error: 'Database connection failed' }`; also add terminal `rescue ActiveRecord::ActiveRecordError` fallback: log `$stdout.puts "[ERROR] Database error: #{e.message}"`, return `{ success: false, status: 503, error: 'Database error' }`

**Checkpoint**: With `DB_HOST=invalid`, `GET /project/1` returns 503 `{"error":"Database connection failed"}` in ≤5 seconds. App remains alive.

---

## Phase 6: User Story 4 — Database Does Not Exist (Priority: P2)

**Goal**: When the configured database name does not exist, `GET /project/:id` returns HTTP 503 with `{"error": "Database does not exist"}` without crashing.

**Independent Test**: Set `DB_NAME=nonexistent_db` (DB server reachable but DB absent), send `GET /project/1`, verify HTTP 503, body `{"error":"Database does not exist"}`, application stays alive.

### Implementation for User Story 4

- [x] T012 [US4] Extend `backend/services/project_finder.rb` — insert `rescue ActiveRecord::NoDatabaseError` clause **before** the `DatabaseConnectionError` rescue (because `NoDatabaseError` inherits from `DatabaseConnectionError` in AR 8 and must be caught first): log `$stdout.puts "[ERROR] Database does not exist: #{e.message}"`, return `{ success: false, status: 503, error: 'Database does not exist' }`

**Checkpoint**: With `DB_NAME=nonexistent_db`, `GET /project/1` returns 503 `{"error":"Database does not exist"}`. With `DB_HOST=invalid`, still returns 503 `{"error":"Database connection failed"}`.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Verification, cleanup, and documentation sync.

- [x] T013 [P] Run `bundle install` inside `backend/` and verify `Gemfile.lock` includes `activerecord`, `pg`, and `rake` entries
- [x] T014 Run `rake db:create && rake db:migrate` inside `backend/` — verify `backend/db/schema.rb` is generated and contains the `projects` table definition
- [x] T015 [P] Audit all new Ruby files (`config/database.yml` excluded; check `.rb` files) — confirm every file starts with `# frozen_string_literal: true` as required by constitution §I
- [x] T016 [P] Validate the complete rescue chain ordering in `backend/services/project_finder.rb` — confirm order: `RecordNotFound` → `NoDatabaseError` → `DatabaseConnectionError` → `ActiveRecordError`; confirm `NoDatabaseError` is above `DatabaseConnectionError`
- [x] T017 Run quickstart.md validation steps end-to-end against local environment — confirm all 5 scenarios from `specs/001-backend-project-endpoint/quickstart.md` produce the expected HTTP status codes and JSON bodies

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 (Gemfile must exist before Rakefile can require gems) — **BLOCKS all user stories**
- **Phase 3 (US1)**: Depends on Phase 2 — foundational layer must be complete
- **Phase 4 (US2)**: Depends on Phase 3 (extends `project_finder.rb` created in T008)
- **Phase 5 (US3)**: Depends on Phase 4 (extends same file, rescue ordering matters)
- **Phase 6 (US4)**: Depends on Phase 5 (inserts rescue clause before `DatabaseConnectionError`)
- **Phase 7 (Polish)**: Depends on Phases 3–6

### Within-Story Dependencies

```
T001 → T003 (database.yml before database.rb)
T001 → T004 (Gemfile before testing config/database.rb loads)
T003 → T004 (database.yml must exist before DatabaseConfig reads it)
T004 → T006 (config/database.rb must exist before Rakefile requires it)
T005 → T006 (migration file must exist before rake db:migrate runs)
T007 → T008 (Project model must exist before ProjectFinder uses it)
T008 → T009 (ProjectFinder must exist before sinatra.rb requires it)
T008 → T010 → T011 → T012 (sequential extensions to project_finder.rb)
```

### Parallel Opportunities

```
T001 ∥ T002        — Gemfile and Dockerfile are independent files
T003 ∥ T005        — database.yml and migration file are independent
T013 ∥ T015 ∥ T016 — Polish tasks touch different concerns
```

---

## Parallel Example: Phase 2 Foundational

```text
# After T001 completes, run in parallel:
Task A: Create backend/config/database.yml (T003)
Task B: Create backend/db/migrate/20260325000000_create_projects.rb (T005)

# Then sequentially:
Task: Create backend/config/database.rb (T004) — needs database.yml
Task: Create backend/Rakefile (T006) — needs config/database.rb
Task: Create backend/models/project.rb (T007) — independent but needs gems
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only — Both P1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational — **CRITICAL, blocks everything**
3. Complete Phase 3: US1 — happy path
4. Complete Phase 4: US2 — not-found handling
5. **STOP and VALIDATE**: `GET /project/1` → 200, `GET /project/999` → 404, `GET /project/abc` → 400
6. Deploy / demo if ready

### Incremental Delivery

1. Setup + Foundational → DB and model layer ready
2. US1 (Phase 3) → Core endpoint works for valid projects → **Deploy (MVP)**
3. US2 (Phase 4) → Not-found errors handled → Deploy
4. US3 (Phase 5) → Connection failures handled → Deploy
5. US4 (Phase 6) → Missing-DB handled → Deploy
6. Polish (Phase 7) → Validation and cleanup → Final deploy

### Parallel Team Strategy (if applicable)

- Phases 1–2 done together as a team (foundational dependency)
- US3 and US4 (Phases 5–6) technically extend the same file sequentially, so assign to one developer
- Polish tasks T013, T015, T016 can be distributed across team members

---

## Task Summary

| Phase | Tasks | Count | Parallel Tasks |
| --- | --- | --- | --- |
| Phase 1: Setup | T001–T002 | 2 | T002 |
| Phase 2: Foundational | T003–T007 | 5 | T005 |
| Phase 3: US1 (P1) | T008–T009 | 2 | — |
| Phase 4: US2 (P1) | T010 | 1 | — |
| Phase 5: US3 (P2) | T011 | 1 | — |
| Phase 6: US4 (P2) | T012 | 1 | — |
| Phase 7: Polish | T013–T017 | 5 | T013, T015, T016 |
| **Total** | | **17** | |

---

## Notes

- All `[P]` tasks operate on different files — no file conflicts
- `project_finder.rb` (T008, T010, T011, T012) is intentionally sequential — each story adds one rescue clause; ordering within the rescue chain is critical (NoDatabaseError before DatabaseConnectionError)
- No test tasks generated — constitution §Tech Stack prohibits automated test suite
- The `sinatra.rb` route (T009) handles all error statuses via `result[:status]` — no changes to `sinatra.rb` are needed for US2–US4 once T009 is complete
- Commit after each checkpoint for clean git history aligned to user story delivery
