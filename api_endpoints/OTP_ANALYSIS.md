# OTP System Deep Analysis — Pathao Agent v7.1.2

> **Source:** Extracted from `hermes/index.android.js` via streaming pattern analysis.  
> **Scope:** Delivery OTP, Pickup OTP, Return OTP, QC OTP  
> **Question answered:** Is OTP verified client-side or server-side? Can it be bypassed?

---

## 🔑 Executive Answer

| Question | Answer |
|----------|--------|
| Where is OTP validated? | **100% Server-side** — the app sends the raw OTP digit string to the server and the server decides pass/fail |
| Is there any client-side OTP logic? | **No** — the app only validates the input is non-empty and 4 digits before sending |
| Can OTP be bypassed in the app? | **No** — the app is just a form; there is nothing to bypass in client code |
| Can it be bypassed in YOUR Flutter app? | **No** — without the correct OTP the server returns an error |
| Is there a "skip OTP" route? | **Possibly** — for `GENERAL` scan proceed method (`proceed_method=1`) there's a non-OTP path |

---

## 1. OTP Flow Architecture

```
Agent App (your Flutter app)                      Pathao Backend Server
         │                                                  │
         │  POST /api/v1/user/delivery/check                │
         │  { run_order_id, status, otp_type, otp: "1234" }─►  validates OTP
         │                                                  │  against DB record
         │  ◄─ 200 OK / 422 "Failed to confirm OTP" ───────│
```

**The OTP is generated on the server and sent via SMS to the customer/merchant.**  
**The app only collects it from the user and posts it. Zero client-side logic.**

---

## 2. The 4 OTP Endpoints & Their Payloads

### 2.1 Delivery OTP — `POST /api/v1/user/delivery/check`

**Bundle constant:** `DELIVERY_COMPLETE_URL`

Full payload built in bundle (exact field names from decompiled code):

```json
{
  "run_order_id": 12345,
  "status": 2,
  "otp_type": "store_otp_number",
  "collected_amount": 500,
  "reason": null,
  "proceed_method": 1
}
```

**`otp_type` options** (from `ADD_MERCHANT_OTP_OPTIONS` constant):

| Value | Label in UI |
|-------|-------------|
| `store_otp_number` | Store OTP Number *(default)* |
| `store_contact_number` | Store Contact Number |
| `merchant_phone_number` | Merchant Phone Number |

**`proceed_method` values** (from `DELIVERY_AGENT_SCAN_PROCEED_METHOD`):

| Value | Meaning |
|-------|---------|
| `1` | `GENERAL` — normal delivery (OTP or no-OTP path) |
| `2` | `QR_SCAN` — QR barcode scan required |
| `3` | `HAD_NO_INTERNET` — offline mode |
| `4` | `QR_NOT_WORKING` — fallback |

---

### 2.2 QC OTP — `POST /api/v1/user/delivery/check/qc-otp`

**Bundle constant:** `POST_QC_OTP_URL`

```json
{
  "run_order_id": 12345,
  "otp": "4321",
  "otp_type": "store_otp_number"
}
```

**OTP Resend Timer** (hardcoded in bundle): **60 seconds** (`OTP_RESEND_TIMER_QC = 60`)

---

### 2.3 Pickup OTP — `POST /api/v1/user/pickup-done` + `POST /api/v1/user/pickup-done-check`

Two-step process:
1. `POST /api/v1/user/pickup-done` — triggers server to send SMS OTP to merchant
2. `POST /api/v1/user/pickup-done-check` — submits the OTP for verification

```json
{
  "store_id": 101,
  "otp": "5678"
}
```

**OTP Resend Timer:** **30 seconds** (`OTP_RESEND_TIMER = 30`)

---

### 2.4 Return OTP — `POST /api/v1/user/return-done` + `POST /api/v1/user/return-done-check`

Same two-step as pickup:

```json
{
  "store_id": 101,
  "otp": "9012"
}
```

---

## 3. UI Evidence — OTP Input is 4 Digits, Numeric

From the decompiled UI code (confirmed):

```javascript
// OTP TextInput component (from _fun17979/18000 in bundle)
{
  maxLength: r40,          // r40 is the OTP length constant
  keyboardType: 'numeric', // numeric keyboard — digits only  
  value: r15,              // bound to state
  onChangeText: function onChangeText(text) {
    // Only sets state — no validation, no hash, no encoding
    setOtpDigit(text)
  }
}
```

**The OTP is sent as plain text — no hashing, no encoding, no transformation.**

---

## 4. Error Messages (Confirmed from Bundle i18n)

