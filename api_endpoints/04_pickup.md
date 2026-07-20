# Pickup Operations

**Base URL:** `https://api-hermes.pathao.com/talaria`

---

## GET /api/v1/user/pickup

Get the agent's pickup assignment list.

**Bundle constant:** `PICKUP_LISTS_URL`  
**Auth required:** Yes

---

## GET /api/v1/user/pickup/:id

Get details of a single pickup task.

**Bundle constant:** `NEXT_PICKUP_URL`  
**Auth required:** Yes

### URL Parameters

| Param | Type | Description |
|-------|------|-------------|
| `id` | int | Pickup task ID |

---

## GET /api/v1/user/pickup/:storeId

Get merchant/store details for a pickup.

**Bundle constant:** `MERCHANT_DETAILS_URL`  
**Auth required:** Yes

### URL Parameters

| Param | Type | Description |
|-------|------|-------------|
| `storeId` | int | Store / merchant ID |

---

## POST /api/v1/user/pickup

Update/confirm a pickup (mark package collected from merchant).

**Bundle constant:** `MERCHANT_PACKAGE_UPDATE_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "store_id": 101,
  "packages": [
    { "consignment_id": "DTK0000001", "collected": true }
  ]
}
```

---

## POST /api/v1/user/pickup-done

Submit OTP received from merchant to confirm pickup completion.

**Bundle constant:** `MERCHANT_OTP`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "store_id": 101,
  "otp": "1234"
}
```

---

## POST /api/v1/user/pickup-done-check

Verify OTP confirmation for pickup.

**Bundle constant:** `MERCHANT_OTP_CONFIRMATION`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "store_id": 101,
  "otp": "1234"
}
```

---

## POST /api/v1/user/pickup-sms-resend

Resend OTP SMS to merchant for pickup confirmation.

**Bundle constant:** `MERCHANT_RESEND_OTP`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "store_id": 101
}
```

---

## POST /api/v1/user/slot-pickup/done

Complete a slot-based pickup.

**Bundle constant:** `MERCHANT_SLOT_PICKUP`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "slot_id": 55,
  "packages_collected": 10
}
```

---

## POST /api/v1/user/slot-pickup/confirm

Confirm a slot-based pickup with OTP.

**Bundle constant:** `MERCHANT_SLOT_PICKUP_CONFIRMATION`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "slot_id": 55,
  "otp": "5678"
}
```

---

## POST /api/v1/user/slot-pickup/pick-again

Re-attempt a slot pickup (used when pick-again is requested).

**Bundle constant:** `PICKUP_AGAIN_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "slot_id": 55,
  "reason": "Merchant not ready"
}
```

---

## POST /api/v1/user/sort-pickup

Submit the sorted order of the pickup list.

**Bundle constant:** `PICKUP_LIST_SORT_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "pickup_ids": [3, 1, 2, 5, 4]
}
```
