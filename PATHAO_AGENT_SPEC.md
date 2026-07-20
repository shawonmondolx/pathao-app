# Pathao Agent App Specification (Decompiled v7.1.2)

This specification document outlines the architecture, data models, screen flows, and API integrations of the official Pathao Agent application. It is reverse-engineered from the decompiled React Native bundle (`com.pathao.agent`) and serves as the source of truth for the Flutter replication.

---

## 1. Authentication & Security

### Login
- **Endpoint**: `/talaria/api/v1/issue-token`
- **Method**: `POST`
- **Headers**:
  ```http
  App-Version: 7.1.2
  X-Language: en
  X-Country-Id: 1
  Accept: application/json
  Content-Type: application/json
  ```
- **Request Body**:
  ```json
  {
    "username": "<PHONE_NUMBER>",
    "password": "<PASSWORD>",
    "client_id": "1",
    "client_secret": "3OTpihlWPazZNDw9CpKwzXombbGa9wmO1Ms4O9Ne",
    "grant_type": "password"
  }
  ```
- **Response Body (200 OK)**:
  ```json
  {
    "message": "logged in successfully",
    "type": "success",
    "code": 200,
    "data": {
      "expires_in": 86400,
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6Ik...",
      "token_type": "Bearer"
    }
  }
  ```

### Refresh Token
- **Endpoint**: `/talaria/api/v1/issue-token`
- **Method**: `POST`
- **Request Body**:
  ```json
  {
    "grant_type": "refresh_token",
    "refresh_token": "<REFRESH_TOKEN>",
    "client_id": "1"
  }
  ```

---

## 2. Core Modules & Endpoints

### A. Dashboard / Summary
- **Endpoint**: `/talaria/api/v1/dashboard`
- **Method**: `GET`
- **Response Body**:
  ```json
  {
    "message": "Summary",
    "type": "success",
    "code": 200,
    "data": {
      "run_ids": [11953867],
      "cash_collected": 23685,
      "cash_collectable_total": 65946,
      "delivery_total": 59,
      "delivery_completed": 20,
      "price_change": 0,
      "returned": 4,
      "partial_delivery": 1,
      "on_hold": 0,
      "pending": 31,
      "drto": 3,
      "exchange": 0,
      "is_run_closed": false,
      "has_delivery": true,
      "has_pickup": false
    }
  }
  ```

### B. Delivery List
- **Endpoint**: `/talaria/api/v1/user/delivery`
- **Method**: `GET`
- **Response Body**:
  ```json
  {
    "message": "orders",
    "type": "success",
    "code": 200,
    "data": {
      "collection": {
        "total_collectable": 65946,
        "total_collected": 23685
      },
      "orders": {
        "data": [
          {
            "consignment_id": "DA1707269WRDVU",
            "run_routes_order_id": 443828899,
            "order_id": 203099373,
            "run_route_id": 11953867,
            "recipient_name": "জুলফিকার",
            "recipient_phone": "01731203376",
            "recipient_address": "ময়মনসিংহ ভালুকা স্কয়ার মাস্টার বাড়ি...",
            "merchant_name": "Ash-Shifa Organic Care",
            "merchant_phone": "01335194282",
            "amount": 890,
            "status": "PENDING",
            "can_mark": true,
            "is_photo_proof_needed": false,
            "failed_reason": null,
            "payment_link": "https://ptho.app/i2aY3v"
          }
        ]
      }
    }
  }
  ```

---

## 3. Post Actions & Workflows

### A. Delivery Confirmation (Delivered)
When marking an order as delivered, the agent sends an OTP to the customer and submits the verification.
- **Endpoint**: `/talaria/api/v1/user/delivery/check`
- **Method**: `POST`
- **Content-Type**: `multipart/form-data` (or JSON if no document/proof attached)
- **Parameters**:
  - `run_order_id` (Integer): The consignment's `run_routes_order_id`
  - `status` (Integer): `2` (representing DELIVERED)
  - `collected_amount` (Double): The money received
  - `otp_type` (String): `"customer"`
  - `otp` (String): The 4-digit code entered by the agent
  - `proceed_method` (String): `"OTP"`
  - `delivery_slip` (File, Optional): Base64 or binary proof photo

### B. Mark On Hold (Hold)
Puts an order on hold due to customer unavailability, rescheduling, etc.
- **Endpoint**: `/talaria/api/v1/user/delivery`
- **Method**: `POST`
- **Content-Type**: `application/json`
- **Request Body**:
  ```json
  {
    "run_order_id": <run_routes_order_id>,
    "status": 3,
    "otp_type": "customer",
    "reason": "<HOLD_REASON_TEXT>"
  }
  ```

### C. Initiate Return (Returned)
Return execution requires two phases:
1. **Submit Reason**:
   - **Endpoint**: `/talaria/api/v1/user/delivery`
   - **Method**: `POST`
   - **Request Body**:
     ```json
     {
       "run_order_id": <run_routes_order_id>,
       "status": 4,
       "reason": "<RETURN_REASON_TEXT>",
       "otp_type": "customer"
     }
     ```
2. **Confirm Return (with OTP verification)**:
   - **Endpoint**: `/talaria/api/v1/user/delivery/check`
   - **Method**: `POST`
   - **Request Body**:
     ```json
     {
       "run_order_id": <run_routes_order_id>,
       "status": 4,
       "reason": "<RETURN_REASON_TEXT>",
       "otp_type": "merchant",
       "otp": "<OTP_CODE>",
       "proceed_method": "OTP"
     }
     ```

### D. Resend OTP SMS
Resends the verification code via SMS to either the recipient or the merchant store.
- **Endpoint**: `/talaria/api/v1/user/delivery/sms-resend`
- **Method**: `POST`
- **Request Body**:
  ```json
  {
    "run_order_id": <run_routes_order_id>,
    "status": <2_or_4>,
    "otp_type": "<customer_or_merchant>",
    "reason": "<REASON_IF_ANY>",
    "collected_amount": <AMOUNT_IF_ANY>
  }
  ```

---

## 4. Flutter Implementation Strategy
We align the Riverpod state notifier to execute these payloads exactly. All parameters are parsed from `Consignment` object dynamically:
- `runOrderId` -> `run_routes_order_id`
- `status` -> `2` for Delivered, `3` for Hold, `4` for Return
- Header token injection handled automatically by `DioClient` interceptor.
