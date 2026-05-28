<template>
  <AppLayout>
    <div class="space-y-6">
      <section class="rounded-2xl border border-gray-200/80 bg-white/85 px-6 py-6 shadow-sm dark:border-dark-600 dark:bg-dark-900/80">
        <div class="flex flex-col gap-5 xl:flex-row xl:items-start xl:justify-between">
          <div class="space-y-3">
            <div class="flex flex-wrap items-center gap-3">
              <span class="inline-flex h-11 w-11 items-center justify-center rounded-xl bg-primary-50 text-primary-600 dark:bg-primary-900/30 dark:text-primary-300">
                <Icon name="sparkles" size="lg" />
              </span>
              <div>
                <div class="flex flex-wrap items-center gap-3">
                  <h1 class="text-2xl font-semibold text-gray-900 dark:text-white">
                    {{ t('availableChannels.marketplace.title') }}
                  </h1>
                  <span class="inline-flex items-center rounded-full bg-primary-50 px-3 py-1 text-xs font-medium text-primary-700 dark:bg-primary-900/30 dark:text-primary-300">
                    {{ activeResultCount }}
                    {{ t('availableChannels.marketplace.resultsUnit') }}
                  </span>
                </div>
                <p class="mt-1 text-sm text-gray-600 dark:text-gray-300">
                  {{ t('availableChannels.marketplace.description') }}
                </p>
              </div>
            </div>

            <div class="flex flex-wrap gap-3 text-sm">
              <div class="rounded-lg bg-gray-50 px-3 py-2 dark:bg-dark-800/80">
                <div class="text-xs text-gray-500 dark:text-gray-400">
                  {{ t('availableChannels.marketplace.stats.models') }}
                </div>
                <div class="mt-1 font-semibold text-gray-900 dark:text-white">
                  {{ uniqueModelCount }}
                </div>
              </div>
              <div class="rounded-lg bg-gray-50 px-3 py-2 dark:bg-dark-800/80">
                <div class="text-xs text-gray-500 dark:text-gray-400">
                  {{ t('availableChannels.marketplace.stats.groups') }}
                </div>
                <div class="mt-1 font-semibold text-gray-900 dark:text-white">
                  {{ uniqueGroupCount }}
                </div>
              </div>
              <div class="rounded-lg bg-gray-50 px-3 py-2 dark:bg-dark-800/80">
                <div class="text-xs text-gray-500 dark:text-gray-400">
                  {{ t('availableChannels.marketplace.stats.channels') }}
                </div>
                <div class="mt-1 font-semibold text-gray-900 dark:text-white">
                  {{ channels.length }}
                </div>
              </div>
            </div>
          </div>

          <div class="flex flex-wrap items-center gap-2">
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-lg border px-3 py-2 text-sm font-medium transition-colors"
              :class="viewMode === 'market'
                ? 'border-primary-300 bg-primary-50 text-primary-700 dark:border-primary-700 dark:bg-primary-900/30 dark:text-primary-300'
                : 'border-gray-200 bg-white text-gray-600 hover:bg-gray-50 dark:border-dark-600 dark:bg-dark-800 dark:text-gray-300 dark:hover:bg-dark-700'"
              @click="viewMode = 'market'"
            >
              <Icon name="grid" size="sm" />
              {{ t('availableChannels.marketplace.marketView') }}
            </button>
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-lg border px-3 py-2 text-sm font-medium transition-colors"
              :class="viewMode === 'table'
                ? 'border-primary-300 bg-primary-50 text-primary-700 dark:border-primary-700 dark:bg-primary-900/30 dark:text-primary-300'
                : 'border-gray-200 bg-white text-gray-600 hover:bg-gray-50 dark:border-dark-600 dark:bg-dark-800 dark:text-gray-300 dark:hover:bg-dark-700'"
              @click="viewMode = 'table'"
            >
              <Icon name="menu" size="sm" />
              {{ t('availableChannels.marketplace.tableView') }}
            </button>
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-50 dark:border-dark-600 dark:bg-dark-800 dark:text-gray-300 dark:hover:bg-dark-700"
              :disabled="loading"
              @click="loadChannels"
            >
              <Icon name="refresh" size="sm" :class="loading ? 'animate-spin' : ''" />
              {{ t('common.refresh', 'Refresh') }}
            </button>
          </div>
        </div>

        <div class="mt-5 flex flex-col gap-3 xl:flex-row xl:items-center">
          <div class="relative flex-1">
            <Icon
              name="search"
              size="md"
              class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 dark:text-gray-500"
            />
            <input
              v-model="searchQuery"
              type="text"
              :placeholder="t('availableChannels.marketplace.searchPlaceholder')"
              class="input pl-10"
            />
          </div>

          <button
            v-if="viewMode === 'market' && hasActiveMarketFilters"
            type="button"
            class="inline-flex items-center gap-2 rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-50 dark:border-dark-600 dark:bg-dark-800 dark:text-gray-300 dark:hover:bg-dark-700"
            @click="resetMarketplaceFilters"
          >
            <Icon name="filter" size="sm" />
            {{ t('availableChannels.marketplace.resetFilters') }}
          </button>
        </div>
      </section>

      <template v-if="viewMode === 'market'">
        <div class="grid gap-6 xl:grid-cols-[280px,minmax(0,1fr)]">
          <aside class="rounded-2xl border border-gray-200/80 bg-white/85 p-4 shadow-sm dark:border-dark-600 dark:bg-dark-900/80">
            <div class="flex items-center justify-between gap-3">
              <div>
                <h2 class="text-sm font-semibold text-gray-900 dark:text-white">
                  {{ t('availableChannels.marketplace.filtersTitle') }}
                </h2>
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                  {{ t('availableChannels.marketplace.filtersHint') }}
                </p>
              </div>
              <button
                v-if="hasActiveMarketFilters"
                type="button"
                class="text-xs font-medium text-primary-600 transition-colors hover:text-primary-500 dark:text-primary-300"
                @click="resetMarketplaceFilters"
              >
                {{ t('availableChannels.marketplace.clearAll') }}
              </button>
            </div>

            <div class="mt-5 space-y-5">
              <section>
                <div class="mb-2 flex items-center gap-2 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
                  <Icon name="globe" size="xs" />
                  {{ t('availableChannels.marketplace.platforms') }}
                </div>
                <div class="flex flex-wrap gap-2">
                  <button
                    v-for="option in platformOptions"
                    :key="option.value"
                    type="button"
                    class="inline-flex items-center gap-2 rounded-lg border px-3 py-2 text-sm transition-colors"
                    :class="selectedPlatforms.includes(option.value)
                      ? 'border-primary-300 bg-primary-50 text-primary-700 dark:border-primary-700 dark:bg-primary-900/30 dark:text-primary-300'
                      : 'border-gray-200 bg-white text-gray-600 hover:bg-gray-50 dark:border-dark-600 dark:bg-dark-800 dark:text-gray-300 dark:hover:bg-dark-700'"
                    @click="togglePlatform(option.value)"
                  >
                    <PlatformIcon :platform="option.value as GroupPlatform" size="xs" />
                    <span>{{ option.value }}</span>
                    <span class="rounded bg-black/5 px-1.5 py-0.5 text-[11px] dark:bg-white/10">
                      {{ option.count }}
                    </span>
                  </button>
                </div>
              </section>

              <section class="border-t border-gray-100 pt-5 dark:border-dark-700">
                <div class="mb-2 flex items-center gap-2 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
                  <Icon name="users" size="xs" />
                  {{ t('availableChannels.marketplace.groups') }}
                </div>
                <div class="space-y-2">
                  <button
                    v-for="option in groupOptions"
                    :key="option.id"
                    type="button"
                    class="flex w-full items-center justify-between gap-3 rounded-lg border px-3 py-2 text-left transition-colors"
                    :class="selectedGroupIds.includes(option.id)
                      ? 'border-primary-300 bg-primary-50 text-primary-700 dark:border-primary-700 dark:bg-primary-900/30 dark:text-primary-300'
                      : 'border-gray-200 bg-white text-gray-600 hover:bg-gray-50 dark:border-dark-600 dark:bg-dark-800 dark:text-gray-300 dark:hover:bg-dark-700'"
                    @click="toggleGroup(option.id)"
                  >
                    <div class="flex min-w-0 items-center gap-2">
                      <PlatformIcon :platform="option.platform as GroupPlatform" size="xs" />
                      <div class="min-w-0">
                        <div class="truncate text-sm font-medium">{{ option.name }}</div>
                        <div class="text-[11px] text-gray-500 dark:text-gray-400">
                          {{ option.count }} {{ t('availableChannels.marketplace.resultsUnit') }}
                        </div>
                      </div>
                    </div>
                    <div class="text-right text-[11px]">
                      <div class="font-mono">
                        {{ formatMultiplier(option.effectiveRateMultiplier) }}x
                      </div>
                      <div
                        v-if="option.hasCustomRate"
                        class="text-gray-400 line-through dark:text-gray-500"
                      >
                        {{ formatMultiplier(option.baseRateMultiplier) }}x
                      </div>
                    </div>
                  </button>
                </div>
              </section>

              <section class="border-t border-gray-100 pt-5 dark:border-dark-700">
                <div class="mb-2 flex items-center gap-2 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
                  <Icon name="calculator" size="xs" />
                  {{ t('availableChannels.marketplace.billingModes') }}
                </div>
                <div class="flex flex-wrap gap-2">
                  <button
                    v-for="option in billingModeOptions"
                    :key="option.value"
                    type="button"
                    class="inline-flex items-center gap-2 rounded-lg border px-3 py-2 text-sm transition-colors"
                    :class="selectedBillingModes.includes(option.value)
                      ? 'border-primary-300 bg-primary-50 text-primary-700 dark:border-primary-700 dark:bg-primary-900/30 dark:text-primary-300'
                      : 'border-gray-200 bg-white text-gray-600 hover:bg-gray-50 dark:border-dark-600 dark:bg-dark-800 dark:text-gray-300 dark:hover:bg-dark-700'"
                    @click="toggleBillingMode(option.value)"
                  >
                    <span>{{ billingModeLabel(option.value) }}</span>
                    <span class="rounded bg-black/5 px-1.5 py-0.5 text-[11px] dark:bg-white/10">
                      {{ option.count }}
                    </span>
                  </button>
                </div>
              </section>
            </div>
          </aside>

          <section class="space-y-4">
            <div class="flex flex-wrap items-center gap-2 text-xs text-gray-500 dark:text-gray-400">
              <span>{{ t('availableChannels.marketplace.showingResults', { count: filteredMarketplaceEntries.length }) }}</span>
              <span v-if="selectedPlatforms.length > 0" class="rounded-full bg-gray-100 px-2 py-1 dark:bg-dark-800">
                {{ selectedPlatforms.join(', ') }}
              </span>
              <span v-if="selectedGroupIds.length > 0" class="rounded-full bg-gray-100 px-2 py-1 dark:bg-dark-800">
                {{ t('availableChannels.marketplace.groupFilterActive', { count: selectedGroupIds.length }) }}
              </span>
              <span v-if="selectedBillingModes.length > 0" class="rounded-full bg-gray-100 px-2 py-1 dark:bg-dark-800">
                {{ t('availableChannels.marketplace.billingFilterActive', { count: selectedBillingModes.length }) }}
              </span>
            </div>

            <div
              v-if="loading"
              class="flex min-h-[260px] items-center justify-center rounded-2xl border border-gray-200/80 bg-white/85 shadow-sm dark:border-dark-600 dark:bg-dark-900/80"
            >
              <Icon name="refresh" size="lg" class="animate-spin text-gray-400" />
            </div>

            <div
              v-else-if="filteredMarketplaceEntries.length === 0"
              class="rounded-2xl border border-dashed border-gray-200/80 bg-white/80 px-6 py-16 text-center shadow-sm dark:border-dark-600 dark:bg-dark-900/70"
            >
              <Icon name="inbox" size="xl" class="mx-auto mb-4 text-gray-400" />
              <div class="text-sm text-gray-500 dark:text-gray-400">
                {{ t('availableChannels.marketplace.empty') }}
              </div>
            </div>

            <div v-else class="grid gap-4 md:grid-cols-2 2xl:grid-cols-3">
              <AvailableChannelsMarketplaceCard
                v-for="entry in filteredMarketplaceEntries"
                :key="entry.id"
                :entry="entry"
                pricing-key-prefix="availableChannels.pricing"
                :no-pricing-label="t('availableChannels.noPricing')"
              />
            </div>
          </section>
        </div>
      </template>

      <section v-else>
        <AvailableChannelsTable
          :columns="columnLabels"
          :rows="filteredChannels"
          :loading="loading"
          :user-group-rates="userGroupRates"
          pricing-key-prefix="availableChannels.pricing"
          :no-pricing-label="t('availableChannels.noPricing')"
          :no-models-label="t('availableChannels.noModels')"
          :empty-label="t('availableChannels.empty')"
        />
      </section>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import AppLayout from '@/components/layout/AppLayout.vue'
