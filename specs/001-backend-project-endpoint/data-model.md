# Data Model: Backend GET /project/:id Endpoint

**Branch**: `001-backend-project-endpoint` | **Date**: 2026-03-25

---

## Entity: Project

**Table**: `projects`
**Model file**: `backend/models/project.rb`
**AR class**: `Project < ActiveRecord::Base`

### Attributes

| Column | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | `bigserial` | PRIMARY KEY, NOT NULL, auto-increment | AR default integer PK |
| `name` | `string` (VARCHAR) | NOT NULL | Project display name |
| `description` | `text` | NULLABLE | Long-form project description |
| `status` | `string` (VARCHAR) | NOT NULL, DEFAULT `'active'` | Lifecycle state: `active` or `inactive` |
| `created_at` | `timestamp` | NOT NULL | AR standard timestamp |
| `updated_at` | `timestamp` | NOT NULL | AR standard timestamp |

### Validations (Model Layer)

- `name`: presence required
- `status`: inclusion in `%w[active inactive]`

### State Transitions

```text
         ┌──────────┐
  create │  active  │ ←──── default on creation
         └────┬─────┘
              │ (future feature, not in scope)
              ▼
         ┌──────────┐
         │ inactive │
         └──────────┘
```

Status transitions are **out of scope** for this feature. The column is present and validated, but no transition logic is implemented here.

---

## Migration

**File**: `backend/db/migrate/20260325000000_create_projects.rb`

```ruby
class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.text   :description
      t.string :status, null: false, default: 'active'
      t.timestamps
    end
  end
end
```

---

## JSON Serialisation

### Success response (HTTP 200)

```json
{
  "project": {
    "id": 1,
    "name": "My Project",
    "description": "A sample project",
    "status": "active"
  }
}
```

Fields serialised: `id`, `name`, `description`, `status`.
Fields **excluded** from response: `created_at`, `updated_at` (internal).

### Error response (all error cases)

```json
{
  "error": "descriptive message"
}
```

---

## Connection Configuration

**Files**: `backend/config/database.yml` (parameters) + `backend/config/database.rb` (loader)

All parameters supplied via ENV vars, interpolated into `database.yml` via ERB (`<%= ENV.fetch(...) %>`):

| ENV var | YAML key | Default |
| --- | --- | --- |
| `DB_HOST` | `host` | `localhost` |
| `DB_PORT` | `port` | `5432` |
| `DB_NAME` | `database` | _(required — KeyError at boot if absent)_ |
| `DB_USER` | `username` | `postgres` |
| `DB_PASSWORD` | `password` | `''` |
| `DB_POOL` | `pool` | `5` |
| `RACK_ENV` | _(selects YAML block)_ | `development` |
| _(hardcoded)_ | `connect_timeout` | `5` (seconds) |
| _(hardcoded)_ | `adapter` | `postgresql` |