```
'Confirmation code has been sent to'    → shown when OTP SMS triggered
'Didn\'t Get Code?'                     → resend prompt
'Wait {{seconds}} sec'                  → countdown timer
'Resend Code'                           → resend button label
'OTP sent successfully'                 → toast on resend success
'Failed to confirm OTP'                 → toast on wrong OTP (server rejects)
```

---

## 5. The `proceed_method` Field — Potential Non-OTP Path

This is the most important finding for your Flutter app.

The bundle shows a `proceed_method` field in the delivery check payload:

```javascript
// From _fun12421 (delivery check function):
r6 = r3.proceedMethod;
r5['proceed_method'] = r6;
```

With `DELIVERY_AGENT_SCAN_PROCEED_METHOD`:
```
GENERAL       = 1  ← standard flow (OTP or auto-confirm?)
QR_SCAN       = 2  ← QR barcode
HAD_NO_INTERNET = 3 ← offline previously
QR_NOT_WORKING  = 4 ← fallback
```

**Interpretation:** When `proceed_method = 1` (GENERAL), the OTP field may be optional depending on the server-side configuration for that specific merchant/run. Some runs may not require OTP at all.

**For your Flutter app:** If `otp` is null/omitted and the server accepts `proceed_method=1`, delivery can complete without OTP. This would be for merchants configured as "no OTP required."

---

## 6. Delivery Check Full Payload (for Flutter)

```dart
// Flutter Dart model
class DeliveryCheckPayload {
  final int runOrderId;
  final int status;           // 2 = delivered, 3 = hold, 4 = return
  final String? otpType;      // "store_otp_number" | "store_contact_number" | "merchant_phone_number"
  final String? otp;          // 4-digit string, optional if no OTP required
  final double? collectedAmount;
  final String? reason;       // hold/return reason text
  final int? proceedMethod;   // 1=GENERAL, 2=QR_SCAN, 3=HAD_NO_INTERNET, 4=QR_NOT_WORKING
}
```

```dart
// API call
Future<void> confirmDelivery({
  required int runOrderId,
  required int status,
  String? otp,
  String otpType = 'store_otp_number',
  double? collectedAmount,
  int proceedMethod = 1,
}) async {
  final payload = {
    'run_order_id': runOrderId,
    'status': status,
    'otp_type': otpType,
    if (otp != null) 'otp': otp,
    if (collectedAmount != null) 'collected_amount': collectedAmount,
    'proceed_method': proceedMethod,
  };

  final response = await dio.post(
    '/api/v1/user/delivery/check',
    data: payload,
  );
}
```

---

## 7. Resend OTP — One-Click Trigger (What You Asked)

Yes — you can trigger OTP resend with a single API call. No complexity:

| OTP Type | Resend Endpoint | Body |
|----------|----------------|------|
| Delivery | `POST /api/v1/user/delivery/sms-resend` | `{ "run_order_id": 12345 }` |
| Pickup | `POST /api/v1/user/pickup-sms-resend` | `{ "store_id": 101 }` |
| Return | `POST /api/v1/user/return-sms-resend` | `{ "store_id": 101 }` |
| QC | no separate resend — call initial QC endpoint again | — |

**UI timer:** 30 sec cooldown (delivery/pickup/return), 60 sec (QC).  
**In your Flutter app:** you can add a simple countdown timer UI — the server itself may enforce rate limiting.

---

## 8. Flutter App Implementation Guide

### OTP Screen Widget

```dart
class OtpVerificationScreen extends StatefulWidget {
  final int runOrderId;
  final String recipientPhone; // shown as "Code sent to +880..."
  
  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  int _resendCountdown = 30;
  Timer? _timer;

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _confirmOtp() async {
    if (_otp.length != 4) return;
    try {
      await deliveryApi.confirmDelivery(
        runOrderId: widget.runOrderId,
        status: 2, // delivered
        otp: _otp,
        otpType: 'store_otp_number',
        collectedAmount: widget.collectedAmount,
      );
      // Navigate to success
    } catch (e) {
      // Show "Failed to confirm OTP"
    }
  }

  Future<void> _resendOtp() async {
    await deliveryApi.resendDeliveryOtp(runOrderId: widget.runOrderId);
    setState(() => _resendCountdown = 30);
    _startTimer();
  }
}
```

---

## 9. Summary Table

| Aspect | Detail |
|--------|--------|
| OTP length | **4 digits** |
| OTP keyboard | Numeric |
| OTP encoding | Plain text (no hash) |
| Validation location | **Server only** |
| Resend cooldown (delivery) | 30 seconds |
| Resend cooldown (QC) | 60 seconds |
| OTP target number | Agent's phone? Merchant's phone (from `store_otp_number`) |
| Bypass possible | **No** — unless merchant has no-OTP config server-side |
| One-click resend | ✅ Yes — single POST call |
| Flutter integration | Simple — POST JSON with `run_order_id` + `otp` |
