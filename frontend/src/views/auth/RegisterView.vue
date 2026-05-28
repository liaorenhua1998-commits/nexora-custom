<template>
  <AuthLayout>
    <div class="space-y-6">
      <div class="space-y-2 text-center">
        <h2 class="text-3xl font-black text-slate-900">{{ t('auth.signUp') }}</h2>
        <p class="text-sm text-slate-500">
          {{ t('auth.signUpToStart', { siteName: settings?.site_name || appStore.siteName || 'Nexora' }) }}
        </p>
      </div>

      <div class="grid grid-cols-2 gap-2 rounded-2xl bg-slate-100 p-1">
        <RouterLink
          to="/login"
          class="flex min-h-11 items-center justify-center rounded-xl px-4 py-3 text-center text-sm font-semibold text-slate-500 transition hover:text-slate-900"
        >
          {{ t('common.login') }}
        </RouterLink>
        <RouterLink
          to="/register"
          class="flex min-h-11 items-center justify-center rounded-xl bg-white px-4 py-3 text-center text-sm font-semibold text-slate-900 shadow-sm"
        >
          {{ t('auth.signUp') }}
        </RouterLink>
      </div>

      <div v-if="hasAnyOAuthProvider" class="space-y-4">
        <EmailOAuthButtons
          :disabled="submitting"
          :github-enabled="settings?.github_oauth_enabled"
          :google-enabled="settings?.google_oauth_enabled"
          :show-divider="false"
        />
        <LinuxDoOAuthSection v-if="settings?.linuxdo_oauth_enabled" :disabled="submitting" :show-divider="false" />
        <WechatOAuthSection v-if="settings?.wechat_oauth_enabled" :disabled="submitting" :show-divider="false" />
        <OidcOAuthSection
          v-if="settings?.oidc_oauth_enabled"
          :disabled="submitting"
          :provider-name="settings?.oidc_oauth_provider_name"
          :show-divider="false"
        />
        <AuthOAuthDivider :label="t('auth.oauthOrContinue')" />
      </div>

      <div
        v-if="settings && settings.registration_enabled === false"
        class="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-700"
      >
        {{ t('auth.registrationDisabled') }}
      </div>

      <form v-else class="space-y-4" @submit.prevent="submit">
        <Input
          v-model="form.email"
          :label="t('common.email')"
          :placeholder="t('common.email')"
          autocomplete="email"
          :error="errors.email"
        />

        <div v-if="emailVerifyEnabled" class="grid gap-3 sm:grid-cols-[minmax(0,1fr)_152px] sm:items-end">
          <Input
            v-model="form.verifyCode"
            :label="t('auth.verificationCode')"
            :placeholder="t('auth.verificationCode')"
            autocomplete="one-time-code"
            :error="errors.verifyCode"
          />
          <div class="sm:pb-[0.375rem]">
            <button
              type="button"
              class="btn btn-secondary h-[4.8rem] w-full"
              :disabled="sendingCode || countdown > 0 || !form.email.trim() || (turnstileEnabled && !turnstileToken)"
              @click="sendCode"
            >
              {{ countdown > 0 ? `${countdown}s` : (sendingCode ? t('common.sending') : t('auth.sendCode')) }}
            </button>
          </div>
        </div>

        <Input
          v-model="form.password"
          type="password"
          :label="t('common.password')"
          :placeholder="t('common.password')"
          autocomplete="new-password"
          :error="errors.password"
        />

        <Input
          v-if="promoEnabled"
          v-model="form.promoCode"
          :label="t('auth.promoCodeLabel')"
          :placeholder="t('auth.promoCodePlaceholder')"
          :error="errors.promoCode"
        />

        <Input
          v-if="invitationEnabled"
          v-model="form.invitationCode"
          :label="t('auth.invitationCodeLabel')"
          :placeholder="t('auth.invitationCodePlaceholder')"
          :error="errors.invitationCode"
        />

        <div v-if="turnstileEnabled" class="space-y-2">
          <label class="input-label">Security Verification</label>
          <TurnstileWidget
            ref="turnstileRef"
            :site-key="turnstileSiteKey"
            @verify="onTurnstileVerify"
            @expire="onTurnstileExpire"
            @error="onTurnstileError"
          />
          <p v-if="errors.turnstile" class="text-sm text-red-500">{{ errors.turnstile }}</p>
        </div>

        <p v-if="errorMessage" class="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600">
          {{ errorMessage }}
        </p>

        <button type="submit" class="btn btn-primary w-full" :disabled="submitting">
          {{ submitting ? t('common.processing') : t('auth.createAccount') }}
        </button>
      </form>
    </div>
  </AuthLayout>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AuthLayout from '@/components/layout/AuthLayout.vue'
import Input from '@/components/common/Input.vue'
import TurnstileWidget from '@/components/TurnstileWidget.vue'
import AuthOAuthDivider from '@/components/auth/AuthOAuthDivider.vue'
import EmailOAuthButtons from '@/components/auth/EmailOAuthButtons.vue'
import LinuxDoOAuthSection from '@/components/auth/LinuxDoOAuthSection.vue'
import WechatOAuthSection from '@/components/auth/WechatOAuthSection.vue'
import OidcOAuthSection from '@/components/auth/OidcOAuthSection.vue'
import { sendVerifyCode } from '@/api/auth'
import { useAppStore, useAuthStore } from '@/stores'

const router = useRouter()
const route = useRoute()
const { t } = useI18n()
const appStore = useAppStore()
const authStore = useAuthStore()

const form = reactive({
  email: '',
  verifyCode: '',
  password: '',
  promoCode: '',
  invitationCode: ''
})

