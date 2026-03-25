# k8s-starting Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-03-25

## Active Technologies
- PostgreSQL 14 — table `projects`, accessed only from `backend/` (001-backend-project-endpoint)
- Ruby 3.2 + Sinatra 4.x, HTTParty (already in `frontend/Gemfile`), ERB (built-in) (002-show-project-details)
- N/A — frontend does not connect to any database; all data via backend API (002-show-project-details)

- Ruby 3.2 + Sinatra 4.x, Puma 7.x, Rackup 2.x, ActiveRecord 8.x, pg ~> 1.5, Rake ~> 13.0 (001-backend-project-endpoint)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Ruby 3.2

## Code Style

Ruby 3.2: Follow standard conventions

## Recent Changes
- 002-show-project-details: Added Ruby 3.2 + Sinatra 4.x, HTTParty (already in `frontend/Gemfile`), ERB (built-in)
- 001-backend-project-endpoint: Added Ruby 3.2 + Sinatra 4.x, Puma 7.x, Rackup 2.x, ActiveRecord 8.x, pg ~> 1.5, Rake ~> 13.0

- 001-backend-project-endpoint: Added Ruby 3.2 + Sinatra 4.x, Puma 7.x, Rackup 2.x, ActiveRecord 8.x, pg ~> 1.5, Rake ~> 13.0

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
