<template>
  <div class="auth-oauth-divider flex items-center gap-3">
    <div class="h-px flex-1 bg-slate-200"></div>
    <span class="text-xs font-medium uppercase tracking-[0.16em] text-slate-400">
      {{ label }}
    </span>
    <div class="h-px flex-1 bg-slate-200"></div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  label: string
}>()
</script>
