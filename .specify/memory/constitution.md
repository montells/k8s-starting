<!--
## Sync Impact Report

**Version change**: 1.0.0 → 1.1.0
**Amendment**: Added database and ORM constraints to Tech Stack Constraints section.

### Modified sections
- Tech Stack Constraints: added ActiveRecord 8 (ORM, backend only) and PostgreSQL 14 (database)

### Added principles / sections
- None

### Removed sections
- None

### Templates requiring updates
- `.specify/templates/plan-template.md` ✅ — Storage field in Technical Context will capture PostgreSQL 14; no structural change needed.
- `.specify/templates/spec-template.md` ✅ — No structural change needed.
- `.specify/templates/tasks-template.md` ✅ — Phase 2 Foundational already covers DB setup tasks; no structural change needed.

### Deferred TODOs
- None. All placeholders resolved.
-->

# Sinatra K8s Tutorial Constitution

## Core Principles

### I. Ruby Excellence

All Ruby code (Sinatra apps in `frontend/` and `backend/`) MUST follow idiomatic Ruby 3.x conventions,
object-oriented design, SOLID principles, and DRY. Specifically:

- **Single Responsibility**: Each class/module MUST have one clear reason to change.
- **Open/Closed**: Classes MUST be open for extension but closed for modification.
- **Liskov Substitution**: Subtypes MUST be substitutable for their base types.
- **Interface Segregation**: Clients MUST NOT be forced to depend on interfaces they do not use.
- **Dependency Inversion**: High-level modules MUST depend on abstractions, not concretions.
- **DRY**: Duplicated logic MUST be extracted into shared modules or helper classes.
- Code MUST use `# frozen_string_literal: true` at the top of every Ruby file.
- Variable and method names MUST be in `snake_case`; classes and modules in `CamelCase`.

### II. Simplicity First (YAGNI)

Ruby application code MUST be kept as simple as the feature requires. No speculative abstractions.

- Features MUST NOT be added unless they are explicitly requested or clearly necessary.
- Premature optimization is PROHIBITED.
- Helper utilities MUST NOT be created for one-off operations.
- Over-engineering, unnecessary indirection, and defensive coding against impossible scenarios
  are PROHIBITED.
- When two designs achieve the same goal, the simpler one MUST be chosen.

### III. Kubernetes Boundary (NON-NEGOTIABLE)

The `k8s/` directory is the **exclusive learning domain of the user**. Claude MUST NOT create,
modify, or delete any file inside `k8s/`.

- All YAML manifests, ConfigMaps, Deployments, Services, Ingress, Volumes, and any other
  Kubernetes resources are managed solely by the user.
- Claude MUST NOT suggest inline edits to files under `k8s/` unless the user explicitly grants
  a one-time exception in writing.
- Violations of this boundary undermine the learning objective of the project and are
  categorically prohibited.

### IV. Modularity & Separation of Concerns

Ruby application code MUST be structured so that each concern lives in its own file/module.

- Sinatra route definitions MUST be separated from business logic.
- Business logic MUST be extracted into plain Ruby objects (POROs) or service objects, not
  embedded inside route blocks.
- Version information MUST live in a dedicated `version.rb` per application.
- Configuration (env vars, defaults) MUST be isolated from routing and business logic.
- Each app directory (`frontend/`, `backend/`) MUST maintain its own self-contained structure
  with no cross-directory Ruby dependencies.

### V. Deploy Scripts & Docker in Scope

Claude MAY freely work on the following files:

- `deploy-backend-local-minikube.sh`
- `deploy-frontend-local-minikube.sh`
- `frontend/Dockerfile`
- `backend/Dockerfile`

Changes to these files MUST remain consistent with the corresponding app's port, image name,
and runtime behavior documented in `README.md` and `AGENTS.md`.

## Tech Stack Constraints

- **Language**: Ruby 3.2 exclusively. No other languages in `frontend/` or `backend/`.
- **Web Framework**: Sinatra. Rails or other full-stack frameworks are PROHIBITED.
- **Web Server**: Puma with Rackup.
- **Base Docker Image**: `ruby:3.2-alpine` to keep images minimal.
- **ORM**: ActiveRecord 8. Used exclusively in `backend/` for database access.
  The `frontend/` app MUST NOT connect to or query any database directly.
- **Database**: PostgreSQL 14. Only the `backend/` application connects to the database.
  All database configuration (host, port, credentials, database name) MUST be supplied
  via environment variables — never hardcoded.
- **Testing**: No automated test suite is required or expected. Quality is achieved through
  clean OOP design and code review, not test coverage.
- **Dependencies**: Gemfile additions MUST be justified by actual feature need. Dev-only gems
  must be in the `:development` group.

## Development Workflow

- New Ruby functionality MUST be introduced in the smallest meaningful unit — one class,
  one module, one route group — per change.
- Dockerfiles and deploy scripts MUST be updated atomically with the Ruby code that changes
  the app's startup, port, or entry point.
- `AGENTS.md` and `README.md` MUST be kept in sync with any structural changes to the apps.
- Changes to `k8s/` are initiated and owned entirely by the user; Claude provides guidance
  only when explicitly asked and NEVER touches the files directly.

## Governance

This constitution supersedes all other development conventions for this project. Amendments
require:

1. A written request in the conversation describing the change and motivation.
2. A version bump following semantic versioning:
   - **MAJOR**: Removal or redefinition of an existing principle.
   - **MINOR**: New principle or section added.
   - **PATCH**: Clarification, wording fix, or non-semantic refinement.
3. Update of `LAST_AMENDED_DATE` to the date of the change.
4. A corresponding update to any affected templates under `.specify/templates/`.

All feature work MUST comply with these principles before implementation begins.
The `AGENTS.md` file serves as the runtime development reference for agents working in
this repository.

**Version**: 1.1.0 | **Ratified**: 2026-03-25 | **Last Amended**: 2026-03-25