import Icon from '@/components/icons/Icon.vue'
import PlatformIcon from '@/components/common/PlatformIcon.vue'
import AvailableChannelsTable from '@/components/channels/AvailableChannelsTable.vue'
import AvailableChannelsMarketplaceCard from '@/components/channels/AvailableChannelsMarketplaceCard.vue'
import userChannelsAPI, { type UserAvailableChannel } from '@/api/channels'
import userGroupsAPI from '@/api/groups'
import { useAppStore } from '@/stores/app'
import { extractApiErrorMessage } from '@/utils/apiError'
import { formatMultiplier } from '@/utils/formatters'
import {
  BILLING_MODE_IMAGE,
  BILLING_MODE_PER_REQUEST,
  BILLING_MODE_TOKEN,
} from '@/constants/channel'
import type { GroupPlatform } from '@/types'
import {
  buildMarketplaceEntries,
  filterMarketplaceEntries,
} from '@/components/channels/marketplace'

type ViewMode = 'market' | 'table'

interface GroupFilterOption {
  id: number
  name: string
  platform: string
  count: number
  effectiveRateMultiplier: number
  baseRateMultiplier: number
  hasCustomRate: boolean
}

const { t } = useI18n()
const appStore = useAppStore()

const channels = ref<UserAvailableChannel[]>([])
const userGroupRates = ref<Record<number, number>>({})
const loading = ref(false)
const searchQuery = ref('')
const viewMode = ref<ViewMode>('market')
const selectedPlatforms = ref<string[]>([])
const selectedGroupIds = ref<number[]>([])
const selectedBillingModes = ref<string[]>([])

