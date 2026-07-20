# Delivery Operations

**Base URL:** `https://api-hermes.pathao.com/talaria`

---

## GET /api/v1/user/delivery

Get the agent's current delivery assignment list.

**Bundle constant:** `DELIVERY_ASSIGNMENT_URL`  
**Auth required:** Yes

### Query Parameters

| Param | Type | Description |
|-------|------|-------------|
| `status` | int | Filter by delivery status |
| `page` | int | Pagination |

### Success Response `200`

```json
{
  "data": [
    {
      "id": 1,
      "consignment_id": "DTK0000001",
      "merchant_name": "Shop XYZ",
      "recipient_name": "John Doe",
      "recipient_phone": "01700000000",
      "delivery_address": "House 1, Road 2, Dhaka",
      "amount": 500,
      "status": 1
    }
  ]
}
```

---

## GET /api/v1/user/delivery/:consignmentId

Get details of a specific delivery/consignment.

**Bundle constant:** `DELIVERY_DETAILS_URL`  
**Auth required:** Yes

### URL Parameters

| Param | Type | Description |
|-------|------|-------------|
| `consignmentId` | string | The consignment ID (e.g. `DTK0000001`) |

---

## POST /api/v1/user/delivery

Update a delivery status (mark delivered/held/etc.).

**Bundle constant:** `DELIVERY_UPDATE_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "run_order_id": 12345,
  "status": 2,
  "note": "Delivered to neighbour"
}
```

### Delivery Status Codes

| Code | Meaning |
|------|---------|
| `1` | Picked up |
| `2` | Delivered |
| `3` | On hold |
| `4` | Returned |

---

## POST /api/v1/user/delivery/check

Confirm delivery completion (triggers OTP or proof verification).

**Bundle constant:** `DELIVERY_COMPLETE_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "run_order_id": 12345,
  "status": 2,
  "proof_image": "base64_or_url",
  "otp": "1234"
}
```

---

## POST /api/v1/user/delivery/check/qc-otp

Verify QC OTP for delivery confirmation.

**Bundle constant:** `POST_QC_OTP_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "run_order_id": 12345,
  "otp": "1234"
}
```

---

## POST /api/v1/user/delivery/sms-resend

Resend the delivery OTP SMS to the customer.

**Bundle constant:** `DELIVERY_SMS_RESEND_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "run_order_id": 12345
}
```

---

## GET /api/v1/user/deliveries/messages

Get all messages across all delivery consignments.

**Bundle constant:** `GET_ALL_MESSAGES_URL`  
**Auth required:** Yes

---

## GET /api/v1/user/deliveries/:consignment_id/messages

Get messages for a specific consignment.

**Bundle constant:** `GET_CONSIGNMENT_WISE_MESSAGES_URL`  
**Auth required:** Yes

### URL Parameters

| Param | Type | Description |
|-------|------|-------------|
| `consignment_id` | string | Consignment ID |

---

## POST /api/v1/user/deliveries/:consignment_id/messages

Send a new message on a consignment.

**Bundle constant:** `SEND_NEW_MESSAGE_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "message": "I will arrive in 10 minutes",
  "type": "text"
}
```

---

## PATCH /api/v1/user/deliveries/:consignment_id/messages

Mark messages as seen on a consignment.

**Bundle constant:** `MARK_MESSAGE_SEEN_URL`  
**Auth required:** Yes

---

## POST /api/v1/user/deliveries/:runRouteOrderId/approve

Approve a delivery order in a run route.

**Bundle constant:** `DELIVERY_APPROVE_URL`  
**Auth required:** Yes

### URL Parameters

| Param | Type | Description |
|-------|------|-------------|
| `runRouteOrderId` | int | Run route order ID |

---

## GET /api/v1/delivery/hold-reasons

Get the list of available hold reasons for a delivery.

**Bundle constant:** `DELIVERY_HOLD_REASONS_URL`  
**Auth required:** Yes

### Success Response `200`

```json
{
  "data": [
    { "id": 1, "reason": "Customer not available" },
    { "id": 2, "reason": "Wrong address" },
    { "id": 3, "reason": "Customer refused" }
  ]
}
```

---

## GET /api/v1/delivery/return-reasons

Get the list of available return reasons.

**Bundle constant:** `DELIVERY_RETURN_REASONS_URL`  
**Auth required:** Yes
