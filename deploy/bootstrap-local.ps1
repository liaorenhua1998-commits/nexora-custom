$ErrorActionPreference = "Stop"

$baseUrl = if ($env:NEXORA_BASE_URL) { $env:NEXORA_BASE_URL.TrimEnd("/") } else { "http://127.0.0.1:8080" }
$adminEmail = if ($env:NEXORA_ADMIN_EMAIL) { $env:NEXORA_ADMIN_EMAIL } else { "admin@nexora.local" }
$adminPassword = if ($env:NEXORA_ADMIN_PASSWORD) { $env:NEXORA_ADMIN_PASSWORD } else { "NexoraAdmin_20260511!" }

$groupName = "nexora-openai"
$accountName = "mock-openai-upstream"
$channelName = "mock-openai-channel"
$mockBaseUrl = if ($env:NEXORA_MOCK_OPENAI_BASE_URL) { $env:NEXORA_MOCK_OPENAI_BASE_URL } else { "http://mock-openai:8090" }
$mockApiKey = if ($env:NEXORA_MOCK_OPENAI_API_KEY) { $env:NEXORA_MOCK_OPENAI_API_KEY } else { "mock-upstream-secret" }

function Invoke-NexoraJson {
  param(
    [string]$Method,
    [string]$Url,
    [object]$Body = $null,
    [hashtable]$Headers = @{}
  )

  $params = @{
    Method      = $Method
    Uri         = $Url
    Headers     = $Headers
    ContentType = "application/json"
  }

  if ($null -ne $Body) {
    $params.Body = ($Body | ConvertTo-Json -Depth 12)
  }

  Invoke-RestMethod @params
}

$login = Invoke-NexoraJson -Method POST -Url "$baseUrl/api/v1/auth/login" -Body @{
  email    = $adminEmail
  password = $adminPassword
}

$headers = @{ Authorization = "Bearer $($login.data.access_token)" }

$settings = Invoke-RestMethod -Uri "$baseUrl/api/v1/admin/settings" -Headers $headers
$settingsPayload = $settings.data
$settingsPayload.default_balance = 50
$settingsPayload.available_channels_enabled = $true
$settingsPayload.payment_enabled_types = @()
$null = Invoke-NexoraJson -Method PUT -Url "$baseUrl/api/v1/admin/settings" -Headers $headers -Body $settingsPayload

$groupsResp = Invoke-RestMethod -Uri "$baseUrl/api/v1/admin/groups?page=1&page_size=200" -Headers $headers
$group = $groupsResp.data.items | Where-Object { $_.name -eq $groupName } | Select-Object -First 1
if (-not $group) {
  $group = (Invoke-NexoraJson -Method POST -Url "$baseUrl/api/v1/admin/groups" -Headers $headers -Body @{
    name              = $groupName
    description       = "Nexora local OpenAI relay group"
    platform          = "openai"
    rate_multiplier   = 1
    is_exclusive      = $false
    subscription_type = "standard"
    rpm_limit         = 0
  }).data
}

$accountsResp = Invoke-RestMethod -Uri "$baseUrl/api/v1/admin/accounts?page=1&page_size=200" -Headers $headers
$account = $accountsResp.data.items | Where-Object { $_.name -eq $accountName } | Select-Object -First 1
$accountPayload = @{
  name         = $accountName
  notes        = "Nexora local mock upstream for full relay verification"
  platform     = "openai"
  type         = "apikey"
  credentials  = @{
    base_url = $mockBaseUrl
    api_key  = $mockApiKey
  }
  extra        = @{}
  concurrency  = 10
  priority     = 1
  group_ids    = @($group.id)
}
if ($account) {
  $account = (Invoke-NexoraJson -Method PUT -Url "$baseUrl/api/v1/admin/accounts/$($account.id)" -Headers $headers -Body $accountPayload).data
} else {
  $account = (Invoke-NexoraJson -Method POST -Url "$baseUrl/api/v1/admin/accounts" -Headers $headers -Body $accountPayload).data
}

$channelsResp = Invoke-RestMethod -Uri "$baseUrl/api/v1/admin/channels?page=1&page_size=200" -Headers $headers
$channel = $channelsResp.data.items | Where-Object { $_.name -eq $channelName } | Select-Object -First 1
$channelPayload = @{
  name                  = $channelName
  description           = "Nexora local OpenAI compatibility channel"
  group_ids             = @($group.id)
  model_pricing         = @()
  model_mapping         = @{}
  billing_model_source  = "channel_mapped"
  restrict_models       = $false
  features              = ""
  features_config       = @{}
}
if ($channel) {
  $channel = (Invoke-NexoraJson -Method PUT -Url "$baseUrl/api/v1/admin/channels/$($channel.id)" -Headers $headers -Body $channelPayload).data
} else {
  $channel = (Invoke-NexoraJson -Method POST -Url "$baseUrl/api/v1/admin/channels" -Headers $headers -Body $channelPayload).data
}

[pscustomobject]@{
  base_url = $baseUrl
  group    = @{ id = $group.id; name = $group.name }
  account  = @{ id = $account.id; name = $account.name }
  channel  = @{ id = $channel.id; name = $channel.name }
} | ConvertTo-Json -Depth 6
