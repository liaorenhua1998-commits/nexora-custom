<template>
  <div class="card">
    <div class="border-b border-gray-100 px-6 py-4 dark:border-dark-700">
      <h2 class="text-lg font-semibold text-gray-900 dark:text-white">{{ t('dashboard.quickActions') }}</h2>
    </div>
    <div class="space-y-3 p-4">
      <button @click="router.push('/keys')" class="group flex w-full items-center gap-4 rounded-2xl border border-white/60 bg-white/55 p-4 text-left shadow-[0_14px_34px_rgba(15,23,42,0.05),inset_0_1px_0_rgba(255,255,255,0.45)] backdrop-blur-2xl transition-all duration-200 hover:-translate-y-0.5 hover:border-primary-200/70 hover:bg-white/70 dark:border-white/10 dark:bg-white/5 dark:hover:border-primary-400/20 dark:hover:bg-white/10">
        <div class="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-xl bg-primary-100 transition-transform group-hover:scale-105 dark:bg-primary-900/30">
          <Icon name="key" size="lg" class="text-primary-600 dark:text-primary-400" />
        </div>
        <div class="min-w-0 flex-1">
          <p class="text-sm font-medium text-gray-900 dark:text-white">{{ t('dashboard.createApiKey') }}</p>
          <p class="text-xs text-gray-500 dark:text-dark-400">{{ t('dashboard.generateNewKey') }}</p>
        </div>
        <Icon name="chevronRight" size="md" class="text-gray-400 transition-colors group-hover:text-primary-500 dark:text-dark-500" />
      </button>

      <button @click="router.push('/usage')" class="group flex w-full items-center gap-4 rounded-2xl border border-white/60 bg-white/55 p-4 text-left shadow-[0_14px_34px_rgba(15,23,42,0.05),inset_0_1px_0_rgba(255,255,255,0.45)] backdrop-blur-2xl transition-all duration-200 hover:-translate-y-0.5 hover:border-primary-200/70 hover:bg-white/70 dark:border-white/10 dark:bg-white/5 dark:hover:border-primary-400/20 dark:hover:bg-white/10">
        <div class="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-xl bg-accent-100 transition-transform group-hover:scale-105 dark:bg-accent-900/30">
          <Icon name="chart" size="lg" class="text-accent-600 dark:text-accent-400" />
        </div>
        <div class="min-w-0 flex-1">
          <p class="text-sm font-medium text-gray-900 dark:text-white">{{ t('dashboard.viewUsage') }}</p>
          <p class="text-xs text-gray-500 dark:text-dark-400">{{ t('dashboard.checkDetailedLogs') }}</p>
        </div>
        <Icon name="chevronRight" size="md" class="text-gray-400 transition-colors group-hover:text-accent-500 dark:text-dark-500" />
      </button>

      <button @click="router.push('/redeem')" class="group flex w-full items-center gap-4 rounded-2xl border border-white/60 bg-white/55 p-4 text-left shadow-[0_14px_34px_rgba(15,23,42,0.05),inset_0_1px_0_rgba(255,255,255,0.45)] backdrop-blur-2xl transition-all duration-200 hover:-translate-y-0.5 hover:border-primary-200/70 hover:bg-white/70 dark:border-white/10 dark:bg-white/5 dark:hover:border-primary-400/20 dark:hover:bg-white/10">
        <div class="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-xl bg-primary-100 transition-transform group-hover:scale-105 dark:bg-primary-900/30">
          <Icon name="gift" size="lg" class="text-primary-600 dark:text-primary-400" />
        </div>
        <div class="min-w-0 flex-1">
          <p class="text-sm font-medium text-gray-900 dark:text-white">{{ t('dashboard.redeemCode') }}</p>
          <p class="text-xs text-gray-500 dark:text-dark-400">{{ t('dashboard.addBalanceWithCode') }}</p>
        </div>
        <Icon name="chevronRight" size="md" class="text-gray-400 transition-colors group-hover:text-primary-500 dark:text-dark-500" />
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import Icon from '@/components/icons/Icon.vue'

const router = useRouter()
const { t } = useI18n()
</script>
