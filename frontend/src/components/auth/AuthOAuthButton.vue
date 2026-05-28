<template>
  <div class="space-y-3">
    <button
      type="button"
      :disabled="disabled"
      class="auth-oauth-button btn btn-secondary w-full"
      @click="$emit('click')"
    >
      <span class="auth-oauth-icon-shell">
        <slot name="icon"></slot>
      </span>
      <span class="auth-oauth-label">{{ label }}</span>
    </button>

    <p v-if="hint" class="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm leading-6 text-amber-700">
      {{ hint }}
    </p>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  label: string
  disabled?: boolean
  hint?: string
}>()

defineEmits<{
  (e: 'click'): void
}>()
</script>