const columnLabels = computed(() => ({
  name: t('availableChannels.columns.name'),
  description: t('availableChannels.columns.description'),
  platform: t('availableChannels.columns.platform'),
  groups: t('availableChannels.columns.groups'),
  supportedModels: t('availableChannels.columns.supportedModels'),
}))

const marketplaceEntries = computed(() =>
  buildMarketplaceEntries(channels.value, userGroupRates.value),
)

const filteredMarketplaceEntries = computed(() =>
  filterMarketplaceEntries(marketplaceEntries.value, {
    query: searchQuery.value,
    platforms: selectedPlatforms.value,
    groupIds: selectedGroupIds.value,
    billingModes: selectedBillingModes.value,
  }),
)

const filteredChannels = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  if (!query) {
    return channels.value
  }

  return channels.value
    .map((channel) => {
      const nameHit = channel.name.toLowerCase().includes(query)
      const descriptionHit = (channel.description || '').toLowerCase().includes(query)
      if (nameHit || descriptionHit) {
        return channel
      }

      const matchingPlatforms = channel.platforms.filter((platform) => {
        return (
          platform.platform.toLowerCase().includes(query) ||
          platform.groups.some((group) => group.name.toLowerCase().includes(query)) ||
          platform.supported_models.some((model) => model.name.toLowerCase().includes(query))
        )
      })

      if (matchingPlatforms.length === 0) {
        return null
      }

      return {
        ...channel,
        platforms: matchingPlatforms,
      }
    })
    .filter((channel): channel is UserAvailableChannel => channel !== null)
})

