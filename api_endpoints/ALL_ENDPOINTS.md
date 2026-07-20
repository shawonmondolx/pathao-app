# Pathao Agent — Complete API Endpoint List

> **App:** `com.pathao.agent` v7.1.2  
> **Base URL:** `https://api-hermes.pathao.com/talaria`  
> **OMS Base URL:** `https://api-hermes.pathao.com/api/agents/v1/oms`  
> **CDN Base URL:** `https://cdn.pathao.com`  
> **Source:** Reverse-engineered from Hermes JS bundle (`hermes/index.android.js`)  
> **Total endpoints:** 64

---

## HTTP Methods Legend

Methods determined from:
1. Bundle constant naming (`GET_*`, `POST_*`, `DELETE_*`, `DAILY_ATTENDANCE_SUBMIT_*`, etc.)
2. Test scripts in the project (`test_*.js`) confirming actual calls
3. REST semantics cross-referenced with the feature inventory

| Symbol | Method |
|--------|--------|
| `G` | GET |
| `P` | POST |
| `U` | PUT |
| `Pa` | PATCH |
| `D` | DELETE |

---

## Authentication

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `P` | `/api/v1/issue-token` | Login / obtain bearer token | `TOKEN_URL` |
| `P` | `/api/v1/logout` | Logout / invalidate token | `LOGOUT_URL` |
| `P` | `/api/v1/user/reset-password` | Change password | `RESET_PASSWORD_URL` |

---

## User Profile & Account

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `G` | `/api/v1/user` | Get agent profile | `PROFILE_URL` |
| `P` | `/api/v1/user/profile-image` | Upload profile picture | `UPLOAD_IMAGE_URL` |
| `P` | `/api/v1/user/profile-toggle` | Toggle hybrid profile mode | `HYBRID_AGENT_PROFILE_TOGGLE_URL` |
| `D` | `/api/v1/user/delete-account` | Request account deletion | `DELETE_ACCOUNT_URL` |
| `G` | `/api/v1/user/agent-ratings` | Get agent ratings | `AGENT_RATINGS_URL` |
| `G` | `/api/v1/user/agent-reviews` | Get agent reviews | `AGENT_REVIEWS_URL` |

---

## Dashboard

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `G` | `/api/v1/dashboard` | Dashboard summary stats | `DASHBOARD_URL` |

---

## Delivery Operations

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `G` | `/api/v1/user/delivery` | Get delivery assignment list | `DELIVERY_ASSIGNMENT_URL` |
| `P` | `/api/v1/user/delivery` | Update delivery status | `DELIVERY_UPDATE_URL` |
| `G` | `/api/v1/user/delivery/:consignmentId` | Get delivery details | `DELIVERY_DETAILS_URL` |
| `P` | `/api/v1/user/delivery/check` | Confirm delivery completion | `DELIVERY_COMPLETE_URL` |
| `P` | `/api/v1/user/delivery/check/qc-otp` | Verify QC OTP for delivery | `POST_QC_OTP_URL` |
| `P` | `/api/v1/user/delivery/sms-resend` | Resend delivery OTP SMS | `DELIVERY_SMS_RESEND_URL` |
| `P` | `/api/v1/user/sort-delivery` | Submit delivery sort order | `DELIVERY_LIST_SORT_URL` |
| `P` | `/api/v1/user/deliveries/:runRouteOrderId/approve` | Approve a delivery order | `DELIVERY_APPROVE_URL` |
| `G` | `/api/v1/delivery/hold-reasons` | Get hold reason list | `DELIVERY_HOLD_REASONS_URL` |
| `G` | `/api/v1/delivery/return-reasons` | Get return reason list | `DELIVERY_RETURN_REASONS_URL` |

---

## Pickup Operations

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `G` | `/api/v1/user/pickup` | Get pickup list | `PICKUP_LISTS_URL` |
| `P` | `/api/v1/user/pickup` | Update pickup (mark collected) | `MERCHANT_PACKAGE_UPDATE_URL` |
| `G` | `/api/v1/user/pickup/:id` | Get pickup task details | `NEXT_PICKUP_URL` |
| `G` | `/api/v1/user/pickup/:storeId` | Get merchant/store details | `MERCHANT_DETAILS_URL` |
| `P` | `/api/v1/user/pickup-done` | Submit pickup OTP | `MERCHANT_OTP` |
| `P` | `/api/v1/user/pickup-done-check` | Verify pickup OTP | `MERCHANT_OTP_CONFIRMATION` |
| `P` | `/api/v1/user/pickup-sms-resend` | Resend pickup OTP SMS | `MERCHANT_RESEND_OTP` |
| `P` | `/api/v1/user/slot-pickup/done` | Complete slot-based pickup | `MERCHANT_SLOT_PICKUP` |
| `P` | `/api/v1/user/slot-pickup/confirm` | Confirm slot-pickup OTP | `MERCHANT_SLOT_PICKUP_CONFIRMATION` |
| `P` | `/api/v1/user/slot-pickup/pick-again` | Re-attempt slot pickup | `PICKUP_AGAIN_URL` |
| `P` | `/api/v1/user/sort-pickup` | Submit pickup sort order | `PICKUP_LIST_SORT_URL` |

