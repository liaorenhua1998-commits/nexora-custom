import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import i18n, { initI18n } from './i18n'
import { useAppStore } from '@/stores/app'
import './style.css'

function initThemeClass() {
  const savedTheme = localStorage.getItem('theme')
  const shouldUseDark =
    savedTheme === 'dark' ||
    (!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)
  document.documentElement.classList.toggle('dark', shouldUseDark)
}

async function bootstrap() {
  // Apply theme class globally before app mount to keep all routes consistent.
  initThemeClass()

  const app = createApp(App)
  const pinia = createPinia()
  app.use(pinia)

  // Initialize settings from injected config BEFORE mounting (prevents flash)
  // This must happen after pinia is installed but before router and i18n
  const appStore = useAppStore()
  appStore.initFromInjectedConfig()

  // Set document title immediately after config is loaded.
  const initialSubtitle = appStore.cachedPublicSettings?.site_subtitle?.trim() || ''
  const initialTitle = initialSubtitle ? `${appStore.siteName} - ${initialSubtitle}` : appStore.siteName
  if (initialTitle.trim()) {
    document.title = initialTitle
  }

  await initI18n()

  app.use(router)
  app.use(i18n)

  // 绛夊緟璺敱鍣ㄥ畬鎴愬垵濮嬪鑸悗鍐嶆寕杞斤紝閬垮厤绔炴€佹潯浠跺鑷寸殑绌虹櫧娓叉煋
  await router.isReady()
  app.mount('#app')
}

bootstrap()


