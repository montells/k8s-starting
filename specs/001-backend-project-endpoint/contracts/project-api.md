# API Contract: GET /project/:id

**Service**: Backend (Sinatra, port 8081)
**Version**: Unversioned (route: `/project/:id`)
**Content-Type**: `application/json` (all responses)

---

## Endpoint

```
GET /project/:id
```

### Path Parameter

| Parameter | Type | Validation | Description |
|---|---|---|---|
| `id` | string (path) | Must match `/\A\d+\z/` | Project integer ID |

---

## Responses

### 200 OK — Project found

```json
{
  "project": {
    "id": 1,
    "name": "string",
    "description": "string | null",
    "status": "active | inactive"
  }
}
```

### 400 Bad Request — Invalid ID format

Triggered when `:id` is not a positive integer string (e.g., `/project/abc`, `/project/1.5`).

```json
{
  "error": "Invalid project ID format"
}
```

### 404 Not Found — Project does not exist

```json
{
  "error": "Project not found"
}
```

### 503 Service Unavailable — Database connection failure

```json
{
  "error": "Database connection failed"
}
```

### 503 Service Unavailable — Database does not exist

```json
{
  "error": "Database does not exist"
}
```

### 503 Service Unavailable — Generic database error

```json
{
  "error": "Database error"
}
```

---

## Guarantees

1. **No crash**: The application NEVER stops regardless of error type.
2. **Always JSON**: Every response carries `Content-Type: application/json`.
3. **All errors logged**: Every non-200 response is logged to stdout.
4. **Timeout bound**: 503 responses under connection failure are returned within 5 seconds (connect_timeout).

---

## Error Logging Format

All errors are logged to `$stdout` with prefix `[ERROR]`:

```
[ERROR] Invalid project ID format: abc
[ERROR] Project not found: id=42
[ERROR] Database does not exist: <ar message>
[ERROR] Database connection failed: <ar message>
[ERROR] Database error: <ar message>
```
