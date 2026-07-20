# Pathao Agent — API Endpoints Reference

> Reverse-engineered from `com.pathao.agent` v7.1.2 (APK decompiled via apktool + jadx + hermes-dec).
> Source bundle: `hermes/index.android.js` (~30 MB decompiled React Native JS).

---

## Base URL

```
https://api-hermes.pathao.com/talaria
```

All `/api/v1/*` paths are appended to this base.  
Full example: `https://api-hermes.pathao.com/talaria/api/v1/issue-token`

## Required Headers (on every request)

| Header        | Value           |
|---------------|-----------------|
| `App-Version` | `7.1.2`         |
| `X-Language`  | `en`            |
| `X-Country-Id`| `1`             |
| `Authorization`| `Bearer <token>` _(except auth endpoints)_ |

---

## Files in this folder

| File | Description |
|------|-------------|
| `01_auth.md` | Authentication & session management |
| `02_user_profile.md` | User profile, password, account |
| `03_delivery.md` | Delivery assignment, check-in, status updates |
| `04_pickup.md` | Pickup operations, slot pickup, merchant packages |
| `05_return.md` | Return delivery operations |
| `06_sorting_runs.md` | Sorting, run routing, transfers, VDA |
| `07_c2c.md` | Customer-to-Customer (C2C) pickup |
| `08_cash_wallet.md` | Cash, wallet, earnings, XDP payments |
| `09_attendance.md` | Agent attendance / shift entry & exit |
| `10_location_ping.md` | GPS location pings & config |
| `11_messaging.md` | Consignment-wise and all-delivery messages |
| `12_push_broadcast.md` | Push notification & real-time broadcast |
| `13_qc_cdn.md` | QC (Quality Control) requests & file upload |
| `14_misc.md` | Dashboard, merchant search, hold/return reasons |
| `ALL_ENDPOINTS.md` | Complete flat list (64 endpoints) |
| `postman_collection.json` | Importable Postman collection |
