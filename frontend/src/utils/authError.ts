import { i18n } from '@/i18n'

interface APIErrorLike {
  status?: number
  message?: string
  response?: {
    data?: {
      detail?: string
      message?: string
    }
  }
}

function extractErrorMessage(error: unknown): string {
  const err = (error || {}) as APIErrorLike
  return err.response?.data?.detail || err.response?.data?.message || err.message || ''
}

export function buildAuthErrorMessage(
  error: unknown,
  options: {
    fallback: string
  }
): string {
  const { fallback } = options
  const err = (error || {}) as APIErrorLike

  if (err.status === 0) {
    return `${i18n.global.t('errors.networkError')}，当前未连接到后端服务。`
  }

  const message = extractErrorMessage(error)
  return message || fallback
}
