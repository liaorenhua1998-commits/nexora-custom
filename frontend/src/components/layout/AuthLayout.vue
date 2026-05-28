<template>
  <div class="relative min-h-screen overflow-hidden bg-[#f7f8ff] text-slate-900">
    <div class="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_14%_24%,rgba(129,100,255,0.20),transparent_28%),radial-gradient(circle_at_90%_90%,rgba(75,120,255,0.16),transparent_26%),linear-gradient(135deg,#f8f9ff_0%,#eef2ff_48%,#f9fbff_100%)]"></div>
    <div class="pointer-events-none absolute inset-0 opacity-70 [background-image:linear-gradient(rgba(129,140,248,0.05)_1px,transparent_1px),linear-gradient(90deg,rgba(129,140,248,0.05)_1px,transparent_1px)] [background-size:72px_72px]"></div>

    <div class="relative mx-auto grid min-h-screen w-full max-w-[1600px] lg:grid-cols-[minmax(0,1.2fr)_minmax(430px,540px)]">
      <section
        class="relative hidden overflow-hidden px-12 pb-16 pt-10 lg:flex lg:flex-col xl:px-20 xl:pt-12"
        :aria-label="heroEyebrow"
      >
        <div class="relative z-10 max-w-[760px]">
          <img
            :src="authBrandFull"
            :alt="siteName"
            class="h-auto w-full max-w-[500px] object-contain object-left xl:max-w-[560px]"
          />

          <p class="mt-6 max-w-[760px] text-[26px] font-semibold leading-10 text-slate-700">
            {{ siteSubtitle }}
          </p>

          <p class="mt-6 max-w-[760px] text-[22px] leading-10 text-slate-600">
            {{ heroDescription }}
          </p>

          <div class="mt-8 flex flex-wrap items-center gap-x-5 gap-y-3 text-lg font-semibold text-primary-600">
            <span v-for="item in heroBullets" :key="item">{{ item }}</span>
          </div>
        </div>

        <div class="relative mt-auto h-[300px] max-w-[780px]">
          <div class="pointer-events-none absolute inset-x-8 bottom-0 top-10 rounded-[42px] border border-primary-200/70 bg-white/45 shadow-[0_40px_100px_rgba(99,102,241,0.12)] backdrop-blur-2xl"></div>
          <div class="pointer-events-none absolute inset-x-[22%] bottom-8 top-28 rounded-[36px] border border-primary-200/60 bg-white/40 backdrop-blur-xl"></div>
          <img
            src="/logo.png"
            alt=""
            class="pointer-events-none absolute left-1/2 top-1/2 h-56 w-56 -translate-x-1/2 -translate-y-1/2 opacity-[0.14] blur-[1px]"
          />

          <div class="auth-chip left-8 top-14">GPT-5.5</div>
          <div class="auth-chip left-1/4 bottom-5">Gemini</div>
          <div class="auth-chip right-16 top-20">Claude</div>
          <div class="auth-chip right-8 bottom-14">{{ isZh ? '接口' : 'API' }}</div>
        </div>
      </section>

      <section class="relative flex items-center justify-center px-4 py-6 sm:px-6 lg:px-8 xl:px-10">
        <div class="w-full max-w-[540px]">
          <div class="overflow-hidden rounded-[34px] border border-white/70 bg-white/86 p-5 shadow-[0_30px_80px_rgba(99,102,241,0.16)] ring-1 ring-slate-200/70 backdrop-blur-2xl sm:p-8">
            <div class="mb-8 flex items-start justify-between gap-4 sm:items-center">
              <div class="min-w-0 flex-1">
                <img
                  :src="authBrandFull"
                  :alt="siteName"
                  class="h-auto w-full max-w-[280px] object-contain object-left sm:max-w-[320px]"
                />
              </div>

              <div class="auth-locale shrink-0">
                <LocaleSwitcher />
              </div>
            </div>

            <slot />

            <div v-if="$slots.footer" class="mt-8 text-center text-sm leading-6 text-slate-500">
              <slot name="footer" />
            </div>

            <div class="mt-6 text-center text-xs leading-6 text-slate-500">
              &copy; {{ currentYear }} {{ siteName }}. {{ footerCopy }}
            </div>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import LocaleSwitcher from '@/components/common/LocaleSwitcher.vue'
