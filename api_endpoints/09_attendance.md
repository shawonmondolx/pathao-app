# Agent Attendance & Shift Management

**Base URL:** `https://api-hermes.pathao.com/talaria`

---

## GET /api/v1/attendances/daily

Get the agent's daily attendance record.

**Bundle constant:** `DAILY_ATTENDANCE_URL`  
**Auth required:** Yes

### Query Parameters

| Param | Type | Description |
|-------|------|-------------|
| `date` | string | Date in `YYYY-MM-DD` format |

### Success Response `200`

```json
{
  "data": {
    "date": "2026-07-17",
    "entry_time": "2026-07-17T08:00:00Z",
    "exit_time": null,
    "status": "active"
  }
}
```

---

## POST /api/v1/attendances/submit/entry

Submit shift entry (clock-in) for the agent.

**Bundle constant:** `DAILY_ATTENDANCE_SUBMIT_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "latitude": 23.8103,
  "longitude": 90.4125,
  "timestamp": "2026-07-17T08:00:00Z"
}
```

### Success Response `200`

```json
{
  "message": "Attendance updated successfully!",
  "entry_time": "2026-07-17T08:00:00Z"
}
```

---

## POST /api/v1/attendances/submit/exit

Submit shift exit (clock-out) for the agent.

**Bundle constant:** `DAILY_ATTENDANCE_SUBMIT_EXIT_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "latitude": 23.8103,
  "longitude": 90.4125,
  "timestamp": "2026-07-17T17:30:00Z"
}
```

### Success Response `200`

```json
{
  "message": "Attendance updated successfully!",
  "exit_time": "2026-07-17T17:30:00Z"
}
```
