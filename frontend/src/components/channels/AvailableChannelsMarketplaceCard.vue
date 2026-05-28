<template>
  <article class="flex h-full min-h-[300px] flex-col rounded-xl border border-gray-200/80 bg-white/85 p-5 shadow-sm transition-colors dark:border-dark-600 dark:bg-dark-900/75">
    <div class="flex items-start justify-between gap-4">
      <div class="min-w-0 space-y-3">
        <div class="flex items-start gap-3">
          <span
            :class="[
              'inline-flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-lg border',
              platformIconClass,
            ]"
          >
            <PlatformIcon :platform="entry.modelPlatform as GroupPlatform" size="sm" />
          </span>
          <div class="min-w-0">
            <h3 class="truncate text-lg font-semibold text-gray-900 dark:text-white">
              {{ entry.modelName }}
            </h3>
            <p class="truncate text-xs text-gray-500 dark:text-gray-400">
              {{ entry.channelName }}
            </p>
          </div>
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <GroupBadge
            :name="entry.group.name"
            :platform="entry.group.platform as GroupPlatform"
            :subscription-type="entry.group.subscription_type as SubscriptionType"
            :rate-multiplier="entry.baseRateMultiplier"
            :user-rate-multiplier="entry.hasCustomRate ? entry.effectiveRateMultiplier : null"
            always-show-rate
          />

          <span class="inline-flex items-center rounded-md bg-gray-100 px-2 py-1 text-[11px] font-medium text-gray-600 dark:bg-dark-700 dark:text-gray-300">
            {{ billingModeLabel }}
          </span>
        </div>
      </div>

      <span
        :class="[
          'inline-flex items-center gap-1 rounded-md border px-2 py-1 text-[11px] font-medium uppercase',
          platformBadgeClass(entry.platform),
        ]"
      >
        <PlatformIcon :platform="entry.platform as GroupPlatform" size="xs" />
        {{ entry.platform }}
      </span>
    </div>

    <div class="mt-5 flex-1 space-y-2 text-sm">
      <template v-if="entry.pricing">
        <template v-if="entry.billingMode === BILLING_MODE_TOKEN || entry.billingMode === 'unknown'">
          <PricingRow
            :label="t(prefixKey('inputPrice'))"
            :value="entry.pricing.input_price"
            :unit="t(prefixKey('unitPerMillion'))"
            :scale="1_000_000"
          />
          <PricingRow
            :label="t(prefixKey('outputPrice'))"
            :value="entry.pricing.output_price"
            :unit="t(prefixKey('unitPerMillion'))"
            :scale="1_000_000"
          />
          <PricingRow
            :label="t(prefixKey('cacheWritePrice'))"
            :value="entry.pricing.cache_write_price"
            :unit="t(prefixKey('unitPerMillion'))"
            :scale="1_000_000"
          />
          <PricingRow
            :label="t(prefixKey('cacheReadPrice'))"
            :value="entry.pricing.cache_read_price"
            :unit="t(prefixKey('unitPerMillion'))"
            :scale="1_000_000"
          />
          <PricingRow
            v-if="entry.pricing.image_output_price != null"
            :label="t(prefixKey('imageOutputPrice'))"
            :value="entry.pricing.image_output_price"
            :unit="t(prefixKey('unitPerMillion'))"
            :scale="1_000_000"
          />
        </template>

        <PricingRow
          v-else-if="entry.billingMode === BILLING_MODE_PER_REQUEST"
          :label="t(prefixKey('perRequestPrice'))"
          :value="entry.pricing.per_request_price"
          :unit="t(prefixKey('unitPerRequest'))"
          :scale="1"
        />

        <PricingRow
          v-else-if="entry.billingMode === BILLING_MODE_IMAGE"
          :label="t(prefixKey('imageOutputPrice'))"
          :value="entry.pricing.image_output_price"
          :unit="t(prefixKey('unitPerRequest'))"
          :scale="1"
        />

        <div
          v-if="entry.pricing.intervals.length > 0"
          class="mt-4 border-t border-dashed border-gray-200 pt-3 dark:border-dark-600"
        >
          <div class="mb-2 text-xs font-medium text-gray-500 dark:text-gray-400">
            {{ t(prefixKey('intervals')) }}
          </div>
          <div class="space-y-1.5 text-xs">
            <div
              v-for="(interval, index) in entry.pricing.intervals"
              :key="`${entry.id}-interval-${index}`"
              class="flex items-start justify-between gap-3"
            >
              <span class="text-gray-500 dark:text-gray-400">
                {{ intervalLabel(interval.min_tokens, interval.max_tokens, interval.tier_label) }}
              </span>
              <span class="text-right font-mono text-gray-700 dark:text-gray-200">
                {{ intervalValue(interval) }}
              </span>
            </div>
          </div>
        </div>
      </template>

      <div v-else class="rounded-lg border border-dashed border-gray-200 px-3 py-6 text-center text-sm text-gray-500 dark:border-dark-600 dark:text-gray-400">
        {{ noPricingLabel }}
      </div>
    </div>

    <footer class="mt-5 border-t border-gray-100 pt-3 text-xs text-gray-500 dark:border-dark-700 dark:text-gray-400">
      <div class="flex items-center justify-between gap-3">
        <span>{{ t('availableChannels.marketplace.effectiveRate') }}</span>
        <span class="font-mono text-gray-700 dark:text-gray-200">
          {{ formatMultiplier(entry.effectiveRateMultiplier) }}x
        </span>
      </div>
      <div
        v-if="entry.hasCustomRate"
        class="mt-1 flex items-center justify-between gap-3"
      >
        <span>{{ t('availableChannels.marketplace.defaultRate') }}</span>
        <span class="font-mono">
          {{ formatMultiplier(entry.baseRateMultiplier) }}x
        </span>
      </div>
    </footer>
  </article>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import PlatformIcon from '@/components/common/PlatformIcon.vue'
