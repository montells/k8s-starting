# Data Model: Show Project Details on Main Page

**Feature**: 002-show-project-details
**Date**: 2026-03-25

## Entities

### Project (read-only, sourced from backend API)

The frontend never accesses the database directly. Project data arrives as a parsed JSON hash from the backend endpoint `GET /project/1`.

| Field | Type | Notes |
| ----- | ---- | ----- |
| id | Integer | Database primary key |
| name | String | Required, not null |
| description | String (text) | Optional |
| status | String | `"active"` or `"inactive"` |

Fields `created_at` and `updated_at` are excluded by the backend (`as_json(only: %i[id name description status])`).

### ErrorResponse (runtime state, not persisted)

Represents any failure path returned or synthesized by `BackendClient`.

| Field | Type | Notes |
| ----- | ---- | ----- |
| error | String | Human-readable message: HTTP error, network error, or "Project not found" |

## View State

The ERB template receives one of two mutually exclusive instance variables:

| Variable | Type | Condition |
| -------- | ---- | --------- |
| `@project_details` | `Hash` with key `"project"` → nested hash | Backend returned 2xx with project payload |
| `@project_error` | `String` | Any error path (4xx, 5xx, network, parse failure) |

Exactly one is non-nil on every page render.

## No schema changes required

This feature is purely additive to the frontend view layer. No database migrations, no model changes, no backend changes.
