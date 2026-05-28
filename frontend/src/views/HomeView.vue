<template>
  <div v-if="homeContent" class="min-h-screen">
    <iframe
      v-if="isHomeContentUrl"
      :src="homeContent.trim()"
      class="h-screen w-full border-0"
      allowfullscreen
    ></iframe>
    <div v-else v-html="homeContent"></div>
  </div>

  <div v-else class="relative min-h-screen overflow-hidden bg-[#f7f8ff] text-slate-900">
    <div class="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_12%_20%,rgba(139,92,246,0.18),transparent_24%),radial-gradient(circle_at_88%_88%,rgba(59,130,246,0.16),transparent_28%),linear-gradient(135deg,#f8f9ff_0%,#eef2ff_48%,#f9fbff_100%)]"></div>
    <div class="pointer-events-none absolute inset-0 opacity-70 [background-image:linear-gradient(rgba(129,140,248,0.045)_1px,transparent_1px),linear-gradient(90deg,rgba(129,140,248,0.045)_1px,transparent_1px)] [background-size:70px_70px]"></div>

    <header class="relative z-20 px-6 py-5">
      <nav class="mx-auto flex max-w-7xl items-center justify-between gap-4">
        <img src="/wordmark.png" alt="Nexora" class="h-20 w-auto max-w-[560px] object-contain sm:h-24" />

        <div class="flex items-center gap-3">
          <div class="home-action-pill">
            <LocaleSwitcher />
          </div>

          <a
            v-if="docUrl"
            :href="docUrl"
            target="_blank"
            rel="noopener noreferrer"
            class="home-icon-btn"
            :title="t('home.viewDocs')"
          >
            <Icon name="book" size="md" />
          </a>

          <router-link
            :to="isAuthenticated ? dashboardPath : '/login'"
            class="inline-flex min-h-12 items-center gap-2 rounded-full bg-gradient-primary px-5 py-3 text-sm font-bold text-white shadow-[0_20px_40px_rgba(79,70,229,0.24)]"
          >
            <span v-if="isAuthenticated" class="flex h-6 w-6 items-center justify-center rounded-full bg-white/16 text-xs">
              {{ userInitial }}
            </span>
            <span>{{ isAuthenticated ? homeDashboardLabel : homeLoginLabel }}</span>
          </router-link>
        </div>
      </nav>
    </header>

    <main class="relative z-10 px-6 pb-16 pt-6">
      <div class="mx-auto max-w-7xl">
        <section class="grid items-start gap-12 lg:grid-cols-[minmax(0,1.1fr)_minmax(360px,470px)] xl:gap-16">
          <div class="max-w-[820px] pt-4">
            <div class="inline-flex items-center gap-3 rounded-full border border-white/80 bg-white/72 px-6 py-3 text-base font-bold text-slate-900 shadow-[0_20px_44px_rgba(148,163,184,0.16)] backdrop-blur-xl">
              <span class="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-primary-50 via-white to-accent-50 ring-1 ring-primary-100">
                <img src="/logo.png" alt="" class="h-5 w-5 object-contain" />
              </span>
              <span class="tracking-tight">{{ siteName }} {{ localeWord }}</span>
            </div>

            <h1 class="mt-10 text-[56px] font-black leading-[0.94] tracking-tight text-slate-950 md:text-[72px] xl:text-[92px]">
              {{ siteName }}
            </h1>

            <p class="mt-4 max-w-[760px] text-2xl font-semibold leading-10 text-slate-700 md:text-3xl">
              {{ siteSubtitle }}
            </p>

            <p class="mt-8 max-w-[760px] text-xl leading-10 text-slate-600 md:text-2xl">
              {{ heroDescription }}
            </p>

            <div class="mt-8 flex flex-wrap items-center gap-x-5 gap-y-3 text-lg font-semibold text-primary-600">
              <span v-for="item in heroBullets" :key="item">{{ item }}</span>
            </div>

            <div class="mt-10 flex flex-wrap items-center gap-4">
              <router-link
                :to="isAuthenticated ? dashboardPath : '/login'"
                class="inline-flex items-center gap-2 rounded-full bg-gradient-primary px-7 py-4 text-base font-bold text-white shadow-[0_24px_44px_rgba(79,70,229,0.24)]"
              >
                {{ isAuthenticated ? homeDashboardLabel : homeLoginLabel }}
                <Icon name="arrowRight" size="md" class="text-white" :stroke-width="2" />
              </router-link>

              <a
                v-if="docUrl"
                :href="docUrl"
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white/76 px-6 py-4 text-base font-semibold text-slate-700 shadow-[0_16px_34px_rgba(148,163,184,0.16)] backdrop-blur-xl transition-colors hover:bg-white"
              >
                {{ docButtonLabel }}
              </a>
            </div>
          </div>

          <div class="relative pt-4">
            <div class="relative overflow-hidden rounded-[36px] border border-white/80 bg-white/78 p-6 shadow-[0_28px_90px_rgba(99,102,241,0.14)] backdrop-blur-2xl">
              <img src="/logo.png" alt="" class="pointer-events-none absolute right-[-36px] top-[86px] h-72 w-72 opacity-[0.07]" />

              <div class="rounded-[28px] border border-primary-100 bg-white/88 p-6">
                <div class="flex items-center justify-between gap-4">
                  <div>
                    <p class="text-sm font-semibold uppercase tracking-[0.24em] text-primary-500">
                      {{ platformEyebrow }}
                    </p>
                    <h2 class="mt-3 text-3xl font-black text-slate-950">
                      {{ platformTitle }}
                    </h2>
                  </div>
                  <div class="flex h-16 w-16 items-center justify-center rounded-3xl bg-gradient-to-br from-primary-50 via-white to-accent-50 ring-1 ring-primary-100">
                    <img src="/logo.png" alt="Nexora" class="h-10 w-10 object-contain" />
                  </div>
                </div>

                <div class="mt-8 grid gap-4">
                  <div
                    v-for="item in providerCards"
                    :key="item.name"
                    class="rounded-[24px] border border-slate-200/80 bg-[#f8faff] px-5 py-4 shadow-[inset_0_1px_0_rgba(255,255,255,0.8)]"
                  >
                    <div class="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-4">
                      <div class="flex min-w-0 items-center gap-4">
                        <div class="model-mark" :class="item.markClass">
                          <img
                            :src="item.icon"
                            :alt="item.name"
                            class="model-mark-image"
                            :class="item.imageClass"
                          />
                        </div>
                        <div class="min-w-0">
                          <p class="text-lg font-bold leading-6 text-slate-900">{{ item.name }}</p>
                          <p class="mt-1 text-sm leading-6 text-slate-500">{{ item.description }}</p>
                        </div>
                      </div>
                      <span class="self-center shrink-0 rounded-full bg-white px-3 py-1 text-xs font-bold text-primary-600 ring-1 ring-primary-100">
                        {{ item.badge }}
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              <div class="mt-6 grid gap-4 sm:grid-cols-3">
                <div v-for="metric in heroMetrics" :key="metric.label" class="rounded-[24px] border border-white/90 bg-white/72 px-5 py-5 text-center shadow-[0_18px_40px_rgba(148,163,184,0.14)]">
                  <p class="text-3xl font-black text-slate-950">{{ metric.value }}</p>
                  <p class="mt-2 text-sm font-medium text-slate-500">{{ metric.label }}</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="mt-16">
          <div class="grid gap-5 md:grid-cols-3">
            <article
              v-for="feature in featureCards"
              :key="feature.title"
              class="rounded-[30px] border border-white/80 bg-white/72 p-7 shadow-[0_22px_56px_rgba(148,163,184,0.14)] backdrop-blur-xl"
            >
              <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-primary shadow-[0_16px_34px_rgba(79,70,229,0.2)]">
                <Icon :name="feature.icon" size="lg" class="text-white" />
              </div>
              <h3 class="mt-6 text-2xl font-black text-slate-950">{{ feature.title }}</h3>
              <p class="mt-4 text-base leading-8 text-slate-600">{{ feature.description }}</p>
            </article>
          </div>
        </section>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuthStore, useAppStore } from '@/stores'
