# User Profile & Account Management

**Base URL:** `https://api-hermes.pathao.com/talaria`

---

## GET /api/v1/user

Fetch the current agent's profile.

**Bundle constant:** `PROFILE_URL`  
**Auth required:** Yes

### Success Response `200`

```json
{
  "data": {
    "id": 123,
    "name": "Agent Name",
    "phone": "01777884223",
    "email": "agent@example.com",
    "profile_image": "https://cdn.pathao.com/...",
    "agent_type": "delivery"
  }
}
```

---

## POST /api/v1/user/profile-image

Upload/update the agent's profile picture.

**Bundle constant:** `UPLOAD_IMAGE_URL`  
**Auth required:** Yes  
**Content-Type:** `multipart/form-data`

### Request Body

| Field | Type | Description |
|-------|------|-------------|
| `image` | File | The profile image (JPEG/PNG) |

---

## POST /api/v1/user/profile-toggle

Toggle hybrid agent profile mode (switches between delivery and pickup modes).

**Bundle constant:** `HYBRID_AGENT_PROFILE_TOGGLE_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "profile": "delivery"
}
```

---

## DELETE /api/v1/user/delete-account

Request account deletion.

**Bundle constant:** `DELETE_ACCOUNT_URL`  
**Auth required:** Yes

### Request Body

_Empty or `{}`_

### Success Response `200`

```json
{ "message": "Account deletion request submitted" }
```

---

## GET /api/v1/user/agent-ratings

Get the agent's performance ratings.

**Bundle constant:** `AGENT_RATINGS_URL`  
**Auth required:** Yes

### Success Response `200`

```json
{
  "data": {
    "average_rating": 4.7,
    "total_ratings": 342,
    "breakdown": { "5": 200, "4": 100, "3": 32, "2": 8, "1": 2 }
  }
}
```

---

## GET /api/v1/user/agent-reviews

Get written reviews for the agent.

**Bundle constant:** `AGENT_REVIEWS_URL`  
**Auth required:** Yes

### Query Parameters

| Param | Type | Description |
|-------|------|-------------|
| `page` | int | Pagination page number |
| `per_page` | int | Items per page |

### Success Response `200`

```json
{
  "data": [
    {
      "id": 1,
      "rating": 5,
      "comment": "Great service!",
      "created_at": "2026-07-01T10:00:00Z"
    }
  ]
}
```
