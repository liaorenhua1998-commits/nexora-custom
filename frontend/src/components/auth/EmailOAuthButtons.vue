<template>
  <div v-if="hasProviders" class="space-y-4">
    <AuthOAuthDivider v-if="showDivider" :label="t('auth.oauthOrContinue')" />

    <div :class="providerGridClass">
      <AuthOAuthButton
        v-for="provider in visibleProviders"
        :key="provider"
        :disabled="disabled"
        :label="providerLabel(provider)"
        @click="startLogin(provider)"
      >
        <template #icon>
          <GitHubMark v-if="provider === 'github'" class="h-5 w-5 text-slate-800" />
          <GoogleMark v-else class="h-5 w-5" />
        </template>
      </AuthOAuthButton>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AuthOAuthButton from './AuthOAuthButton.vue'
import AuthOAuthDivider from './AuthOAuthDivider.vue'
import GitHubMark from './GitHubMark.vue'
import GoogleMark from './GoogleMark.vue'
import { resolveAffiliateReferralCode, storeOAuthAffiliateCode } from '@/utils/oauthAffiliate'

type EmailOAuthProvider = 'github' | 'google'
const EMAIL_OAUTH_PENDING_PROVIDER_KEY = 'email_oauth_pending_provider'

const props = withDefaults(defineProps<{
  disabled?: boolean
  affCode?: string
  githubEnabled?: boolean
  googleEnabled?: boolean
  showDivider?: boolean
}>(), {
  showDivider: true
})

const route = useRoute()
const { t } = useI18n()

const visibleProviders = computed<EmailOAuthProvider[]>(() => {
  const providers: EmailOAuthProvider[] = []
  if (props.githubEnabled) providers.push('github')
  if (props.googleEnabled) providers.push('google')
  return providers
})

const hasProviders = computed(() => visibleProviders.value.length > 0)
const hasMultipleProviders = computed(() => visibleProviders.value.length > 1)
const providerGridClass = computed(() => [
  'grid',
  'grid-cols-1',
  'gap-3',
  hasMultipleProviders.value ? 'sm:grid-cols-2' : ''
])

function providerLabel(provider: EmailOAuthProvider): string {
  const name = provider === 'github' ? 'GitHub' : 'Google'
  return hasMultipleProviders.value ? name : t('auth.emailOAuth.signIn', { providerName: name })
}

function startLogin(provider: EmailOAuthProvider): void {
  const redirectTo = (route.query.redirect as string) || '/dashboard'
  const affiliateCode = resolveAffiliateReferralCode(props.affCode, route.query.aff, route.query.aff_code)
  storeOAuthAffiliateCode(affiliateCode)
  window.sessionStorage.setItem(EMAIL_OAUTH_PENDING_PROVIDER_KEY, provider)
  const apiBase = (import.meta.env.VITE_API_BASE_URL as string | undefined) || '/api/v1'
  const normalized = apiBase.replace(/\/$/, '')
  const params = new URLSearchParams({ redirect: redirectTo })
  if (affiliateCode) {
    params.set('aff_code', affiliateCode)
  }
  const startURL = `${normalized}/auth/oauth/${provider}/start?${params.toString()}`
  window.location.href = startURL
}
</script>