import LocaleSwitcher from '@/components/common/LocaleSwitcher.vue'
import Icon from '@/components/icons/Icon.vue'

const { t, locale } = useI18n()

const authStore = useAuthStore()
const appStore = useAppStore()

const isZh = computed(() => locale.value.toLowerCase().startsWith('zh'))
const siteName = computed(() => appStore.cachedPublicSettings?.site_name || appStore.siteName || 'Nexora')
const siteSubtitle = computed(() => appStore.cachedPublicSettings?.site_subtitle || t('auth.brandSubtitle'))
const docUrl = computed(() => appStore.cachedPublicSettings?.doc_url || appStore.docUrl || '')
const homeContent = computed(() => appStore.cachedPublicSettings?.home_content || '')

const isHomeContentUrl = computed(() => {
  const content = homeContent.value.trim()
  return content.startsWith('http://') || content.startsWith('https://')
})

const isAuthenticated = computed(() => authStore.isAuthenticated)
const isAdmin = computed(() => authStore.isAdmin)
const dashboardPath = computed(() => (isAdmin.value ? '/admin/dashboard' : '/dashboard'))
const userInitial = computed(() => {
  const user = authStore.user
  if (!user?.email) return ''
  return user.email.charAt(0).toUpperCase()
})

const localeWord = computed(() => (isZh.value ? '智能中转' : ''))
const heroDescription = computed(() => t('home.heroDescription'))
const heroBullets = computed(() =>
  isZh.value
    ? ['统一接口', '多模型聚合', '灵活计费', '稳定连接']
    : ['Unified API', 'Model aggregation', 'Flexible billing', 'Stable routing']
)
const platformEyebrow = computed(() => 'AI MODEL RELAY PLATFORM')
const platformTitle = computed(() => (isZh.value ? '统一中转，轻量接入' : 'Unified Relay, Lightweight Access'))
const homeLoginLabel = computed(() => (isZh.value ? '登录平台' : t('home.login')))
const homeDashboardLabel = computed(() => (isZh.value ? '进入控制台' : t('home.dashboard')))
const docButtonLabel = computed(() => (isZh.value ? '查看文档' : t('home.docs')))

