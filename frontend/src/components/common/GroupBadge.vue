<template>
  <span
    :class="[
      'inline-flex items-center gap-1.5 rounded-md px-2 py-0.5 text-xs font-medium transition-colors',
      badgeClass,
    ]"
  >
    <PlatformIcon v-if="platform" :platform="platform" size="sm" />
    <span class="truncate">{{ name }}</span>
    <span v-if="showLabel" :class="labelClass">
      <template v-if="hasCustomRate">
        <span class="mr-0.5 line-through opacity-50">{{ rateMultiplier }}x</span>
        <span class="font-bold">{{ userRateMultiplier }}x</span>
      </template>
      <template v-else>
        {{ labelText }}
      </template>
    </span>
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { SubscriptionType, GroupPlatform } from '@/types'
import PlatformIcon from './PlatformIcon.vue'

interface Props {
  name: string
  platform?: GroupPlatform
  subscriptionType?: SubscriptionType
  rateMultiplier?: number
  userRateMultiplier?: number | null
  showRate?: boolean
  daysRemaining?: number | null
  alwaysShowRate?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  subscriptionType: 'standard',
  showRate: true,
  daysRemaining: null,
  userRateMultiplier: null,
  alwaysShowRate: false,
})

const { t } = useI18n()

const isSubscription = computed(() => props.subscriptionType === 'subscription')

const hasCustomRate = computed(() => {
  return props.userRateMultiplier !== null && props.userRateMultiplier !== undefined && props.rateMultiplier !== undefined && props.userRateMultiplier !== props.rateMultiplier
})

const showLabel = computed(() => {
  if (!props.showRate) return false
  if (isSubscription.value) return true
  return props.rateMultiplier !== undefined || hasCustomRate.value
})

const labelText = computed(() => {
  const rateLabel = props.rateMultiplier !== undefined ? `${props.rateMultiplier}x` : ''
  if (isSubscription.value && !props.alwaysShowRate) {
    if (props.daysRemaining !== null && props.daysRemaining !== undefined) {
      if (props.daysRemaining <= 0) return t('admin.users.expired')
      return t('admin.users.daysRemaining', { days: props.daysRemaining })
    }
    return t('groups.subscription')
  }
  return rateLabel
})

const labelClass = computed(() => {
  const base = 'px-1.5 py-0.5 rounded text-[10px] font-semibold'

  if (!isSubscription.value) return `${base} bg-black/10 dark:bg-white/10`
  if (props.daysRemaining !== null && props.daysRemaining !== undefined) {
    if (props.daysRemaining <= 0 || props.daysRemaining <= 3) return `${base} bg-red-200/80 text-red-800 dark:bg-red-800/50 dark:text-red-300`
    if (props.daysRemaining <= 7) return `${base} bg-amber-200/80 text-amber-800 dark:bg-amber-800/50 dark:text-amber-300`
  }

  if (props.platform === 'anthropic') return `${base} bg-orange-200/60 text-orange-800 dark:bg-orange-800/40 dark:text-orange-300`
  if (props.platform === 'openai') return `${base} bg-primary-200/70 text-primary-800 dark:bg-primary-800/40 dark:text-primary-300`
  if (props.platform === 'gemini') return `${base} bg-accent-200/70 text-accent-800 dark:bg-accent-800/40 dark:text-accent-300`
  return `${base} bg-violet-200/60 text-violet-800 dark:bg-violet-800/40 dark:text-violet-300`
})

const badgeClass = computed(() => {
  if (props.platform === 'anthropic') {
    return isSubscription.value
      ? 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400'
      : 'bg-amber-50 text-amber-700 dark:bg-amber-900/20 dark:text-amber-400'
  }
  if (props.platform === 'openai') {
    return isSubscription.value
      ? 'bg-primary-100 text-primary-700 dark:bg-primary-900/30 dark:text-primary-400'
      : 'bg-primary-50 text-primary-700 dark:bg-primary-900/20 dark:text-primary-400'
  }
  if (props.platform === 'gemini') {
    return isSubscription.value
      ? 'bg-accent-100 text-accent-700 dark:bg-accent-900/30 dark:text-accent-400'
      : 'bg-accent-50 text-accent-700 dark:bg-accent-900/20 dark:text-accent-400'
  }
  return isSubscription.value
    ? 'bg-violet-100 text-violet-700 dark:bg-violet-900/30 dark:text-violet-400'
    : 'bg-primary-100 text-primary-700 dark:bg-primary-900/30 dark:text-primary-400'
})
</script>
