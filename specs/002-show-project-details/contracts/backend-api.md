# Contract: Backend API — Project by ID

**Consumer**: `frontend/app.rb` (via `BackendClient`)
**Provider**: `backend/sinatra.rb`
**Endpoint**: `GET /project/:id`

## Request

```
GET /project/1
Host: <BACKEND_URL>
```

No authentication. No request body.

## Success Response

**Status**: `200 OK`
**Content-Type**: `application/json`

```json
{
  "project": {
    "id": 1,
    "name": "My Project",
    "description": "A project description",
    "status": "active"
  }
}
```

## Error Responses

### 404 — Project not found

```json
{ "error": "Project not found" }
```

### 400 — Invalid ID format

```json
{ "error": "Invalid project ID format" }
```

### 503 — Database unavailable

```json
{ "error": "Database does not exist" }
```

```json
{ "error": "Database connection failed" }
```

```json
{ "error": "Database error" }
```

## Frontend handling

`BackendClient.fetch` returns:

- On 2xx: `{ "project" => { ... } }` — display with green background
- On non-2xx: `{ error: "HTTP <code>: <message>" }` — display with red background
- On network/parse error: `{ error: "<exception message>" }` — display with red background

Detection in `app.rb`: `response.key?('error')` → error state; otherwise → success state.

## No contract changes required

The backend endpoint `GET /project/:id` already exists and is unchanged by this feature.
