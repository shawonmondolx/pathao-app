# Cash, Wallet, Earnings & Payment

**Base URL:** `https://api-hermes.pathao.com/talaria`

---

## GET /api/v1/user/earnings

Get the agent's earnings summary.

**Bundle constant:** `DELIVERY_EARNINS_URL`  
**Auth required:** Yes

### Query Parameters

| Param | Type | Description |
|-------|------|-------------|
| `from` | date | Start date (YYYY-MM-DD) |
| `to`   | date | End date (YYYY-MM-DD) |

### Success Response `200`

```json
{
  "data": {
    "total_earnings": 15000,
    "pending": 3000,
    "paid": 12000,
    "period": "2026-07-01 to 2026-07-17"
  }
}
```

---

## GET /api/v1/user/payment-info

Get the agent's payment/cash collection information.

**Bundle constant:** `PAYMENT_URL`  
**Auth required:** Yes

### Success Response `200`

```json
{
  "data": {
    "cash_in_hand": 5000,
    "to_be_deposited": 3000,
    "last_deposit": "2026-07-15T14:00:00Z"
  }
}
```

---

## POST /api/v1/user/payments/send-link

Send a payment collection link to a customer.

**Bundle constant:** `SEND_PAYMENT_LINK_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "consignment_id": "DTK0000001",
  "phone": "01700000000",
  "amount": 500
}
```

### Success Response `200`

```json
{
  "message": "Payment link sent successfully",
  "link": "https://pay.pathao.com/..."
}
```

---

## GET /api/v1/wallet-list

Get the list of deposit wallets (bank branches / bKash agents).

**Bundle constant:** `WALLET_LIST_URL`  
**Auth required:** Yes

### Success Response `200`

```json
{
  "data": [
    { "id": 1, "name": "Pathao Headquarters", "type": "office" },
    { "id": 2, "name": "bKash Agent - Mirpur", "type": "bkash" }
  ]
}
```

---

## GET /api/v1/wallet-list/:walletId/branch

Get branch details for a specific wallet/deposit location.

**Bundle constant:** `WALLET_BRANCH_LIST_URL`  
**Auth required:** Yes

### URL Parameters

| Param | Type | Description |
|-------|------|-------------|
| `walletId` | int | Wallet/deposit location ID |

---

## GET /api/v1/xdp-payment-info/:agentId

Get XDP (Cross-Delivery Point) payment information for an agent.

**Bundle constant:** `XDP_PAYMENT_INFO_URL`  
**Auth required:** Yes

### URL Parameters

| Param | Type | Description |
|-------|------|-------------|
| `agentId` | int | Agent ID |

---

## POST /api/v1/xdp-payment-info/:agentId

Confirm XDP payment.

**Bundle constant:** `XDP_PAYMENT_CONFIRM_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "amount": 5000,
  "reference": "XDP20260717001"
}
```

---

## GET /api/v1/user/merchant-search

Search for merchants by name/phone for cash handover.

**Bundle constant:** `MERCHANT_SEARCH_URL`  
**Auth required:** Yes

### Query Parameters

| Param | Type | Description |
|-------|------|-------------|
| `q` | string | Search query (name or phone) |
