import type {
  UserAvailableChannel,
  UserAvailableGroup,
  UserPricingInterval,
  UserSupportedModelPricing,
} from '@/api/channels'
import {
  BILLING_MODE_IMAGE,
  BILLING_MODE_PER_REQUEST,
  BILLING_MODE_TOKEN,
  type BillingMode,
} from '@/constants/channel'

export interface MarketplaceEntry {
  id: string
  channelName: string
  channelDescription: string
  platform: string
  group: UserAvailableGroup
  modelName: string
  modelPlatform: string
  billingMode: BillingMode | 'unknown'
  effectiveRateMultiplier: number
  baseRateMultiplier: number
  hasCustomRate: boolean
  pricing: UserSupportedModelPricing | null
  basePricing: UserSupportedModelPricing | null
}

export interface MarketplaceFilters {
  query?: string
  platforms?: string[]
  groupIds?: number[]
  billingModes?: string[]
}

const BILLING_MODE_SET = new Set<string>([
  BILLING_MODE_TOKEN,
  BILLING_MODE_PER_REQUEST,
  BILLING_MODE_IMAGE,
])

export function buildMarketplaceEntries(
  channels: UserAvailableChannel[],
  userGroupRates: Record<number, number>,
): MarketplaceEntry[] {
  const entries: MarketplaceEntry[] = []

  for (const channel of channels) {
    for (const section of channel.platforms) {
      for (const group of section.groups) {
        const baseRateMultiplier = normalizeMultiplier(group.rate_multiplier)
        const hasUserRate = Object.prototype.hasOwnProperty.call(userGroupRates, group.id)
        const effectiveRateMultiplier = normalizeMultiplier(
          hasUserRate ? userGroupRates[group.id] : baseRateMultiplier,
        )
        const hasCustomRate = hasUserRate && effectiveRateMultiplier !== baseRateMultiplier

        for (const model of section.supported_models) {
          const basePricing = clonePricing(model.pricing)
          entries.push({
            id: [
              channel.name,
              section.platform,
              String(group.id),
              model.name,
            ].join('::'),
            channelName: channel.name,
            channelDescription: channel.description,
            platform: section.platform,
            group,
            modelName: model.name,
            modelPlatform: model.platform || section.platform,
            billingMode: normalizeBillingMode(model.pricing?.billing_mode),
            effectiveRateMultiplier,
            baseRateMultiplier,
            hasCustomRate,
            pricing: scalePricing(basePricing, effectiveRateMultiplier),
            basePricing,
          })
        }
      }
    }
  }

  return entries.sort(compareMarketplaceEntries)
}

export function filterMarketplaceEntries(
  entries: MarketplaceEntry[],
  filters: MarketplaceFilters,
): MarketplaceEntry[] {
  const query = normalizeQuery(filters.query)
  const platformFilter = new Set((filters.platforms ?? []).map((value) => value.toLowerCase()))
  const groupFilter = new Set(filters.groupIds ?? [])
  const billingModeFilter = new Set((filters.billingModes ?? []).map((value) => value.toLowerCase()))

  return entries.filter((entry) => {
    if (platformFilter.size > 0 && !platformFilter.has(entry.platform.toLowerCase())) {
      return false
    }
    if (groupFilter.size > 0 && !groupFilter.has(entry.group.id)) {
      return false
    }
    if (billingModeFilter.size > 0 && !billingModeFilter.has(entry.billingMode.toLowerCase())) {
      return false
    }
    if (!query) {
      return true
    }

    const haystack = [
      entry.modelName,
      entry.modelPlatform,
      entry.group.name,
      entry.channelName,
      entry.channelDescription,
      entry.billingMode,
    ]
      .join(' ')
      .toLowerCase()

    return haystack.includes(query)
  })
}

function compareMarketplaceEntries(a: MarketplaceEntry, b: MarketplaceEntry): number {
  const modelCompare = a.modelName.localeCompare(b.modelName, undefined, { sensitivity: 'base' })
  if (modelCompare !== 0) return modelCompare

  const groupCompare = a.group.name.localeCompare(b.group.name, undefined, { sensitivity: 'base' })
  if (groupCompare !== 0) return groupCompare

  const channelCompare = a.channelName.localeCompare(b.channelName, undefined, {
    sensitivity: 'base',
  })
  if (channelCompare !== 0) return channelCompare

  return a.platform.localeCompare(b.platform, undefined, { sensitivity: 'base' })
}

function normalizeBillingMode(mode: string | undefined): BillingMode | 'unknown' {
  if (mode && BILLING_MODE_SET.has(mode)) {
    return mode as BillingMode
  }
  return 'unknown'
}

function clonePricing(pricing: UserSupportedModelPricing | null | undefined): UserSupportedModelPricing | null {
  if (!pricing) {
    return null
  }
  return {
    billing_mode: pricing.billing_mode,
    input_price: pricing.input_price,
    output_price: pricing.output_price,
    cache_write_price: pricing.cache_write_price,
    cache_read_price: pricing.cache_read_price,
    image_output_price: pricing.image_output_price,
    per_request_price: pricing.per_request_price,
    intervals: pricing.intervals.map((interval) => ({ ...interval })),
  }
}

function scalePricing(
  pricing: UserSupportedModelPricing | null,
  multiplier: number,
): UserSupportedModelPricing | null {
  if (!pricing) {
    return null
  }

  return {
    billing_mode: pricing.billing_mode,
    input_price: scaleNullable(pricing.input_price, multiplier),
    output_price: scaleNullable(pricing.output_price, multiplier),
    cache_write_price: scaleNullable(pricing.cache_write_price, multiplier),
    cache_read_price: scaleNullable(pricing.cache_read_price, multiplier),
    image_output_price: scaleNullable(pricing.image_output_price, multiplier),
    per_request_price: scaleNullable(pricing.per_request_price, multiplier),
    intervals: pricing.intervals.map((interval) => scaleInterval(interval, multiplier)),
  }
}

function scaleInterval(interval: UserPricingInterval, multiplier: number): UserPricingInterval {
  return {
    ...interval,
    input_price: scaleNullable(interval.input_price, multiplier),
    output_price: scaleNullable(interval.output_price, multiplier),
    cache_write_price: scaleNullable(interval.cache_write_price, multiplier),
    cache_read_price: scaleNullable(interval.cache_read_price, multiplier),
    per_request_price: scaleNullable(interval.per_request_price, multiplier),
  }
}

function scaleNullable(value: number | null, multiplier: number): number | null {
  if (value == null) {
    return null
  }
  return value * multiplier
}

function normalizeMultiplier(value: number | null | undefined): number {
  if (typeof value !== 'number' || !Number.isFinite(value) || value <= 0) {
    return 1
  }
  return value
}

function normalizeQuery(value: string | undefined): string {
  return (value ?? '').trim().toLowerCase()
}
