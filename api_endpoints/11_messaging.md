# Messaging (Consignment Chat)

**Base URL:** `https://api-hermes.pathao.com/talaria`

---

## GET /api/v1/user/deliveries/messages

Get all messages across **all** delivery consignments (inbox overview).

**Bundle constant:** `GET_ALL_MESSAGES_URL`  
**Auth required:** Yes

### Query Parameters

| Param | Type | Description |
|-------|------|-------------|
| `page` | int | Pagination page |
| `per_page` | int | Items per page |
| `unread` | bool | Filter unread only |

### Success Response `200`

```json
{
  "data": [
    {
      "consignment_id": "DTK0000001",
      "last_message": "I'm on my way",
      "unread_count": 2,
      "updated_at": "2026-07-17T11:00:00Z"
    }
  ]
}
```

---

## GET /api/v1/user/deliveries/:consignment_id/messages

Get the message thread for a specific consignment.

**Bundle constant:** `GET_CONSIGNMENT_WISE_MESSAGES_URL`  
**Auth required:** Yes

### URL Parameters

| Param | Type | Description |
|-------|------|-------------|
| `consignment_id` | string | e.g. `DTK0000001` |

### Success Response `200`

```json
{
  "data": [
    {
      "id": 1,
      "sender": "agent",
      "message": "I will be there in 10 mins",
      "sent_at": "2026-07-17T10:55:00Z"
    },
    {
      "id": 2,
      "sender": "customer",
      "message": "Ok, I'll wait",
      "sent_at": "2026-07-17T10:57:00Z"
    }
  ]
}
```

---

## POST /api/v1/user/deliveries/:consignment_id/messages

Send a new message on a specific consignment thread.

**Bundle constant:** `SEND_NEW_MESSAGE_URL`  
**Auth required:** Yes

### URL Parameters

| Param | Type | Description |
|-------|------|-------------|
| `consignment_id` | string | e.g. `DTK0000001` |

### Request Body (JSON)

```json
{
  "message": "I'll arrive in 5 minutes",
  "type": "text"
}
```

---

## PATCH /api/v1/user/deliveries/:consignment_id/messages

Mark messages as **seen/read** for a consignment.

**Bundle constant:** `MARK_MESSAGE_SEEN_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "message_ids": [1, 2, 3]
}
```
