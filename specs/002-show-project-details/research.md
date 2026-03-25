# Research: Show Project Details on Main Page

**Feature**: 002-show-project-details
**Date**: 2026-03-25

## Findings

### Decision: Reuse `BackendClient` without modification

- **Decision**: Call `BackendClient.fetch(backend_url, '/project/1')` from a new `fetch_project_details` helper in `app.rb`. No changes to `backend_client.rb`.
- **Rationale**: `BackendClient.fetch` already accepts any path and returns either a parsed hash or `{ error: "..." }` on failure. Adding a second helper in `app.rb` follows the same pattern as the existing `fetch_backend_response` — DRY by reuse, not duplication.
- **Alternatives considered**: Adding a `fetch_project` method directly inside `BackendClient` — rejected because `BackendClient` already handles the generic case; a new wrapper would be speculative abstraction (YAGNI violation).

### Decision: No new gems required

- **Decision**: Use HTTParty already in `frontend/Gemfile`.
- **Rationale**: `BackendClient` already uses HTTParty. No additional HTTP client needed.
- **Alternatives considered**: Net::HTTP (stdlib) — unnecessary when HTTParty is already a declared dependency.

### Decision: Success/error state determined by presence of `error` key in response

- **Decision**: In the view helper, check `response.key?('error')` to distinguish error from success.
- **Rationale**: `BackendClient.fetch` returns `{ error: ... }` (symbol key, then `parsed_response` converts to string key) for all failure paths (HTTP error, network error, parse error). A successful response contains `{ "project" => { ... } }`.
- **Alternatives considered**: HTTP status code inspection — not available at the `app.rb` level since `BackendClient` already abstracts it into a hash.

### Decision: Display all fields returned inside `response['project']`

- **Decision**: Iterate over `response['project']` key-value pairs in the ERB template.
- **Rationale**: Spec requires "all fields returned by the backend". Backend returns `id`, `name`, `description`, `status`. Iterating the hash future-proofs the display without hardcoding field names.
- **Alternatives considered**: Hardcode field names — rejected because spec explicitly states "all fields returned".

### Decision: Colors — `#e8f8e8` (green) and `#f8e8e8` (muted red)

- **Decision**: Use `background-color: #e8f8e8` for success (matches existing `.env-var.backend` class) and `background-color: #f8e8e8` for error (muted red, spec assumption).
- **Rationale**: Consistent with the existing color palette on the page.
- **Alternatives considered**: Tailwind or external CSS — prohibited (no extra dependencies).

## No NEEDS CLARIFICATION items remain

All unknowns resolved. Proceed to Phase 1.
