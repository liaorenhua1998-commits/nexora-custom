<template>
  <StandalonePageShell max-width="lg">
    <div class="mx-auto max-w-2xl py-2">
      <div class="space-y-6">
        <div v-if="loading" class="glass-card flex items-center justify-center py-20">
          <div class="h-8 w-8 animate-spin rounded-full border-4 border-primary-500 border-t-transparent"></div>
        </div>

        <template v-else>
          <div class="glass-card p-8 text-center">
            <div
              class="mx-auto flex h-20 w-20 items-center justify-center rounded-3xl"
              :class="statusIconShellClass"
            >
              <div
                v-if="isPending"
                class="h-10 w-10 animate-spin rounded-full border-4 border-current border-t-transparent"
              ></div>
              <Icon v-else :name="statusIconName" size="xl" class="h-10 w-10" :stroke-width="2" />
            </div>
            <h2 class="mt-5 text-2xl font-bold text-gray-900 dark:text-white">
              {{ statusTitle }}
            </h2>
            <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
              {{ statusHint }}
            </p>
          </div>

          <div v-if="order" class="glass-card p-6">
            <div class="surface-subtle p-5">
              <div class="space-y-3 text-sm">
                <div class="flex justify-between gap-4">
                  <span class="text-gray-500 dark:text-gray-400">{{ t('payment.orders.orderId') }}</span>
                  <span class="font-medium text-gray-900 dark:text-white">#{{ order.id }}</span>
                </div>
                <div v-if="order.out_trade_no" class="flex justify-between gap-4">
                  <span class="text-gray-500 dark:text-gray-400">{{ t('payment.orders.orderNo') }}</span>
                  <span class="break-all text-right font-medium text-gray-900 dark:text-white">{{ order.out_trade_no }}</span>
                </div>
                <div class="flex justify-between gap-4">
                  <span class="text-gray-500 dark:text-gray-400">{{ t('payment.orders.baseAmount') }}</span>
                  <span class="font-medium text-gray-900 dark:text-white">&#165;{{ baseAmount.toFixed(2) }}</span>
                </div>
                <div v-if="order.fee_rate > 0" class="flex justify-between gap-4">
                  <span class="text-gray-500 dark:text-gray-400">{{ t('payment.orders.fee') }} ({{ order.fee_rate }}%)</span>
                  <span class="font-medium text-gray-900 dark:text-white">&#165;{{ feeAmount.toFixed(2) }}</span>
                </div>
                <div class="flex justify-between gap-4 border-t border-white/50 pt-3 dark:border-white/10">
                  <span class="font-medium text-gray-700 dark:text-gray-300">{{ t('payment.orders.payAmount') }}</span>
                  <span class="text-lg font-bold text-primary-600 dark:text-primary-400">&#165;{{ order.pay_amount.toFixed(2) }}</span>
                </div>
                <div v-if="order.amount !== order.pay_amount" class="flex justify-between gap-4">
                  <span class="text-gray-500 dark:text-gray-400">{{ t('payment.orders.creditedAmount') }}</span>
                  <span class="font-medium text-gray-900 dark:text-white">{{ order.order_type === 'balance' ? '$' : 'CNY ' }}{{ order.amount.toFixed(2) }}</span>
                </div>
                <div class="flex justify-between gap-4">
                  <span class="text-gray-500 dark:text-gray-400">{{ t('payment.orders.paymentMethod') }}</span>
                  <span class="font-medium text-gray-900 dark:text-white">{{ t(paymentMethodI18nKey(order.payment_type), normalizedOrderPaymentType(order.payment_type)) }}</span>
                </div>
                <div class="flex items-center justify-between gap-4">
                  <span class="text-gray-500 dark:text-gray-400">{{ t('payment.orders.status') }}</span>
                  <OrderStatusBadge :status="order.status" />
                </div>
              </div>
            </div>
          </div>

          <div v-else-if="returnInfo" class="glass-card p-6">
            <div class="surface-subtle p-5">
              <div class="space-y-3 text-sm">
                <div v-if="returnInfo.outTradeNo" class="flex justify-between gap-4">
                  <span class="text-gray-500 dark:text-gray-400">{{ t('payment.orders.orderId') }}</span>
                  <span class="break-all text-right font-medium text-gray-900 dark:text-white">{{ returnInfo.outTradeNo }}</span>
                </div>
                <div v-if="returnInfo.money" class="flex justify-between gap-4">
                  <span class="text-gray-500 dark:text-gray-400">{{ t('payment.orders.payAmount') }}</span>
                  <span class="font-medium text-gray-900 dark:text-white">&#165;{{ returnInfo.money }}</span>
                </div>
                <div v-if="returnInfo.type" class="flex justify-between gap-4">
                  <span class="text-gray-500 dark:text-gray-400">{{ t('payment.orders.paymentMethod') }}</span>
                  <span class="font-medium text-gray-900 dark:text-white">{{ t(paymentMethodI18nKey(returnInfo.type), normalizedOrderPaymentType(returnInfo.type)) }}</span>
                </div>
              </div>
            </div>
          </div>

          <div class="flex flex-col gap-3 sm:flex-row">
            <button class="btn btn-secondary flex-1" @click="router.push('/purchase')">{{ t('payment.result.backToRecharge') }}</button>
            <button class="btn btn-primary flex-1" @click="router.push('/orders')">{{ t('payment.result.viewOrders') }}</button>
          </div>
        </template>
      </div>
    </div>
  </StandalonePageShell>
