<template>
  <div class="relative min-h-screen overflow-hidden bg-[#f7f8ff] text-slate-900 dark:bg-dark-950 dark:text-white">
    <div class="pointer-events-none absolute inset-0 bg-mesh-gradient opacity-65"></div>
    <div class="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(122,63,254,0.12),transparent_24%),radial-gradient(circle_at_bottom_right,rgba(37,99,255,0.10),transparent_28%)]"></div>
    <div class="pointer-events-none absolute inset-0 opacity-70 [background-image:linear-gradient(rgba(129,140,248,0.05)_1px,transparent_1px),linear-gradient(90deg,rgba(129,140,248,0.05)_1px,transparent_1px)] [background-size:72px_72px]"></div>

    <div :class="wrapperClass">
      <div :class="contentClass">
        <slot />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    centered?: boolean
    maxWidth?: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '4xl' | '6xl' | 'full'
  }>(),
  {
    centered: false,
    maxWidth: 'xl'
  }
)

const maxWidthClasses = {
  sm: 'max-w-md',
  md: 'max-w-lg',
  lg: 'max-w-2xl',
  xl: 'max-w-4xl',
  '2xl': 'max-w-5xl',
  '4xl': 'max-w-7xl',
  '6xl': 'max-w-[1600px]',
  full: 'max-w-none'
} as const

const wrapperClass = computed(() => [
  'relative mx-auto w-full px-4 py-8 sm:px-6 lg:px-8',
  props.centered ? 'flex min-h-screen items-center justify-center' : ''
])

const contentClass = computed(() => [
  'w-full',
  maxWidthClasses[props.maxWidth],
  props.maxWidth === 'full' ? '' : 'mx-auto'
])
</script>