---

## Return Operations

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `G` | `/api/v1/user/return` | Get return delivery list | `RETURN_DELIVERY_LISTS_URL` |
| `P` | `/api/v1/user/return` | Update return status | `RETURN_ORDER_STATUS_UPDATE_URL` |
| `G` | `/api/v1/user/return/:storeId` | Get return details for a store | `NEXT_PICKUP_RETURN_URL` / `RETURN_ORDER_DETAILS` |
| `P` | `/api/v1/user/return-done` | Initiate return OTP | `RETURN_ORDER_OTP` |
| `P` | `/api/v1/user/return-done-check` | Verify return OTP | `RETURN_ORDER_OTP_CONFIRMATION` |
| `P` | `/api/v1/user/return-sms-resend` | Resend return OTP SMS | `RETURN_ORDER_RESEND_OTP` |
| `P` | `/api/v1/user/sort-return` | Submit return sort order | `RETURN_DELIVERY_SORT_URL` |

---

## Run Routing, Sorting & Transfers

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `G` | `/api/v1/user/runs/:runRouteId` | Get run/shift details | `DELIVERY_SHIFT_URL` |
| `G` | `/api/v1/user/transfers` | Get VDA delivery transfer list | `VDA_DELIVERY_LISTS_URL` |
| `G` | `/api/v1/user/transfers/:runRouteId` | Get VDA transfer status for run | `VDA_DELIVERY_STATUS_URL` |
| `G` | `/api/v1/user/pick-merchant-orders` | Get merchant orders for shift | `PICK_MERCHANT_ORDERS_URL` |
| `P` | `/api/v1/user/pick-merchant-orders-done` | Mark merchant order picking done | `PICK_MERCHANT_ORDERS_DONE_URL` |

---

## C2C (Customer-to-Customer) Pickup

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `G` | `/api/v1/user/c2c-pickup` | Get C2C pickup list | `C2C_PICKUP_LIST` |
| `P` | `/api/v1/user/c2c-pickup` | Confirm C2C pickup attempt | `C2C_PICKUP_CONFIRM_URL` |
| `G` | `/api/v1/user/c2c-pickup/:runRouteOrderId` | Get C2C pickup order details | `C2C_PICKUP_DETAILS` |
| `Pa` | `/dispatches/attempts/attemptId/status` | Update C2C dispatch attempt status | `UPDATE_C2C_PICKUP_ATTEMPT_URL` |

---

## Cash, Wallet & Payments

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `G` | `/api/v1/user/earnings` | Get agent earnings summary | `DELIVERY_EARNINS_URL` |
| `G` | `/api/v1/user/payment-info` | Get cash collection info | `PAYMENT_URL` |
| `P` | `/api/v1/user/payments/send-link` | Send payment link to customer | `SEND_PAYMENT_LINK_URL` |
| `G` | `/api/v1/wallet-list` | Get deposit wallet list | `WALLET_LIST_URL` |
| `G` | `/api/v1/wallet-list/:walletId/branch` | Get wallet branch details | `WALLET_BRANCH_LIST_URL` |
| `G` | `/api/v1/xdp-payment-info/:agentId` | Get XDP payment info | `XDP_PAYMENT_INFO_URL` |
| `P` | `/api/v1/xdp-payment-info/:agentId` | Confirm XDP payment | `XDP_PAYMENT_CONFIRM_URL` |
| `G` | `/api/v1/user/merchant-search` | Search merchants | `MERCHANT_SEARCH_URL` |

---

## Attendance & Shift

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `G` | `/api/v1/attendances/daily` | Get daily attendance | `DAILY_ATTENDANCE_URL` |
| `P` | `/api/v1/attendances/submit/entry` | Clock in (shift start) | `DAILY_ATTENDANCE_SUBMIT_URL` |
| `P` | `/api/v1/attendances/submit/exit` | Clock out (shift end) | `DAILY_ATTENDANCE_SUBMIT_EXIT_URL` |

---

## GPS Location & Pings

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `P` | `/api/v1/user/latlon` | Submit GPS coordinates | `POI_URL` |
| `P` | `/api/v1/pings` | Submit periodic ping | `SUBMIT_PINGS_URL` |
| `G` | `/api/v1/pings/config` | Get ping configuration | `GET_PINGS_CONFIG_URL` |

---

## Messaging

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `G` | `/api/v1/user/deliveries/messages` | Get all consignment messages | `GET_ALL_MESSAGES_URL` |
| `G` | `/api/v1/user/deliveries/:consignment_id/messages` | Get consignment message thread | `GET_CONSIGNMENT_WISE_MESSAGES_URL` |
| `P` | `/api/v1/user/deliveries/:consignment_id/messages` | Send message on consignment | `SEND_NEW_MESSAGE_URL` |
| `Pa` | `/api/v1/user/deliveries/:consignment_id/messages` | Mark messages as seen | `MARK_MESSAGE_SEEN_URL` |