const providerCards = computed(() =>
  isZh.value
    ? [
        {
          name: 'GPT-5.5',
          description: '统一协议接入与稳定计费管理。',
          badge: 'OpenAI',
          icon: '/model-icons/gpt-openai.png',
          markClass: 'model-mark-openai',
          imageClass: 'model-mark-image-openai'
        },
        {
          name: 'Claude',
          description: '多账号池与路由能力集中调度。',
          badge: 'Anthropic',
          icon: '/model-icons/claude.png',
          markClass: 'model-mark-claude',
          imageClass: 'model-mark-image-claude'
        },
        {
          name: 'Gemini',
          description: '接口聚合，按需切换与成本控制。',
          badge: 'Google',
          icon: '/model-icons/gemini.png',
          markClass: 'model-mark-gemini',
          imageClass: 'model-mark-image-gemini'
        }
      ]
    : [
        {
          name: 'GPT-5.5',
          description: 'Unified protocol access with stable billing control.',
          badge: 'OpenAI',
          icon: '/model-icons/gpt-openai.png',
          markClass: 'model-mark-openai',
          imageClass: 'model-mark-image-openai'
        },
        {
          name: 'Claude',
          description: 'Pool multiple accounts behind a single routing layer.',
          badge: 'Anthropic',
          icon: '/model-icons/claude.png',
          markClass: 'model-mark-claude',
          imageClass: 'model-mark-image-claude'
        },
        {
          name: 'Gemini',
          description: 'Aggregate endpoints and switch models on demand.',
          badge: 'Google',
          icon: '/model-icons/gemini.png',
          markClass: 'model-mark-gemini',
          imageClass: 'model-mark-image-gemini'
        }
      ]
)

