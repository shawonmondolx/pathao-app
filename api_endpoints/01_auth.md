# Authentication & Session Management

**Base URL:** `https://api-hermes.pathao.com/talaria`  
**Constant name prefix used in bundle:** `TOKEN_URL`, `LOGOUT_URL`, `RESET_PASSWORD_URL`

---

## POST /api/v1/issue-token

Obtain an OAuth2-style bearer token (password grant).

**Bundle constant:** `TOKEN_URL`  
**Auth required:** No

### Request Body (JSON)

```json
{
  "username": "01777884223",
  "password": "YourPassword",
  "client_id": "1",
  "client_secret": "<secret>",
  "grant_type": "password",
  "scope": "*"
}
```

### Headers

```
App-Version: 7.1.2
X-Language: en
X-Country-Id: 1
```

### Success Response `200`

```json
{
  "data": {
    "token": "eyJ...",
    "refresh_token": "...",
    "expires_in": 86400
  }
}
```

---

## POST /api/v1/logout

Invalidate the current token.

**Bundle constant:** `LOGOUT_URL`  
**Auth required:** Yes (Bearer token)

### Request Body

_Empty or `{}`_

### Success Response `200`

```json
{ "message": "Logged out successfully" }
```

---

## POST /api/v1/user/reset-password

Change the agent's password.

**Bundle constant:** `RESET_PASSWORD_URL`  
**Auth required:** Yes

### Request Body (JSON)

```json
{
  "old_password": "current_password",
  "new_password": "new_password",
  "new_password_confirmation": "new_password"
}
```

### Success Response `200`

```json
{ "message": "Password reset successfully" }
```