const activeResultCount = computed(() =>
  viewMode.value === 'market'
    ? filteredMarketplaceEntries.value.length
    : filteredChannels.value.length,
)

const uniqueModelCount = computed(() => {
  return new Set(marketplaceEntries.value.map((entry) => entry.modelName)).size
})

const uniqueGroupCount = computed(() => {
  return new Set(marketplaceEntries.value.map((entry) => entry.group.id)).size
})

const platformOptions = computed(() => {
  const counts = new Map<string, number>()
  for (const entry of marketplaceEntries.value) {
    counts.set(entry.platform, (counts.get(entry.platform) ?? 0) + 1)
  }
  return Array.from(counts.entries())
    .map(([value, count]) => ({ value, count }))
    .sort((a, b) => a.value.localeCompare(b.value, undefined, { sensitivity: 'base' }))
})

const groupOptions = computed<GroupFilterOption[]>(() => {
  const groups = new Map<number, GroupFilterOption>()
  for (const entry of marketplaceEntries.value) {
    const existing = groups.get(entry.group.id)
    if (existing) {
      existing.count += 1
      continue
    }
    groups.set(entry.group.id, {
      id: entry.group.id,
      name: entry.group.name,
      platform: entry.group.platform,
      count: 1,
      effectiveRateMultiplier: entry.effectiveRateMultiplier,
      baseRateMultiplier: entry.baseRateMultiplier,
      hasCustomRate: entry.hasCustomRate,
    })
  }

  return Array.from(groups.values()).sort((a, b) =>
    a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }),
  )
})

