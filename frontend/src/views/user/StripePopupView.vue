<template>
  <StandalonePageShell centered max-width="md">
    <div class="glass-card overflow-hidden">
      <div class="border-b border-white/50 bg-white/40 px-6 py-5 dark:border-white/10 dark:bg-white/5">
        <div class="flex items-center gap-4">
          <div
            class="flex h-12 w-12 items-center justify-center rounded-2xl text-white shadow-[0_18px_36px_rgba(15,23,42,0.14)]"
            :style="{ background: `linear-gradient(135deg, ${methodColor} 0%, ${methodColor}CC 100%)` }"
          >
            <Icon :name="success ? 'check' : error ? 'exclamationCircle' : 'creditCard'" size="lg" :stroke-width="2" />
          </div>
          <div class="min-w-0">
            <p class="text-xs font-semibold uppercase tracking-[0.14em] text-gray-500 dark:text-gray-400">
              {{ methodLabel }}
            </p>
            <h1 class="mt-1 text-lg font-semibold text-gray-900 dark:text-white">
              {{ popupTitle }}
            </h1>
          </div>
        </div>
      </div>

      <div class="space-y-5 p-6">
        <div v-if="amount || orderId" class="surface-subtle p-4 text-center">
          <p v-if="amount" class="text-3xl font-bold" :style="{ color: methodColor }">&#165;{{ amount }}</p>
          <p v-if="orderId" class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ t('payment.orders.orderId') }}: {{ orderId }}
          </p>
        </div>

        <div v-if="error" class="space-y-4">
          <div class="rounded-2xl border border-red-200/80 bg-red-50/80 p-4 text-sm text-red-600 dark:border-red-800/80 dark:bg-red-900/25 dark:text-red-300">
            {{ error }}
          </div>
          <button class="btn btn-secondary w-full" @click="closeWindow">
            {{ t('common.close') }}
          </button>
        </div>

        <div v-else-if="success" class="space-y-4 py-2 text-center">
          <div class="mx-auto flex h-16 w-16 items-center justify-center rounded-3xl bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400">
            <Icon name="check" size="xl" :stroke-width="2" />
          </div>
          <p class="text-sm text-gray-500 dark:text-gray-400">{{ t('payment.result.success') }}</p>
          <button class="btn btn-primary w-full" @click="closeWindow">
            {{ t('common.close') }}
          </button>
        </div>

        <div v-else class="surface-subtle flex items-center justify-center gap-3 px-5 py-6 text-center">
          <div
            class="h-8 w-8 animate-spin rounded-full border-2 border-t-transparent"
            :style="{ borderColor: methodColor, borderTopColor: 'transparent' }"
          />
          <span class="text-sm text-gray-500 dark:text-gray-400">{{ hint }}</span>
        </div>
      </div>
    </div>
  </StandalonePageShell>
</template>

<script setup lang="ts">
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute } from 'vue-router'
import Icon from '@/components/icons/Icon.vue'
import StandalonePageShell from '@/components/layout/StandalonePageShell.vue'
import { extractI18nErrorMessage } from '@/utils/apiError'
import { isMobileDevice } from '@/utils/device'
import { paymentMethodI18nKey } from './paymentUx'

interface StripeWithWechatPay {
  confirmWechatPayPayment(clientSecret: string, options: Record<string, unknown>): Promise<{ error?: { message?: string }; paymentIntent?: { status: string } }>
}

const METHOD_COLORS: Record<string, string> = {
  alipay: '#00AEEF',
  wechat_pay: '#07C160',
}
const DEFAULT_METHOD_COLOR = '#635bff'

const { t } = useI18n()
const route = useRoute()

const orderId = String(route.query.order_id || '')
const method = String(route.query.method || 'alipay')
const amount = String(route.query.amount || '')

const methodColor = computed(() => METHOD_COLORS[method] || DEFAULT_METHOD_COLOR)
const methodLabel = computed(() => t(paymentMethodI18nKey(method), method))

const error = ref('')
const success = ref(false)
const hint = ref(t('payment.stripePopup.redirecting'))

const popupTitle = computed(() => {
  if (error.value) return t('payment.result.failed')
  if (success.value) return t('payment.result.success')
  return t('payment.qr.waitingPayment')
})

let pollTimer: ReturnType<typeof setInterval> | null = null

function closeWindow() { window.close() }

onMounted(() => {
  const handler = (event: MessageEvent) => {
    if (event.origin !== window.location.origin) return
    if (event.data?.type !== 'STRIPE_POPUP_INIT') return
    window.removeEventListener('message', handler)
    initStripe(event.data.clientSecret, event.data.publishableKey)
  }
  window.addEventListener('message', handler)

  if (window.opener) {
    window.opener.postMessage({ type: 'STRIPE_POPUP_READY' }, window.location.origin)
  }

  setTimeout(() => {
    if (!error.value && !success.value) {
      error.value = t('payment.stripePopup.timeout')
    }
  }, 15000)
})

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer)
})

async function initStripe(clientSecret: string, publishableKey: string) {
  if (!clientSecret || !publishableKey) {
    error.value = t('payment.stripeMissingParams')
    return
  }
  try {
    const { loadStripe } = await import('@stripe/stripe-js')
    const stripe = await loadStripe(publishableKey)
    if (!stripe) { error.value = t('payment.stripeLoadFailed'); return }

    const returnUrl = window.location.origin + '/payment/result?order_id=' + orderId + '&status=success'

    if (method === 'alipay') {
      // Alipay: redirect this popup to Alipay payment page
      const { error: err } = await stripe.confirmAlipayPayment(clientSecret, { return_url: returnUrl })
      if (err) error.value = err.message || t('payment.result.failed')
    } else if (method === 'wechat_pay') {
      // WeChat: Stripe shows its built-in QR dialog, user scans, promise resolves
      hint.value = t('payment.stripePopup.loadingQr')
      const result = await (stripe as unknown as StripeWithWechatPay).confirmWechatPayPayment(clientSecret, {
        payment_method_options: { wechat_pay: { client: isMobileDevice() ? 'mobile_web' : 'web' } },
      })
      if (result.error) {
        error.value = result.error.message || t('payment.result.failed')
      } else if (result.paymentIntent?.status === 'succeeded') {
        success.value = true
        setTimeout(closeWindow, 2000)
      } else {
        // Payment not completed (user closed QR dialog)
        startPolling()
      }
    }
  } catch (err: unknown) {
    error.value = extractI18nErrorMessage(err, t, 'payment.errors', t('payment.stripeLoadFailed'))
  }
}

function startPolling() {
  pollTimer = setInterval(async () => {
    try {
      const token = document.cookie.split('; ').find(c => c.startsWith('token='))?.split('=')[1]
        || localStorage.getItem('token') || ''
      const res = await fetch('/api/v1/payment/orders/' + orderId, {
        headers: token ? { Authorization: 'Bearer ' + token } : {},
        credentials: 'include',
      })
      if (!res.ok) return
      const data = await res.json()
      const status = data?.data?.status
      if (status === 'COMPLETED' || status === 'PAID') {
        if (pollTimer) { clearInterval(pollTimer); pollTimer = null }
        success.value = true
        setTimeout(closeWindow, 2000)
      }
    } catch { /* ignore */ }
  }, 3000)
}
</script>
