# Push Notifications & Real-time Broadcast

**Base URL:** `https://api-hermes.pathao.com/talaria`

---

## POST /api/v1/user/push/subscribe

Register the agent's device for push notifications (FCM).

**Bundle constant:** `PUSH_SUBSCRIBE_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "fcm_token": "APA91bH...",
  "device_type": "android",
  "device_id": "DEVICE_UUID"
}
```

### Success Response `200`

```json
{ "message": "Push subscription registered" }
```

---

## POST /api/v1/user/push/unsubscribe

Unregister the agent's device from push notifications (on logout).

**Bundle constant:** `PUSH_UNSUBSCRIBE_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "fcm_token": "APA91bH...",
  "device_id": "DEVICE_UUID"
}
```

---

## POST /api/v1/broadcast/user-auth/agent

Get a Pusher/Soketi connection authentication token for the agent's personal channel.

**Bundle constant:** `GET_CONNECTION_TOKEN_URL`  
**Auth required:** Yes

> Used to authenticate the WebSocket connection for real-time events (FCM + Notifee).

### Request Body (JSON)

```json
{
  "socket_id": "1234.5678",
  "channel_name": "private-agent-123"
}
```

### Success Response `200`

```json
{
  "auth": "app_key:signature"
}
```

---

## POST /api/v1/broadcast/auth/agent

Get a channel subscription token for a specific broadcast channel.

**Bundle constant:** `GET_CHANNEL_SUBSCRIPTION_TOKEN_URL`  
**Auth required:** Yes

> Used to subscribe to presence or private channels for delivery notifications.

### Request Body (JSON)

```json
{
  "socket_id": "1234.5678",
  "channel_name": "presence-delivery-run-42"
}
```

### Success Response `200`

```json
{
  "auth": "app_key:signature",
  "channel_data": "{\"user_id\":\"123\",\"user_info\":{}}"
}
```