import authBrandFull from '@/assets/auth-brand-full.png'
import { useAppStore } from '@/stores'

const appStore = useAppStore()
const { t, locale } = useI18n()

const isZh = computed(() => locale.value.toLowerCase().startsWith('zh'))
const siteName = computed(() => appStore.cachedPublicSettings?.site_name || appStore.siteName || 'Nexora')
const siteSubtitle = computed(
  () => appStore.cachedPublicSettings?.site_subtitle || t('auth.brandSubtitle')
)
const currentYear = computed(() => new Date().getFullYear())

const heroEyebrow = computed(() =>
  isZh.value ? 'AI 模型网关与路由平台' : 'AI gateway and routing platform'
)
const heroDescription = computed(() => t('home.heroDescription'))
const heroBullets = computed(() =>
  isZh.value
    ? ['统一接口', '多模型路由', '灵活计费', '稳定交付']
    : ['Unified API', 'Multi-model routing', 'Flexible billing', 'Stable delivery']
)
const footerCopy = computed(() =>
  isZh.value ? '保留所有权利。' : t('home.footer.allRightsReserved')
)

onMounted(() => {
  appStore.fetchPublicSettings()
})
</script>

<style scoped>
.auth-chip {
  position: absolute;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 92px;
  height: 54px;
  padding: 0 22px;
  border-radius: 999px;
  border: 1px solid rgba(199, 210, 254, 0.9);
  background: rgba(255, 255, 255, 0.84);
  box-shadow: 0 18px 44px rgba(99, 102, 241, 0.12);
  color: #334155;
  font-size: 18px;
  font-weight: 700;
  backdrop-filter: blur(16px);
}

.auth-locale :deep(button) {
  border-radius: 20px;
  border: 1px solid rgba(226, 232, 240, 0.95);
  background: rgba(255, 255, 255, 0.95);
  padding: 0.85rem 1.15rem;
  color: #334155;
  font-size: 1.05rem;
  font-weight: 700;
  box-shadow: 0 16px 36px rgba(148, 163, 184, 0.18);
}

.auth-locale :deep(button:hover) {
  background: rgb(248 250 252);
}

.auth-locale :deep(.dark) button {
  background: rgba(255, 255, 255, 0.95);
  color: #334155;
}

:deep(.input-label) {
  display: inline-block;
  margin-bottom: 0.8rem;
  color: #334155;
  font-size: 1.05rem;
  font-weight: 700;
}

:deep(.input) {
  min-height: 4.8rem;
  border-radius: 1.6rem;
  border: 1px solid #d9e1f2;
  background: linear-gradient(180deg, rgba(244, 247, 255, 0.98) 0%, rgba(235, 241, 255, 0.94) 100%);
  color: #0f172a;
  font-size: 1.05rem;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.8);
}

:deep(.input::placeholder) {
  color: #94a3b8;
}

:deep(.input:focus) {
  border-color: rgba(99, 102, 241, 0.62);
  box-shadow: 0 0 0 4px rgba(129, 140, 248, 0.16);
}

:deep(.btn-primary) {
  min-height: 4.8rem;
  border: 0;
  border-radius: 1.7rem;
  background: linear-gradient(90deg, #7c3aed 0%, #5b5cf6 50%, #2563ff 100%);
  box-shadow: 0 22px 46px rgba(79, 70, 229, 0.28);
  font-size: 1.15rem;
  font-weight: 800;
}

:deep(.btn-primary:hover) {
  filter: brightness(1.03);
}

:deep(.input-hint) {
  margin-top: 0.55rem;
  color: #94a3b8;
  font-size: 0.85rem;
}
</style>
