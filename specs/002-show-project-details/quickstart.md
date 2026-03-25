# Quickstart: Show Project Details on Main Page

**Feature**: 002-show-project-details
**Date**: 2026-03-25

## What changes

Two files in `frontend/` are modified. No backend changes. No new gems.

### 1. `frontend/app.rb` — add helper + assign instance variable

Add a `fetch_project_details` helper that reuses `BackendClient`:

```ruby
def fetch_project_details(id)
  backend_url = ENV.fetch('BACKEND_URL', 'http://localhost:8081')
  BackendClient.fetch(backend_url, "/project/#{id}")
end
```

In the `GET /` route, call it and split the result into two instance variables:

```ruby
result = fetch_project_details(1)
if result.key?('error')
  @project_error   = result['error'] || result[:error]
else
  @project_details = result['project']
end
```

### 2. `frontend/views/index.erb` — add new section below "Backend Response"

```erb
<!-- Project Details Section -->
<% if @project_error %>
  <div class="env-var project-error">
    <span class="label">Project #1 Error:</span>
    <span class="value error"><%= @project_error %></span>
  </div>
<% else %>
  <div class="env-var project-success">
    <span class="label">Project #1:</span>
    <% @project_details.each do |field, value| %>
      <div class="project-field">
        <span class="label"><%= field %>:</span>
        <span class="value"><%= value %></span>
      </div>
    <% end %>
  </div>
<% end %>
```

CSS additions (inside the existing `<style>` block):

```css
.env-var.project-success {
  background-color: #e8f8e8;
}
.env-var.project-error {
  background-color: #f8e8e8;
}
.value.error {
  color: #cc0000;
  font-weight: bold;
}
.project-field {
  margin: 4px 0;
}
```

## Running locally

```bash
cd frontend
rvm use 3.2
BACKEND_URL=http://localhost:8081 bundle exec rackup -p 8080
```

Open `http://localhost:8080` — the new "Project #1" section appears below "Backend Response".

## Key reuse point

`BackendClient.fetch` in `frontend/backend_client.rb` is **unchanged**. The feature only adds a second call site with a different path (`/project/1`). This is the entire integration surface.
