# ADMIN_PAYMENT_INTEGRATION_API

> Single-file bilingual documentation (Chinese + English)

---

## 中文

### 目标

本文档用于对接外部支付系统与 Nexora 的 Admin API，覆盖：

- 支付成功后的充值
- 用户信息查询
- 管理员手动余额修正
- 购买页参数透传

### 基础地址

- 生产环境：`https://<your-domain>`
- 测试环境：`http://<your-server-ip>:8084`

### 认证

推荐请求头：

- `x-api-key: admin-<64hex>`
- `Content-Type: application/json`
- `Idempotency-Key`（幂等接口必带）

说明：管理员 JWT 也能访问 admin 路由，但服务间调用建议使用 Admin API Key。

### 1) 创建并兑换充值码

`POST /api/v1/admin/redeem-codes/create-and-redeem`

用途：原子完成“创建充值码并直接给指定用户充值”。

请求体示例：

```json
{
  "code": "s2p_cm1234567890",
  "type": "balance",
  "value": 100.0,
  "user_id": 123,
  "notes": "external payment order: cm1234567890"
}
```

幂等行为：

- 相同 `code` 且相同 `used_by`：返回 `200`
- 相同 `code` 但不同 `used_by`：返回 `409`
- 缺少 `Idempotency-Key`：返回 `400`，错误码 `IDEMPOTENCY_KEY_REQUIRED`

```bash
curl -X POST "${BASE}/api/v1/admin/redeem-codes/create-and-redeem" \
  -H "x-api-key: ${KEY}" \
  -H "Idempotency-Key: pay-cm1234567890-success" \
  -H "Content-Type: application/json" \
  -d '{
    "code":"s2p_cm1234567890",
    "type":"balance",
    "value":100.00,
    "user_id":123,
    "notes":"external payment order: cm1234567890"
  }'
```

### 2) 查询用户

`GET /api/v1/admin/users/:id`

```bash
curl -s "${BASE}/api/v1/admin/users/123" \
  -H "x-api-key: ${KEY}"
```

### 3) 手动余额调整

`POST /api/v1/admin/users/:id/balance`

用途：人工补偿、加款、扣减，支持 `set` / `add` / `subtract`。

```json
{
  "balance": 100.0,
  "operation": "subtract",
  "notes": "manual correction"
}
```

```bash
curl -X POST "${BASE}/api/v1/admin/users/123/balance" \
  -H "x-api-key: ${KEY}" \
  -H "Idempotency-Key: balance-subtract-cm1234567890" \
  -H "Content-Type: application/json" \
  -d '{
    "balance":100.00,
    "operation":"subtract",
    "notes":"manual correction"
  }'
```

### 4) 购买页参数透传

当 Nexora 打开 `purchase_subscription_url` 或用户自定义支付页面 iframe URL 时，会自动追加：

- `user_id`
- `token`
- `theme`：`light` / `dark`
- `lang`：例如 `zh` / `en`
- `ui_mode`：固定为 `embedded`

示例：

```text
https://pay.example.com/pay?user_id=123&token=<jwt>&theme=light&lang=zh&ui_mode=embedded
```

### 5) 失败处理建议

- 支付成功与充值成功分状态存储
- 回调验签成功后先标记“支付成功”
- 充值失败允许后续重试
- 重试时保持相同业务单号，使用新的 `Idempotency-Key`

### 6) `doc_url` 建议

- 查看：`./docs/ADMIN_PAYMENT_INTEGRATION_API.md`
- 下载：`./docs/ADMIN_PAYMENT_INTEGRATION_API.md`

---

## English

### Purpose
This document describes the minimal Nexora Admin API surface for external payment integrations, including:
- Recharge after payment success
- User lookup
- Manual balance correction
- Purchase page query parameter forwarding

### Base URL
- Production: `https://<your-domain>`
- Beta: `http://<your-server-ip>:8084`

### Authentication
Recommended headers:
- `x-api-key: admin-<64hex>`
- `Content-Type: application/json`
- `Idempotency-Key` for idempotent endpoints

Note: Admin JWT can also access admin routes, but Admin API Key is recommended for server-to-server integration.

### 1) Create and Redeem in one step
`POST /api/v1/admin/redeem-codes/create-and-redeem`

Use case: atomically create a redeem code and redeem it to a target user.

Headers:
- `x-api-key`
- `Idempotency-Key`

Request body:
```json
{
  "code": "s2p_cm1234567890",
  "type": "balance",
  "value": 100.0,
  "user_id": 123,
  "notes": "external payment order: cm1234567890"
}
```

Idempotency behavior:
- Same `code` and same `used_by`: `200`
- Same `code` but different `used_by`: `409`
- Missing `Idempotency-Key`: `400` (`IDEMPOTENCY_KEY_REQUIRED`)

curl example:
```bash
curl -X POST "${BASE}/api/v1/admin/redeem-codes/create-and-redeem" \
  -H "x-api-key: ${KEY}" \
  -H "Idempotency-Key: pay-cm1234567890-success" \
  -H "Content-Type: application/json" \
  -d '{
    "code":"s2p_cm1234567890",
    "type":"balance",
    "value":100.00,
    "user_id":123,
    "notes":"external payment order: cm1234567890"
  }'
```

### 2) Query User (optional pre-check)
`GET /api/v1/admin/users/:id`

```bash
curl -s "${BASE}/api/v1/admin/users/123" \
  -H "x-api-key: ${KEY}"
```

### 3) Balance Adjustment (existing API)
`POST /api/v1/admin/users/:id/balance`

Use case: manual correction with `set` / `add` / `subtract`.

Request body example (`subtract`):
```json
{
  "balance": 100.0,
  "operation": "subtract",
  "notes": "manual correction"
}
```

```bash
curl -X POST "${BASE}/api/v1/admin/users/123/balance" \
  -H "x-api-key: ${KEY}" \
  -H "Idempotency-Key: balance-subtract-cm1234567890" \
  -H "Content-Type: application/json" \
  -d '{
    "balance":100.00,
    "operation":"subtract",
    "notes":"manual correction"
  }'
```

### 4) Purchase / Custom Page URL query forwarding (iframe and new tab)
When Nexora opens `purchase_subscription_url` or a user-facing custom page iframe URL, it appends:
- `user_id`
- `token`
- `theme` (`light` / `dark`)
- `lang` (for example `zh` / `en`, used to pass the current UI language to the embedded page)
- `ui_mode` (fixed: `embedded`)

Example:
```text
https://pay.example.com/pay?user_id=123&token=<jwt>&theme=light&lang=zh&ui_mode=embedded
```

### 5) Failure handling recommendations
- Persist payment success and recharge success as separate states
- Mark payment as successful immediately after verified callback
- Allow retry for orders with payment success but recharge failure
- Keep the same `code` for retry, and use a new `Idempotency-Key`

### 6) Recommended `doc_url`
- View URL: `./docs/ADMIN_PAYMENT_INTEGRATION_API.md`
- Download URL: `./docs/ADMIN_PAYMENT_INTEGRATION_API.md`
