# Miscellaneous Endpoints

**Base URL:** `https://api-hermes.pathao.com/talaria`

---

## GET /api/v1/dashboard

Get the agent's dashboard summary (overview stats).

**Bundle constant:** `DASHBOARD_URL`  
**Auth required:** Yes

### Success Response `200`

```json
{
  "data": {
    "earnings_so_far": 12000,
    "deliveries_today": 15,
    "deliveries_done": 10,
    "pickups_pending": 3,
    "assignment_pending": 5,
    "cash_in_hand": 5000,
    "rating": 4.7
  }
}
```

---

## GET /api/v1/delivery/hold-reasons

Get the list of hold reasons (why a delivery was not completed).

**Bundle constant:** `DELIVERY_HOLD_REASONS_URL`  
**Auth required:** Yes

### Success Response `200`

```json
{
  "data": [
    { "id": 1, "reason": "Customer not available" },
    { "id": 2, "reason": "Wrong address" },
    { "id": 3, "reason": "Customer refused delivery" },
    { "id": 4, "reason": "Area flooded/inaccessible" }
  ]
}
```

---

## GET /api/v1/delivery/return-reasons

Get the list of return reasons.

**Bundle constant:** `DELIVERY_RETURN_REASONS_URL`  
**Auth required:** Yes

### Success Response `200`

```json
{
  "data": [
    { "id": 1, "reason": "Merchant requested return" },
    { "id": 2, "reason": "Customer refused" },
    { "id": 3, "reason": "Damaged parcel" }
  ]
}
```

---

## GET /api/v1/user/merchant-search

Search for merchants by name or phone number (for cash handover or reference).

**Bundle constant:** `MERCHANT_SEARCH_URL`  
**Auth required:** Yes

### Query Parameters

| Param | Type | Description |
|-------|------|-------------|
| `q` | string | Search term (name or phone) |

### Success Response `200`

```json
{
  "data": [
    {
      "id": 501,
      "name": "Shop ABC",
      "phone": "01700000999",
      "address": "Gulshan-2, Dhaka"
    }
  ]
}
```