</template>

<script setup lang="ts">
import { ref, computed, onBeforeUnmount, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import Icon from '@/components/icons/Icon.vue'
import StandalonePageShell from '@/components/layout/StandalonePageShell.vue'
import OrderStatusBadge from '@/components/payment/OrderStatusBadge.vue'
import {
  PAYMENT_RECOVERY_STORAGE_KEY,
  clearPaymentRecoverySnapshot,
  readPaymentRecoverySnapshot,
} from '@/components/payment/paymentFlow'
import { usePaymentStore } from '@/stores/payment'
import { paymentAPI } from '@/api/payment'
import type { PaymentOrder } from '@/types/payment'
import { normalizePaymentMethodForDisplay, paymentMethodI18nKey } from './paymentUx'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const paymentStore = usePaymentStore()

const order = ref<PaymentOrder | null>(null)
const loading = ref(true)

interface ReturnInfo {
  outTradeNo: string
  money: string
  type: string
  tradeStatus: string
}
const returnInfo = ref<ReturnInfo | null>(null)

const SUCCESS_STATUSES = new Set(['COMPLETED', 'PAID', 'RECHARGING'])
const PENDING_STATUSES = new Set(['PENDING', 'CREATED', 'WAITING', 'PROCESSING'])
const STATUS_REFRESH_INTERVAL_MS = 2000
const STATUS_REFRESH_MAX_ATTEMPTS = 15

let statusRefreshTimer: ReturnType<typeof setTimeout> | null = null
const refreshAttempts = ref(0)

/** 鍏呭€奸噾棰?= pay_amount / (1 + fee_rate/100)锛宖ee_rate=0 鏃剁瓑浜?pay_amount */
const baseAmount = computed(() => {
  if (!order.value || order.value.fee_rate <= 0) return order.value?.pay_amount ?? 0
  return Math.round((order.value.pay_amount / (1 + order.value.fee_rate / 100)) * 100) / 100
})

/** 鎵嬬画璐?= pay_amount - baseAmount */
const feeAmount = computed(() => {
  if (!order.value || order.value.fee_rate <= 0) return 0
  return Math.round((order.value.pay_amount - baseAmount.value) * 100) / 100
})

const isSuccess = computed(() => {
  return isSuccessStatus(order.value?.status)
})

const isPending = computed(() => {
  return isPendingStatus(order.value?.status)
})

const statusTitle = computed(() => {
  if (isSuccess.value) {
    return t('payment.result.success')
  }
  if (isPending.value) {
    return t('payment.result.processing')
  }
  return t('payment.result.failed')
})

const statusHint = computed(() => {
  if (isSuccess.value) {
    return t('payment.result.viewOrders')
  }
  if (isPending.value) {
    return t('payment.result.processingHint')
  }
  return t('payment.result.backToRecharge')
})

const statusIconName = computed(() => {
  if (isSuccess.value) return 'check'
  if (isPending.value) return 'clock'
  return 'x'
})

const statusIconShellClass = computed(() => {
  if (isSuccess.value) {
    return 'bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400'
  }
  if (isPending.value) {
    return 'bg-amber-100 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400'
  }
  return 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400'
})

function normalizedOrderPaymentType(paymentType: string): string {
  return normalizePaymentMethodForDisplay(paymentType) || paymentType
}

function normalizeOrderStatus(status: string | null | undefined): string {
  return String(status || '').trim().toUpperCase()
}

function isSuccessStatus(status: string | null | undefined): boolean {
  return SUCCESS_STATUSES.has(normalizeOrderStatus(status))
}

function isPendingStatus(status: string | null | undefined): boolean {
  return PENDING_STATUSES.has(normalizeOrderStatus(status))
}

function readRouteQueryString(key: string): string {
  const value = route.query[key]
  if (Array.isArray(value)) {
    return typeof value[0] === 'string' ? value[0] : ''
  }
  return typeof value === 'string' ? value : ''
}

function restoreRecoverySnapshot(context: {
  resumeToken: string
  routeOrderId: number
  routeOutTradeNo: string
}) {
  if (typeof window === 'undefined') {
    return null
  }

  const rawSnapshot = window.localStorage.getItem(PAYMENT_RECOVERY_STORAGE_KEY)
  if (!rawSnapshot) {
    return null
  }

  if (context.resumeToken) {
    return readPaymentRecoverySnapshot(rawSnapshot, {
      resumeToken: context.resumeToken,
    })
  }

  if (!context.routeOrderId && !context.routeOutTradeNo) {
    return null
  }

  const restored = readPaymentRecoverySnapshot(rawSnapshot)
  if (!restored) {
    return null
  }

  if (context.routeOrderId > 0 && restored.orderId !== context.routeOrderId) {
    return null
  }

  if (context.routeOutTradeNo && restored.outTradeNo !== context.routeOutTradeNo) {
    return null
  }

  return restored
}

async function resolveOrderFromResumeToken(resumeToken: string): Promise<PaymentOrder | null> {
  try {
    const result = await paymentAPI.resolveOrderPublicByResumeToken(resumeToken)
    return result.data
  } catch (_err: unknown) {
    return null
  }
}

async function resolveOrderFromOutTradeNo(outTradeNo: string): Promise<PaymentOrder | null> {
  try {
    const result = await paymentAPI.verifyOrderPublic(outTradeNo)
    return result.data
  } catch (_err: unknown) {
    return null
  }
}

function clearStatusRefreshTimer(): void {
  if (statusRefreshTimer !== null) {
    clearTimeout(statusRefreshTimer)
    statusRefreshTimer = null
  }
}

function clearRecoverySnapshot(): void {
  if (typeof window === 'undefined') return
  clearPaymentRecoverySnapshot(window.localStorage, PAYMENT_RECOVERY_STORAGE_KEY)
}

function clearRecoverySnapshotForTerminalStatus(status: string | null | undefined): void {
  if (!status) return
  if (!isPendingStatus(status)) {
    clearRecoverySnapshot()
  }
}

function scheduleStatusRefresh(refreshOrder: (() => Promise<PaymentOrder | null>) | null): void {
  clearStatusRefreshTimer()
  if (!refreshOrder || !isPending.value || refreshAttempts.value >= STATUS_REFRESH_MAX_ATTEMPTS) {
    return
  }

  statusRefreshTimer = setTimeout(async () => {
    refreshAttempts.value += 1
    const refreshedOrder = await refreshOrder()
    if (refreshedOrder) {
      order.value = refreshedOrder
      clearRecoverySnapshotForTerminalStatus(refreshedOrder.status)
    }

    if (isPendingStatus(order.value?.status)) {
      scheduleStatusRefresh(refreshOrder)
    }
  }, STATUS_REFRESH_INTERVAL_MS)
}

onMounted(async () => {
  const resumeToken = readRouteQueryString('resume_token')
  const routeOrderId = Number(readRouteQueryString('order_id')) || 0
  let outTradeNo = readRouteQueryString('out_trade_no')
  let orderId = 0
  let resumeTokenLookupFailed = false

  const restored = restoreRecoverySnapshot({
    resumeToken,
    routeOrderId,
    routeOutTradeNo: outTradeNo,
  })
  if (restored?.orderId) {
    orderId = restored.orderId
  }
  if (!outTradeNo && restored?.outTradeNo) {
    outTradeNo = restored.outTradeNo
  }

  if (resumeToken) {
    const resolvedOrder = await resolveOrderFromResumeToken(resumeToken)
    if (resolvedOrder) {
      order.value = resolvedOrder
      if (!orderId) {
        orderId = resolvedOrder.id
      }
    } else if (routeOrderId > 0) {
      resumeTokenLookupFailed = true
      orderId = routeOrderId
    } else {
      resumeTokenLookupFailed = true
    }
  } else if (routeOrderId > 0) {
    orderId = routeOrderId
  }

  const hasLegacyFallbackContext = readRouteQueryString('trade_status').trim() !== ''
  const shouldUsePublicOutTradeNo = outTradeNo !== '' && (hasLegacyFallbackContext || routeOrderId > 0 || orderId > 0)

  if (!order.value && orderId && (!resumeToken || routeOrderId > 0)) {
    try {
      order.value = await paymentStore.pollOrderStatus(orderId)
    } catch (_err: unknown) {
      // Order lookup failed, will try legacy fallback below when possible.
    }
  }

  if (!order.value && shouldUsePublicOutTradeNo && (!resumeToken || resumeTokenLookupFailed)) {
    const legacyOrder = await resolveOrderFromOutTradeNo(outTradeNo)
    if (legacyOrder) {
      order.value = legacyOrder
      if (!orderId) {
        orderId = legacyOrder.id
      }
    }
  }

  if (!order.value && !orderId && outTradeNo && hasLegacyFallbackContext) {
    returnInfo.value = {
      outTradeNo,
      money: String(route.query.money || ''),
      type: String(route.query.type || ''),
      tradeStatus: String(route.query.trade_status || ''),
    }
  }

  const refreshOrder = async (): Promise<PaymentOrder | null> => {
    if (resumeToken) {
      const resolvedOrder = await resolveOrderFromResumeToken(resumeToken)
      if (resolvedOrder) {
        return resolvedOrder
      }
    }

    if (orderId) {
      try {
        return await paymentStore.pollOrderStatus(orderId)
      } catch (_err: unknown) {
        // Fall through to legacy public verification when order polling is unavailable.
      }
    }

    if (shouldUsePublicOutTradeNo) {
      return await resolveOrderFromOutTradeNo(outTradeNo)
    }

    return null
  }

  if (isPendingStatus(order.value?.status)) {
    scheduleStatusRefresh(refreshOrder)
  } else if (order.value) {
    clearRecoverySnapshotForTerminalStatus(order.value.status)
  } else if (returnInfo.value) {
    clearRecoverySnapshot()
  }
  loading.value = false
})

onBeforeUnmount(() => {
  clearStatusRefreshTimer()
})
</script>