const heroMetrics = computed(() =>
  isZh.value
    ? [
        { value: '1 Key', label: '统一入口' },
        { value: '4+', label: '主流模型' },
        { value: '24/7', label: '稳定调用' }
      ]
    : [
        { value: '1 Key', label: 'Unified entry' },
        { value: '4+', label: 'Model families' },
        { value: '24/7', label: 'Stable relay' }
      ]
)

const featureCards = computed(() =>
  isZh.value
    ? [
        {
          icon: 'server' as const,
          title: '统一接口',
          description: '面向 Claude、GPT、Gemini 等主流模型提供一致的调用入口，减少接入碎片化。'
        },
        {
          icon: 'users' as const,
          title: '多模型聚合',
          description: '通过账号池、分组与路由规则集中管理上游能力，避免每个平台都单独维护。'
        },
        {
          icon: 'creditCard' as const,
          title: '灵活计费',
          description: '把用量、余额、套餐和记录沉到同一平台里，让运营和调用策略更清晰。'
        }
      ]
    : [
        {
          icon: 'server' as const,
          title: 'Unified API',
          description: 'Expose Claude, GPT, Gemini and more through one consistent integration surface.'
        },
        {
          icon: 'users' as const,
          title: 'Model Aggregation',
          description: 'Manage upstream accounts, groups, and routing policies from a single control layer.'
        },
        {
          icon: 'creditCard' as const,
          title: 'Flexible Billing',
          description: 'Keep usage, balance, plans, and records in one platform with clearer operational control.'
        }
      ]
)

onMounted(() => {
  authStore.checkAuth()
  if (!appStore.publicSettingsLoaded) {
    appStore.fetchPublicSettings()
  }
})
</script>

<style scoped>
.home-action-pill :deep(button) {
  border-radius: 999px;
  border: 1px solid rgba(226, 232, 240, 0.95);
  background: rgba(255, 255, 255, 0.84);
  padding: 0.65rem 0.95rem;
  color: #334155;
  box-shadow: 0 16px 36px rgba(148, 163, 184, 0.14);
}

.home-icon-btn {
  display: inline-flex;
  height: 48px;
  width: 48px;
  align-items: center;
  justify-content: center;
  border-radius: 999px;
  border: 1px solid rgba(226, 232, 240, 0.95);
  background: rgba(255, 255, 255, 0.84);
  color: #475569;
  box-shadow: 0 16px 36px rgba(148, 163, 184, 0.14);
  transition: background-color 0.2s ease, color 0.2s ease;
}

.home-icon-btn:hover {
  background: rgba(255, 255, 255, 1);
  color: #1e293b;
}

.model-mark {
  flex-shrink: 0;
  display: flex;
  height: 3.75rem;
  width: 3.75rem;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  border-radius: 1.25rem;
  border: 1px solid rgba(203, 213, 225, 0.95);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.72),
    0 10px 24px rgba(148, 163, 184, 0.12);
}

.model-mark-openai {
  background:
    radial-gradient(circle at 30% 30%, rgba(255, 255, 255, 0.5), transparent 55%),
    linear-gradient(180deg, #d9f7eb 0%, #eefcf5 100%);
}

.model-mark-claude {
  background:
    radial-gradient(circle at 30% 30%, rgba(255, 255, 255, 0.5), transparent 55%),
    linear-gradient(180deg, #ffe8d7 0%, #fff5eb 100%);
}

.model-mark-gemini {
  background:
    radial-gradient(circle at 30% 30%, rgba(255, 255, 255, 0.52), transparent 55%),
    linear-gradient(180deg, #e2ebff 0%, #f2f7ff 100%);
}

.model-mark-image {
  display: block;
  object-fit: contain;
  filter: drop-shadow(0 4px 12px rgba(15, 23, 42, 0.12));
}

.model-mark-image-openai {
  height: 2.15rem;
  width: 2.15rem;
}

.model-mark-image-claude {
  height: 2.45rem;
  width: 2.45rem;
}

.model-mark-image-gemini {
  height: 2.3rem;
  width: 2.3rem;
}
</style>