import GroupBadge from '@/components/common/GroupBadge.vue'
import PricingRow from './PricingRow.vue'
import type { UserPricingInterval } from '@/api/channels'
import type { GroupPlatform, SubscriptionType } from '@/types'
import { formatScaled } from '@/utils/pricing'
import { formatMultiplier } from '@/utils/formatters'
import {
  BILLING_MODE_IMAGE,
  BILLING_MODE_PER_REQUEST,
  BILLING_MODE_TOKEN,
} from '@/constants/channel'
import { platformBadgeClass, platformBadgeLightClass } from '@/utils/platformColors'
import type { MarketplaceEntry } from './marketplace'

const props = withDefaults(
  defineProps<{
    entry: MarketplaceEntry
    pricingKeyPrefix?: string
    noPricingLabel?: string
  }>(),
  {
    pricingKeyPrefix: 'availableChannels.pricing',
    noPricingLabel: '',
  },
)

const { t } = useI18n()

const platformIconClass = computed(() =>
  platformBadgeLightClass(props.entry.modelPlatform || props.entry.platform),
)

const billingModeLabel = computed(() => {
  switch (props.entry.billingMode) {
    case BILLING_MODE_TOKEN:
      return t(prefixKey('billingModeToken'))
    case BILLING_MODE_PER_REQUEST:
      return t(prefixKey('billingModePerRequest'))
    case BILLING_MODE_IMAGE:
      return t(prefixKey('billingModeImage'))
    default:
      return t(prefixKey('billingMode'))
  }
})

function prefixKey(key: string): string {
  return `${props.pricingKeyPrefix}.${key}`
}

function intervalLabel(minTokens: number, maxTokens: number | null, tierLabel?: string): string {
  if (tierLabel) {
    return tierLabel
  }
  if (maxTokens == null) {
    return `${minTokens}+`
  }
  const maxLabel = String(maxTokens)
  return `${minTokens} - ${maxLabel}`
}

function intervalValue(interval: UserPricingInterval): string {
  if (props.entry.billingMode === BILLING_MODE_PER_REQUEST || props.entry.billingMode === BILLING_MODE_IMAGE) {
    return formatScaled(interval.per_request_price, 1)
  }

  const input = formatScaled(interval.input_price, 1_000_000)
  const output = formatScaled(interval.output_price, 1_000_000)
  return `${input} / ${output}`
}
</script>
