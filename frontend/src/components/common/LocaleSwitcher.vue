<template>
  <div class="relative" ref="dropdownRef">
    <button
      @click="toggleDropdown"
      :disabled="switching"
      class="locale-trigger flex min-h-12 items-center gap-2 rounded-full px-4 py-2 text-sm font-semibold text-slate-700 transition-colors hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-70"
      :title="currentLocale?.name"
    >
      <span class="inline-flex min-w-8 items-center justify-center rounded-full bg-slate-100 px-2 py-1 text-xs font-bold text-slate-500">
        {{ currentLocale?.flag }}
      </span>
      <span class="whitespace-nowrap">{{ currentLocale?.name }}</span>
      <Icon
        name="chevronDown"
        size="xs"
        class="ml-1 text-slate-400 transition-transform duration-200"
        :class="{ 'rotate-180': isOpen }"
      />
    </button>

    <transition name="dropdown">
      <div
        v-if="isOpen"
        class="absolute right-0 z-50 mt-3 flex w-44 flex-col gap-2"
      >
        <button
          v-for="locale in availableLocales"
          :key="locale.code"
          :disabled="switching"
          @click="selectLocale(locale.code)"
          class="flex w-full items-center gap-3 rounded-full border border-slate-200 bg-white px-4 py-3 text-sm font-medium text-slate-700 shadow-[0_18px_34px_rgba(148,163,184,0.16)] transition-colors hover:bg-slate-50"
          :class="{
            'bg-primary-50 text-primary-600':
              locale.code === currentLocaleCode
          }"
        >
          <span class="inline-flex min-w-8 items-center justify-center rounded-full bg-slate-100 px-2 py-1 text-xs font-bold text-slate-500">
            {{ locale.flag }}
          </span>
          <span>{{ locale.name }}</span>
          <Icon v-if="locale.code === currentLocaleCode" name="check" size="sm" class="ml-auto text-primary-500" />
        </button>
      </div>
    </transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { useI18n } from 'vue-i18n'
import Icon from '@/components/icons/Icon.vue'
import { setLocale, availableLocales } from '@/i18n'

const { locale } = useI18n()

const isOpen = ref(false)
const dropdownRef = ref<HTMLElement | null>(null)
const switching = ref(false)

const currentLocaleCode = computed(() => locale.value)
const currentLocale = computed(() => availableLocales.find((l) => l.code === locale.value))

function toggleDropdown() {
  isOpen.value = !isOpen.value
}

async function selectLocale(code: string) {
  if (switching.value || code === currentLocaleCode.value) {
    isOpen.value = false
    return
  }
  switching.value = true
  try {
    await setLocale(code)
    isOpen.value = false
  } finally {
    switching.value = false
  }
}

function handleClickOutside(event: MouseEvent) {
  if (dropdownRef.value && !dropdownRef.value.contains(event.target as Node)) {
    isOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<style scoped>
.locale-trigger {
  background: transparent;
}

.dropdown-enter-active,
.dropdown-leave-active {
  transition: all 0.15s ease;
}

.dropdown-enter-from,
.dropdown-leave-to {
  opacity: 0;
  transform: scale(0.95) translateY(-4px);
}
</style>