const billingModeOptions = computed(() => {
  const counts = new Map<string, number>()
  for (const entry of marketplaceEntries.value) {
    counts.set(entry.billingMode, (counts.get(entry.billingMode) ?? 0) + 1)
  }
  const order = [BILLING_MODE_TOKEN, BILLING_MODE_PER_REQUEST, BILLING_MODE_IMAGE, 'unknown']
  return Array.from(counts.entries())
    .map(([value, count]) => ({ value, count }))
    .sort((a, b) => order.indexOf(a.value) - order.indexOf(b.value))
})

const hasActiveMarketFilters = computed(() => {
  return (
    searchQuery.value.trim().length > 0 ||
    selectedPlatforms.value.length > 0 ||
    selectedGroupIds.value.length > 0 ||
    selectedBillingModes.value.length > 0
  )
})

function billingModeLabel(mode: string): string {
  switch (mode) {
    case BILLING_MODE_TOKEN:
      return t('availableChannels.pricing.billingModeToken')
    case BILLING_MODE_PER_REQUEST:
      return t('availableChannels.pricing.billingModePerRequest')
    case BILLING_MODE_IMAGE:
      return t('availableChannels.pricing.billingModeImage')
    default:
      return t('availableChannels.marketplace.unknownBillingMode')
  }
}

function togglePlatform(platform: string) {
  toggleValue(selectedPlatforms.value, platform)
}

function toggleGroup(groupId: number) {
  toggleValue(selectedGroupIds.value, groupId)
}

function toggleBillingMode(mode: string) {
  toggleValue(selectedBillingModes.value, mode)
}

function toggleValue<T>(values: T[], value: T) {
  const index = values.indexOf(value)
  if (index >= 0) {
    values.splice(index, 1)
    return
  }
  values.push(value)
}

function resetMarketplaceFilters() {
  searchQuery.value = ''
  selectedPlatforms.value = []
  selectedGroupIds.value = []
  selectedBillingModes.value = []
}

async function loadChannels() {
  loading.value = true
  try {
    const [list, rates] = await Promise.all([
      userChannelsAPI.getAvailable(),
      userGroupsAPI.getUserGroupRates().catch((error: unknown) => {
        console.error('Failed to load user group rates:', error)
        return {} as Record<number, number>
      }),
    ])
    channels.value = list
    userGroupRates.value = rates
  } catch (error: unknown) {
    appStore.showError(extractApiErrorMessage(error, t('common.error')))
  } finally {
    loading.value = false
  }
}

onMounted(loadChannels)
</script>
