# GPS Location & Ping

**Base URL:** `https://api-hermes.pathao.com/talaria`

---

## POST /api/v1/user/latlon

Submit the agent's current GPS coordinates (live location update).

**Bundle constant:** `POI_URL`  
**Auth required:** Yes

> This endpoint is called **periodically** by the foreground location service (`ForegroundServiceChecker` native module) to keep the server updated with the agent's real-time position.

### Request Body (JSON)

```json
{
  "latitude": 23.8103,
  "longitude": 90.4125,
  "accuracy": 10.5,
  "timestamp": "2026-07-17T10:30:00Z"
}
```

### Success Response `200`

```json
{ "status": "ok" }
```

---

## POST /api/v1/pings

Submit a periodic ping to keep the session alive and report location.

**Bundle constant:** `SUBMIT_PINGS_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "latitude": 23.8103,
  "longitude": 90.4125,
  "battery": 85,
  "timestamp": "2026-07-17T10:30:00Z"
}
```

---

## GET /api/v1/pings/config

Fetch the ping configuration (interval, frequency settings).

**Bundle constant:** `GET_PINGS_CONFIG_URL`  
**Auth required:** Yes

### Success Response `200`

```json
{
  "data": {
    "ping_interval_seconds": 30,
    "location_interval_seconds": 10,
    "background_enabled": true
  }
}
```