const errors = reactive({
  email: '',
  verifyCode: '',
  password: '',
  promoCode: '',
  invitationCode: '',
  turnstile: ''
})

const errorMessage = ref('')
const sendingCode = ref(false)
const submitting = ref(false)
const countdown = ref(0)
const turnstileToken = ref('')
const turnstileSiteKey = ref('')
const turnstileRef = ref<InstanceType<typeof TurnstileWidget> | null>(null)
let countdownTimer: ReturnType<typeof setInterval> | null = null

const settings = computed(() => appStore.cachedPublicSettings)
const hasAnyOAuthProvider = computed(
  () =>
    Boolean(settings.value?.github_oauth_enabled) ||
    Boolean(settings.value?.google_oauth_enabled) ||
    Boolean(settings.value?.linuxdo_oauth_enabled) ||
    Boolean(settings.value?.wechat_oauth_enabled) ||
    Boolean(settings.value?.oidc_oauth_enabled)
)
const turnstileEnabled = computed(
  () => settings.value?.turnstile_enabled === true && Boolean(turnstileSiteKey.value)
)
const emailVerifyEnabled = computed(() => settings.value?.email_verify_enabled === true)
const promoEnabled = computed(() => settings.value?.promo_code_enabled === true)
const invitationEnabled = computed(() => settings.value?.invitation_code_enabled === true)

function getRequestErrorMessage(error: unknown, fallback: string): string {
  const maybeError = error as {
    response?: { data?: { detail?: string; message?: string } }
    message?: string
  }
  return (
    maybeError?.response?.data?.detail ||
    maybeError?.response?.data?.message ||
    maybeError?.message ||
    fallback
  )
}

function resetErrors(): void {
  errors.email = ''
  errors.verifyCode = ''
  errors.password = ''
  errors.promoCode = ''
  errors.invitationCode = ''
  errors.turnstile = ''
  errorMessage.value = ''
}

function validate(): boolean {
  resetErrors()
  let valid = true

  if (!form.email.trim()) {
    errors.email = t('common.email')
    valid = false
  }
  if (emailVerifyEnabled.value && !form.verifyCode.trim()) {
    errors.verifyCode = t('auth.verifyCode')
    valid = false
  }
  if (!form.password) {
    errors.password = t('common.password')
    valid = false
  }
  if (turnstileEnabled.value && !turnstileToken.value) {
    errors.turnstile = t('auth.turnstileFailed')
    valid = false
  }

  return valid
}

function startCountdown(seconds: number): void {
  countdown.value = seconds
  if (countdownTimer) {
    clearInterval(countdownTimer)
  }
  countdownTimer = setInterval(() => {
    if (countdown.value <= 1) {
      countdown.value = 0
      if (countdownTimer) {
        clearInterval(countdownTimer)
        countdownTimer = null
      }
      return
    }
    countdown.value -= 1
  }, 1000)
}

async function loadSettings(): Promise<void> {
  try {
    const publicSettings = await appStore.fetchPublicSettings(true)
    turnstileSiteKey.value = publicSettings?.turnstile_site_key || ''
  } catch (error) {
    console.error('Failed to load public settings:', error)
  }
}

async function sendCode(): Promise<void> {
  resetErrors()
  if (!form.email.trim()) {
    errors.email = t('common.email')
    return
  }
  if (turnstileEnabled.value && !turnstileToken.value) {
    errors.turnstile = t('auth.turnstileFailed')
    return
  }

  sendingCode.value = true

  try {
    const result = await sendVerifyCode({
      email: form.email.trim(),
      turnstile_token: turnstileEnabled.value ? turnstileToken.value : undefined
    })
    appStore.showSuccess(result.message || t('auth.sendCodeSuccess'))
    startCountdown(result.countdown || 60)
    if (turnstileEnabled.value) {
      turnstileToken.value = ''
      turnstileRef.value?.reset()
    }
  } catch (error) {
    const message = getRequestErrorMessage(error, t('auth.sendCodeFailed'))
    errorMessage.value = message
    appStore.showError(message)
  } finally {
    sendingCode.value = false
  }
}

async function submit(): Promise<void> {
  if (!validate()) {
    return
  }

  submitting.value = true
  resetErrors()

  try {
    await authStore.register({
      email: form.email.trim(),
      password: form.password,
      verify_code: emailVerifyEnabled.value ? form.verifyCode.trim() : undefined,
      turnstile_token: turnstileEnabled.value ? turnstileToken.value : undefined,
      promo_code: promoEnabled.value ? form.promoCode.trim() || undefined : undefined,
      invitation_code: invitationEnabled.value ? form.invitationCode.trim() || undefined : undefined,
      aff_code: (route.query.aff_code as string) || (route.query.aff as string) || undefined
    })
    appStore.showSuccess(t('auth.registerSuccess'))
    await router.push((route.query.redirect as string) || '/dashboard')
  } catch (error) {
    const message = getRequestErrorMessage(error, t('auth.registerFailed'))
    errorMessage.value = message
    appStore.showError(message)
    if (turnstileEnabled.value) {
      turnstileToken.value = ''
      turnstileRef.value?.reset()
    }
  } finally {
    submitting.value = false
  }
}

function onTurnstileVerify(token: string): void {
  turnstileToken.value = token
  errors.turnstile = ''
}

function onTurnstileExpire(): void {
  turnstileToken.value = ''
  errors.turnstile = t('auth.turnstileExpired')
}

function onTurnstileError(): void {
  turnstileToken.value = ''
  errors.turnstile = t('auth.turnstileFailed')
}

onMounted(async () => {
  await loadSettings()
})

onBeforeUnmount(() => {
  if (countdownTimer) {
    clearInterval(countdownTimer)
  }
})
</script>
