import { describe, expect, it } from 'vitest'
import {
  buildMarketplaceEntries,
  filterMarketplaceEntries,
} from '../marketplace'
import type { UserAvailableChannel } from '@/api/channels'

const fixtureChannels: UserAvailableChannel[] = [
  {
    name: 'openai-main',
    description: 'Primary OpenAI channel',
    platforms: [
      {
        platform: 'openai',
        groups: [
          {
            id: 11,
            name: 'vip-openai',
            platform: 'openai',
            subscription_type: 'standard',
            rate_multiplier: 0.8,
            is_exclusive: true,
          },
          {
            id: 12,
            name: 'public-openai',
            platform: 'openai',
            subscription_type: 'standard',
            rate_multiplier: 1,
            is_exclusive: false,
          },
        ],
        supported_models: [
          {
            name: 'gpt-5.5',
            platform: 'openai',
            pricing: {
              billing_mode: 'token',
              input_price: 0.000005,
              output_price: 0.00003,
              cache_write_price: 0.0000025,
              cache_read_price: 0.0000005,
              image_output_price: null,
              per_request_price: null,
              intervals: [],
            },
          },
          {
            name: 'gpt-image-1',
            platform: 'openai',
            pricing: {
              billing_mode: 'image',
              input_price: null,
              output_price: null,
              cache_write_price: null,
              cache_read_price: null,
              image_output_price: 0.12,
              per_request_price: null,
              intervals: [],
            },
          },
        ],
      },
    ],
  },
]

describe('available channel marketplace helpers', () => {
  it('flattens channels into group-specific entries with effective pricing', () => {
    const entries = buildMarketplaceEntries(fixtureChannels, {
      11: 0.5,
    })

    expect(entries).toHaveLength(4)

    const vipGpt = entries.find(
      (entry) => entry.group.id === 11 && entry.modelName === 'gpt-5.5',
    )
    expect(vipGpt).toBeTruthy()
    expect(vipGpt?.hasCustomRate).toBe(true)
    expect(vipGpt?.effectiveRateMultiplier).toBe(0.5)
    expect(vipGpt?.baseRateMultiplier).toBe(0.8)
    expect(vipGpt?.basePricing?.input_price).toBe(0.000005)
    expect(vipGpt?.pricing?.input_price).toBe(0.0000025)
    expect(vipGpt?.pricing?.output_price).toBe(0.000015)
    expect(vipGpt?.pricing?.cache_read_price).toBe(0.00000025)

    const publicImage = entries.find(
      (entry) => entry.group.id === 12 && entry.modelName === 'gpt-image-1',
    )
    expect(publicImage?.pricing?.image_output_price).toBe(0.12)
  })

  it('filters by search text, platform, group and billing mode', () => {
    const entries = buildMarketplaceEntries(fixtureChannels, {})

    const filtered = filterMarketplaceEntries(entries, {
      query: 'vip',
      platforms: ['openai'],
      groupIds: [11],
      billingModes: ['token'],
    })

    expect(filtered).toHaveLength(1)
    expect(filtered[0].group.name).toBe('vip-openai')
    expect(filtered[0].modelName).toBe('gpt-5.5')
  })
})
