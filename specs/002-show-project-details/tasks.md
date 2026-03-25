# Tasks: Show Project Details on Main Page

**Input**: Design documents from `/specs/002-show-project-details/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: Not requested — omitted per constitution (no test suite required).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1)
- Exact file paths included in all descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm no setup is needed — all infrastructure already exists.

> No tasks. `BackendClient` (HTTParty), `frontend/app.rb`, `frontend/views/index.erb`, and the backend `GET /project/:id` endpoint are all in place. No new gems, no new files, no migrations.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure required before user story work.

> No tasks. `BackendClient.fetch(url, path)` already handles any backend path. The frontend `app.rb` already has the `fetch_backend_response` pattern to follow. No shared infrastructure to build.

**Checkpoint**: Foundation confirmed — user story implementation can begin immediately.

---

## Phase 3: User Story 1 — View Project Details on Main Page (Priority: P1) 🎯 MVP

**Goal**: Add a new section below "Backend Response" on the main page that shows project id 1 fields on a green background (success) or an error message on a red background (failure). Data fetched server-side on every page load by reusing `BackendClient`.

**Independent Test**: Load `http://localhost:8080` — a new "Project #1" section is visible directly below "Backend Response". When the backend is healthy, fields appear on a green background. When the backend returns an error (or is unreachable), the error message appears on a red background.

### Implementation for User Story 1

- [x] T001 [US1] Add `fetch_project_details` helper method to `frontend/app.rb` — calls `BackendClient.fetch(backend_url, '/project/1')` using the same `BACKEND_URL` env var pattern as `fetch_backend_response`
- [x] T002 [US1] Assign `@project_details` and `@project_error` instance variables in the `GET /` route in `frontend/app.rb` — call `fetch_project_details`, set `@project_error` if `response.key?('error')`, else set `@project_details = response['project']`
- [x] T003 [US1] Add CSS classes `project-success` (`background-color: #e8f8e8`), `project-error` (`background-color: #f8e8e8`), `value.error` (dark red), and `project-field` inside the `<style>` block in `frontend/views/index.erb`
- [x] T004 [US1] Add project details HTML section directly below the "Backend Response" `<div>` in `frontend/views/index.erb` — conditionally render all `@project_details` key-value pairs on green background or `@project_error` message on red background

**Checkpoint**: User Story 1 fully functional. Load the main page — the new section renders with correct background color in both success and error states.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup.

- [ ] T005 Manually verify all three acceptance scenarios from spec.md against the running frontend: (1) green section with project fields, (2) red section with error message, (3) section always present below "Backend Response"

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Skipped — no work needed
- **Foundational (Phase 2)**: Skipped — no work needed
- **User Story 1 (Phase 3)**: Can start immediately
- **Polish (Phase 4)**: Depends on Phase 3 completion

### User Story Dependencies

- **User Story 1 (P1)**: Only user story — no inter-story dependencies

### Within User Story 1

```
T001 (helper method)
  └── T002 (route assignment, depends on T001)
T003 (CSS, no dependencies)
  └── T004 (HTML section, depends on T002 + T003)
        └── T005 (manual verification)
```

T001 and T003 can start in parallel (different concerns in the same file for T001, different file for T003).
T002 depends on T001 completing. T004 depends on both T002 and T003 completing.

### Parallel Opportunities

- **T001 + T003**: Start simultaneously — T001 touches `app.rb`, T003 touches `index.erb`
- **T002 → T004**: Sequential chain after T001/T003 are done

---

## Parallel Example: User Story 1

```bash
# Start in parallel:
Task T001: "Add fetch_project_details helper method in frontend/app.rb"
Task T003: "Add CSS classes in frontend/views/index.erb"

# Then in parallel once both above complete:
Task T002: "Assign @project_details / @project_error in GET / in frontend/app.rb"

# Then once T002 + T003 complete:
Task T004: "Add project details HTML section in frontend/views/index.erb"
```

---

## Implementation Strategy

### MVP (User Story 1 Only — this IS the entire feature)

1. ~~Phase 1: Setup~~ — skipped
2. ~~Phase 2: Foundational~~ — skipped
3. Complete Phase 3: User Story 1 (T001 → T003 in parallel, then T002 → T004)
4. **STOP and VALIDATE**: Load main page, check green/red states
5. Ready to deploy

### Incremental Delivery

Single story, single increment. T001+T003 → T002 → T004 → validate.

---

## Notes

- [P] on T001/T003 means they touch different files and can be done simultaneously
- No tests — constitution explicitly prohibits them
- No new gems — HTTParty already in `frontend/Gemfile`
- `backend_client.rb` is NOT modified — reused as-is
- `backend/` files are NOT modified — `GET /project/:id` already exists
- `k8s/` is NOT touched — constitution boundary
- Commit after T004 when the feature is visually verified
