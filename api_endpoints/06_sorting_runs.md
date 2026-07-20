# Sorting, Run Routing & Transfers

**Base URL:** `https://api-hermes.pathao.com/talaria`

---

## POST /api/v1/user/sort-delivery

Submit sorted order for the delivery list.

**Bundle constant:** `DELIVERY_LIST_SORT_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "delivery_ids": [10, 5, 3, 8, 2]
}
```

### Success Response `200`

```json
{ "message": "Delivery list sorted successfully" }
```

---

## GET /api/v1/user/runs/:runRouteId

Get details of a specific delivery run/shift.

**Bundle constant:** `DELIVERY_SHIFT_URL`  
**Auth required:** Yes

### URL Parameters

| Param | Type | Description |
|-------|------|-------------|
| `runRouteId` | int | Run route identifier |

### Success Response `200`

```json
{
  "data": {
    "run_route_id": 42,
    "status": "active",
    "started_at": "2026-07-17T08:00:00Z",
    "deliveries_total": 25,
    "deliveries_done": 12
  }
}
```

---

## GET /api/v1/user/transfers

Get the VDA (Volume Delivery Agent) delivery transfer list.

**Bundle constant:** `VDA_DELIVERY_LISTS_URL`  
**Auth required:** Yes

---

## GET /api/v1/user/transfers/:runRouteId

Get VDA delivery transfer status for a specific run route.

**Bundle constant:** `VDA_DELIVERY_STATUS_URL`  
**Auth required:** Yes

### URL Parameters

| Param | Type | Description |
|-------|------|-------------|
| `runRouteId` | int | Run route identifier |

---

## GET /api/v1/user/pick-merchant-orders

Get the list of merchant orders to pick for the current shift.

**Bundle constant:** `PICK_MERCHANT_ORDERS_URL`  
**Auth required:** Yes

---

## POST /api/v1/user/pick-merchant-orders-done

Mark merchant order picking as complete.

**Bundle constant:** `PICK_MERCHANT_ORDERS_DONE_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "run_route_id": 42,
  "orders_picked": [101, 102, 103]
}
```
