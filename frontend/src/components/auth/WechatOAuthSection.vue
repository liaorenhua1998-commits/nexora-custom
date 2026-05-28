<template>
  <div class="space-y-4">
    <AuthOAuthButton
      :disabled="buttonDisabled"
      :label="t('auth.oidc.signIn', { providerName })"
      :hint="disabledHint"
      @click="startLogin"
    >
      <template #icon>
        <span class="inline-flex h-5 w-5 items-center justify-center rounded-full bg-[#22c55e] text-[10px] font-bold text-white">
          WX
        </span>
      </template>
    </AuthOAuthButton>

    <AuthOAuthDivider v-if="showDivider" :label="t('auth.oauthOrContinue')" />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AuthOAuthButton from './AuthOAuthButton.vue'
import AuthOAuthDivider from './AuthOAuthDivider.vue'
import { resolveWeChatOAuthStart } from '@/api/auth'
import { useAppStore } from '@/stores'
import { resolveAffiliateReferralCode, storeOAuthAffiliateCode } from '@/utils/oauthAffiliate'

const props = withDefaults(defineProps<{
  disabled?: boolean
  affCode?: string
  showDivider?: boolean
}>(), {
  showDivider: true
})

const appStore = useAppStore()
const route = useRoute()
const { t, locale } = useI18n()
const providerName = computed(() => t('auth.wechatProviderName'))

function localizeWeChatHint(zh: string, en: string): string {
  return locale.value.startsWith('zh') ? zh : en
}

const resolvedStart = computed(() => resolveWeChatOAuthStart(appStore.cachedPublicSettings))
const buttonDisabled = computed(() => props.disabled || resolvedStart.value.mode === null)
const disabledHint = computed(() => {
  if (props.disabled) {
    return ''
  }
  switch (resolvedStart.value.unavailableReason) {
    case 'external_browser_required':
      return t('auth.oauthFlow.wechatSystemBrowserOnly')
    case 'wechat_browser_required':
      return t('auth.oauthFlow.wechatBrowserOnly')
    case 'native_app_required':
      return localizeWeChatHint(
        '\u5f53\u524d\u4ec5\u914d\u7f6e\u4e86\u5fae\u4fe1\u79fb\u52a8\u5e94\u7528\u767b\u5f55\uff0c\u8bf7\u5728\u539f\u751f App \u4e2d\u901a\u8fc7\u5fae\u4fe1 SDK \u53d1\u8d77\u6388\u6743\u3002',
        'This site only has WeChat mobile app login configured. Continue from the native app through the WeChat SDK.'
      )
    case 'not_configured':
      return t('auth.oauthFlow.wechatNotConfigured')
    default:
      return ''
  }
})

onMounted(() => {
  if (!appStore.cachedPublicSettings && !appStore.publicSettingsLoaded) {
    appStore.fetchPublicSettings()
  }
})

function startLogin(): void {
  if (buttonDisabled.value || !resolvedStart.value.mode) {
    return
  }
  const redirectTo = (route.query.redirect as string) || '/dashboard'
  storeOAuthAffiliateCode(resolveAffiliateReferralCode(props.affCode, route.query.aff, route.query.aff_code))
  const apiBase = (import.meta.env.VITE_API_BASE_URL as string | undefined) || '/api/v1'
  const normalized = apiBase.replace(/\/$/, '')
  const mode = resolvedStart.value.mode
  const startURL = `${normalized}/auth/oauth/wechat/start?mode=${mode}&redirect=${encodeURIComponent(redirectTo)}`
  window.location.href = startURL
}
</script>
