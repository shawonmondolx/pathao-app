# Return Delivery Operations

**Base URL:** `https://api-hermes.pathao.com/talaria`

---

## GET /api/v1/user/return

Get the agent's return delivery list.

**Bundle constant:** `RETURN_DELIVERY_LISTS_URL`  
**Auth required:** Yes

---

## GET /api/v1/user/return/:storeId

Get return delivery details for a specific store/merchant.

**Bundle constants:** `NEXT_PICKUP_RETURN_URL`, `RETURN_ORDER_DETAILS`  
**Auth required:** Yes

### URL Parameters

| Param | Type | Description |
|-------|------|-------------|
| `storeId` | int | Store/merchant ID |

---

## POST /api/v1/user/return

Update/submit a return delivery status.

**Bundle constant:** `RETURN_ORDER_STATUS_UPDATE_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "run_order_id": 67890,
  "status": 4,
  "return_reason_id": 2
}
```

---

## POST /api/v1/user/return-done

Initiate OTP verification for return completion.

**Bundle constant:** `RETURN_ORDER_OTP`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "store_id": 101,
  "consignments": [67890, 67891]
}
```

---

## POST /api/v1/user/return-done-check

Verify OTP for return completion.

**Bundle constant:** `RETURN_ORDER_OTP_CONFIRMATION`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "store_id": 101,
  "otp": "9012"
}
```

---

## POST /api/v1/user/return-sms-resend

Resend OTP SMS for return delivery confirmation.

**Bundle constant:** `RETURN_ORDER_RESEND_OTP`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "store_id": 101
}
```

---

## POST /api/v1/user/sort-return

Submit sorted order for the return delivery list.

**Bundle constant:** `RETURN_DELIVERY_SORT_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "return_ids": [5, 3, 1, 4, 2]
}
```
