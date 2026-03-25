# Implementation Plan: Show Project Details on Main Page

**Branch**: `002-show-project-details` | **Date**: 2026-03-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-show-project-details/spec.md`

## Summary

Add a new section to the frontend main page that renders below "Backend Response", showing project id 1 details on a green background (success) or the backend error message on a red background (error). Data is fetched server-side by reusing the existing `BackendClient` module before the page is rendered.

## Technical Context

**Language/Version**: Ruby 3.2
**Primary Dependencies**: Sinatra 4.x, HTTParty (already in `frontend/Gemfile`), ERB (built-in)
**Storage**: N/A — frontend does not connect to any database; all data via backend API
**Testing**: None required
**Target Platform**: Linux container (Puma/Rackup, port 8080)
**Project Type**: web-service (frontend Sinatra app)
**Performance Goals**: No additional requirements beyond existing page load
**Constraints**: No new gems; no database access from frontend; server-side render only
**Scale/Scope**: Single page, single backend call per page load

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
| --------- | ------ | ----- |
| I. Ruby Excellence (SOLID, DRY, frozen_string_literal) | ✅ PASS | Reuse `BackendClient`; extract helper method; no duplication |
| II. Simplicity First (YAGNI) | ✅ PASS | One new helper method + one ERB section; no new abstractions |
| III. Kubernetes Boundary | ✅ PASS | No files under `k8s/` are touched |
| IV. Modularity — routes separated from business logic | ✅ PASS | Route calls a helper; BackendClient handles HTTP; ERB handles display |
| V. Deploy Scripts & Docker in Scope | ✅ PASS | No Docker or deploy script changes needed |
| Tech Stack — no new gems | ✅ PASS | HTTParty already in Gemfile; no additions required |
| Tech Stack — no DB from frontend | ✅ PASS | Frontend calls backend API, never the DB |

**Gate result: ALL PASS. Proceed.**

## Project Structure

### Documentation (this feature)

```text
specs/002-show-project-details/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── backend-api.md
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
frontend/
├── app.rb               # ADD: fetch_project_details helper + @project_details assignment in GET /
├── backend_client.rb    # NO CHANGE — reused as-is
└── views/
    └── index.erb        # ADD: new <div> section below "Backend Response"

backend/
└── sinatra.rb           # NO CHANGE — GET /project/:id already exists
```

**Structure Decision**: Web application (Option 2 from template), frontend-only changes. No backend modifications required.

## Complexity Tracking

> No constitution violations — table not required.