---

## Push Notifications & Broadcast

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `P` | `/api/v1/user/push/subscribe` | Register FCM token | `PUSH_SUBSCRIBE_URL` |
| `P` | `/api/v1/user/push/unsubscribe` | Unregister FCM token | `PUSH_UNSUBSCRIBE_URL` |
| `P` | `/api/v1/broadcast/user-auth/agent` | Get WebSocket connection token | `GET_CONNECTION_TOKEN_URL` |
| `P` | `/api/v1/broadcast/auth/agent` | Get channel subscription token | `GET_CHANNEL_SUBSCRIPTION_TOKEN_URL` |

---

## QC & File Upload

| Method | Endpoint | Description | Bundle Constant |
|--------|----------|-------------|-----------------|
| `P` | `/api/v1/qc-request` | Submit QC proof request | `POST_REQUEST_QC_WITH_PROOF_URL` |
| `D` | `/api/v1/qc-request` | Cancel QC request | `DELETE_REQUEST_QC_URL` |
| `P` | `/api/v1/cdn/upload` | Upload file to CDN | `POST_QC_UPLOAD_FILE_URL` |

---

## Complete URL Summary (sorted)

```
BASE: https://api-hermes.pathao.com/talaria

GET    /api/v1/attendances/daily
POST   /api/v1/attendances/submit/entry
POST   /api/v1/attendances/submit/exit
POST   /api/v1/broadcast/auth/agent
POST   /api/v1/broadcast/user-auth/agent
POST   /api/v1/cdn/upload
GET    /api/v1/dashboard
GET    /api/v1/delivery/hold-reasons
GET    /api/v1/delivery/return-reasons
POST   /api/v1/issue-token
POST   /api/v1/logout
POST   /api/v1/pings
GET    /api/v1/pings/config
DELETE /api/v1/qc-request
POST   /api/v1/qc-request
GET    /api/v1/user
DELETE /api/v1/user/delete-account
GET    /api/v1/user/agent-ratings
GET    /api/v1/user/agent-reviews
GET    /api/v1/user/c2c-pickup
POST   /api/v1/user/c2c-pickup
GET    /api/v1/user/c2c-pickup/:runRouteOrderId
GET    /api/v1/user/deliveries/:consignment_id/messages
PATCH  /api/v1/user/deliveries/:consignment_id/messages
POST   /api/v1/user/deliveries/:consignment_id/messages
POST   /api/v1/user/deliveries/:runRouteOrderId/approve
GET    /api/v1/user/deliveries/messages
GET    /api/v1/user/delivery
POST   /api/v1/user/delivery
GET    /api/v1/user/delivery/:consignmentId
POST   /api/v1/user/delivery/check
POST   /api/v1/user/delivery/check/qc-otp
POST   /api/v1/user/delivery/sms-resend
GET    /api/v1/user/earnings
POST   /api/v1/user/latlon
GET    /api/v1/user/merchant-search
GET    /api/v1/user/payment-info
POST   /api/v1/user/payments/send-link
GET    /api/v1/user/pick-merchant-orders
POST   /api/v1/user/pick-merchant-orders-done
GET    /api/v1/user/pickup
POST   /api/v1/user/pickup
POST   /api/v1/user/pickup-done
POST   /api/v1/user/pickup-done-check
POST   /api/v1/user/pickup-sms-resend
GET    /api/v1/user/pickup/:id
GET    /api/v1/user/pickup/:storeId
POST   /api/v1/user/profile-image
POST   /api/v1/user/profile-toggle
POST   /api/v1/user/push/subscribe
POST   /api/v1/user/push/unsubscribe
POST   /api/v1/user/reset-password
GET    /api/v1/user/return
POST   /api/v1/user/return
POST   /api/v1/user/return-done
POST   /api/v1/user/return-done-check
POST   /api/v1/user/return-sms-resend
GET    /api/v1/user/return/:storeId
GET    /api/v1/user/runs/:runRouteId
POST   /api/v1/user/slot-pickup/confirm
POST   /api/v1/user/slot-pickup/done
POST   /api/v1/user/slot-pickup/pick-again
POST   /api/v1/user/sort-delivery
POST   /api/v1/user/sort-pickup
POST   /api/v1/user/sort-return
GET    /api/v1/user/transfers
GET    /api/v1/user/transfers/:runRouteId
GET    /api/v1/wallet-list
GET    /api/v1/wallet-list/:walletId/branch
GET    /api/v1/xdp-payment-info/:agentId
POST   /api/v1/xdp-payment-info/:agentId

BASE: https://api-hermes.pathao.com/api/agents/v1/oms

PATCH  /dispatches/attempts/attemptId/status
```
