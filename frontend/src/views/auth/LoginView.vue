<template>
  <AuthLayout>
    <div class="space-y-6">
      <div class="space-y-2 text-center">
        <h2 class="text-3xl font-black text-slate-900">{{ t('common.login') }}</h2>
        <p class="text-sm text-slate-500">{{ settings?.site_subtitle || t('auth.brandSubtitle') }}</p>
      </div>

      <div class="grid grid-cols-2 gap-2 rounded-2xl bg-slate-100 p-1">
        <RouterLink
          to="/login"
          class="flex min-h-11 items-center justify-center rounded-xl bg-white px-4 py-3 text-center text-sm font-semibold text-slate-900 shadow-sm"
        >
          {{ t('common.login') }}
        </RouterLink>
        <RouterLink
          to="/register"
          class="flex min-h-11 items-center justify-center rounded-xl px-4 py-3 text-center text-sm font-semibold text-slate-500 transition hover:text-slate-900"
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

      <form class="space-y-4" @submit.prevent="submit">
        <Input
          v-model="form.email"
          :label="t('common.email')"
          :placeholder="t('common.email')"
          autocomplete="email"
          :error="errors.email"
        />

        <Input
          v-model="form.password"
          type="password"
          :label="t('common.password')"
          :placeholder="t('common.password')"
          autocomplete="current-password"
          :error="errors.password"
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

        <div class="flex items-center justify-between gap-3 text-sm">
          <RouterLink to="/forgot-password" class="font-medium text-primary-600 hover:text-primary-500">
            {{ t('auth.forgotPasswordTitle') }}
          </RouterLink>
          <RouterLink to="/register" class="font-medium text-slate-500 hover:text-slate-900">
            {{ t('auth.createAccount') }}
          </RouterLink>
        </div>

        <p v-if="errorMessage" class="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600">
          {{ errorMessage }}
        </p>

        <button type="submit" class="btn btn-primary w-full" :disabled="submitting">
          {{ submitting ? t('common.processing') : t('common.login') }}
        </button>
      </form>
    </div>

    <TotpLoginModal
      v-if="totpTempToken"
      ref="totpModalRef"
      :temp-token="totpTempToken"
      :user-email-masked="totpUserEmailMasked"
      @verify="submitTotp"
      @cancel="resetTotp"
    />
  </AuthLayout>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AuthLayout from '@/components/layout/AuthLayout.vue'
import Input from '@/components/common/Input.vue'
import TurnstileWidget from '@/components/TurnstileWidget.vue'
import TotpLoginModal from '@/components/auth/TotpLoginModal.vue'
import AuthOAuthDivider from '@/components/auth/AuthOAuthDivider.vue'
import EmailOAuthButtons from '@/components/auth/EmailOAuthButtons.vue'
import LinuxDoOAuthSection from '@/components/auth/LinuxDoOAuthSection.vue'
import WechatOAuthSection from '@/components/auth/WechatOAuthSection.vue'
import OidcOAuthSection from '@/components/auth/OidcOAuthSection.vue'
import { useAppStore, useAuthStore } from '@/stores'

const router = useRouter()
const route = useRoute()
const { t } = useI18n()
const appStore = useAppStore()
const authStore = useAuthStore()

const form = reactive({
  email: '',
  password: ''
})

const errors = reactive({
  email: '',
  password: '',
  turnstile: ''
})

const errorMessage = ref('')
const submitting = ref(false)
const turnstileToken = ref('')
const turnstileSiteKey = ref('')
const totpTempToken = ref('')
const totpUserEmailMasked = ref('')
const totpSubmitting = ref(false)
const turnstileRef = ref<InstanceType<typeof TurnstileWidget> | null>(null)
const totpModalRef = ref<InstanceType<typeof TotpLoginModal> | null>(null)

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
  errors.password = ''
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

async function loadSettings(): Promise<void> {
  try {
    const publicSettings = await appStore.fetchPublicSettings(true)
    turnstileSiteKey.value = publicSettings?.turnstile_site_key || ''
  } catch (error) {
    console.error('Failed to load public settings:', error)
  }
}

async function submit(): Promise<void> {
  if (!validate()) {
    return
  }

  submitting.value = true
  resetErrors()

  try {
    const response = await authStore.login({
      email: form.email.trim(),
      password: form.password,
      turnstile_token: turnstileEnabled.value ? turnstileToken.value : undefined
    })

    if ('requires_2fa' in response && response.requires_2fa) {
      totpTempToken.value = response.temp_token || ''
      totpUserEmailMasked.value = response.user_email_masked || form.email.trim()
      return
    }

    appStore.showSuccess(t('auth.loginSuccess'))
    await router.push((route.query.redirect as string) || (authStore.isAdmin ? '/admin/dashboard' : '/dashboard'))
  } catch (error) {
    errorMessage.value = getRequestErrorMessage(error, t('auth.loginFailed'))
    appStore.showError(errorMessage.value)
    if (turnstileEnabled.value) {
      turnstileToken.value = ''
      turnstileRef.value?.reset()
    }
  } finally {
    submitting.value = false
  }
}

async function submitTotp(code: string): Promise<void> {
  if (!totpTempToken.value || code.trim().length !== 6) {
    return
  }

  totpSubmitting.value = true
  totpModalRef.value?.setVerifying(true)

  try {
    await authStore.login2FA(totpTempToken.value, code.trim())
    resetTotp()
    appStore.showSuccess(t('auth.loginSuccess'))
    await router.push((route.query.redirect as string) || (authStore.isAdmin ? '/admin/dashboard' : '/dashboard'))
  } catch (error) {
    const message = getRequestErrorMessage(error, t('auth.loginFailed'))
    totpModalRef.value?.setError(message)
  } finally {
    totpSubmitting.value = false
    totpModalRef.value?.setVerifying(false)
  }
}

function resetTotp(): void {
  if (totpSubmitting.value) {
    return
  }
  totpTempToken.value = ''
  totpUserEmailMasked.value = ''
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
  if (sessionStorage.getItem('auth_expired')) {
    sessionStorage.removeItem('auth_expired')
    errorMessage.value = t('auth.reloginRequired')
  }
})

onBeforeUnmount(() => {
  turnstileToken.value = ''
})
</script>
