# QC (Quality Control) & File Upload

**Base URL:** `https://api-hermes.pathao.com/talaria`

---

## POST /api/v1/qc-request

Submit a QC proof request (barcode scan + image proof for consignment).

**Bundle constant:** `POST_REQUEST_QC_WITH_PROOF_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "consignment_id": "DTK0000001",
  "scanned_barcode": "DTK0000001_BARCODE",
  "proof_image_url": "https://cdn.pathao.com/proof/...",
  "proof_type": "qr_scan"
}
```

### Success Response `200`

```json
{
  "message": "QC request submitted",
  "request_id": "QC_REQ_001"
}
```

---

## DELETE /api/v1/qc-request

Cancel/delete a QC request.

**Bundle constant:** `DELETE_REQUEST_QC_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "request_id": "QC_REQ_001"
}
```

---

## POST /api/v1/user/delivery/check/qc-otp

Verify OTP for QC-gated delivery confirmation.

**Bundle constant:** `POST_QC_OTP_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "run_order_id": 12345,
  "otp": "4321",
  "consignment_id": "DTK0000001"
}
```

### Success Response `200`

```json
{
  "message": "Delivery confirmed with OTP",
  "status": 2
}
```

---

## POST /api/v1/cdn/upload

Upload a file (proof image, profile photo, QC evidence) to the CDN.

**Bundle constant:** `POST_QC_UPLOAD_FILE_URL`  
**Auth required:** Yes  
**Content-Type:** `multipart/form-data`

> CDN base: `https://cdn.pathao.com`

### Request Body (multipart/form-data)

| Field | Type | Description |
|-------|------|-------------|
| `file` | File | Image file (JPEG/PNG) |
| `type` | string | `proof`, `profile`, or `qc` |
| `consignment_id` | string | _(optional)_ Related consignment |

### Success Response `200`

```json
{
  "url": "https://cdn.pathao.com/uploads/proof/DTK0000001_proof.jpg",
  "key": "uploads/proof/DTK0000001_proof.jpg"
}
```
