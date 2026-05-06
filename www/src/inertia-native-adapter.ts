/**
 * Flutter Inertia Native Adapter
 *
 * Registers a custom Inertia v3 HttpClient (via http.setClient) that routes
 * all navigation requests through the Flutter JavaScriptChannel instead of
 * making real network requests.
 *
 * Call setupNativeAdapter() before createInertiaApp().
 */

import { http } from '@inertiajs/core'
import type { HttpClient, HttpRequestConfig, HttpResponse } from '@inertiajs/core'

type NativeInertiaDetail = {
  component?: string
  props?: Record<string, unknown>
  url?: string
  version?: string
  redirect?: string
}

/** Extract just the route path from a potentially absolute or file:// URL. */
function toRoutePath(url: string): string {
  try {
    const parsed = new URL(url)
    const pathname = parsed.pathname + parsed.search
    // file:// URLs from Flutter assets contain the full filesystem path,
    // e.g. /…/flutter_assets/assets/www/notes/create
    // Strip everything up to and including /assets/www
    const marker = '/assets/www'
    const idx = pathname.indexOf(marker)
    if (idx !== -1) {
      const after = pathname.slice(idx + marker.length)
      // e.g. /index.html (the bootstrap load) → treat as root
      if (!after || after === '/' || after === '/index.html') return '/'
      return after.startsWith('/') ? after : '/' + after
    }
    return pathname
  } catch {
    return url
  }
}

function postToFlutter(config: HttpRequestConfig): void {
  const channel = (
    window as unknown as { nativeInertia?: { postMessage: (s: string) => void } }
  ).nativeInertia
  if (!channel) {
    console.error('[flutter_inertia] nativeInertia JavaScriptChannel not found')
    return
  }
  channel.postMessage(
    JSON.stringify({
      method: config.method ?? 'GET',
      url: toRoutePath(config.url),
      data: config.data ?? {},
      headers: config.headers ?? {},
    }),
  )
}

function awaitFlutterResponse(): Promise<NativeInertiaDetail> {
  return new Promise((resolve) => {
    window.addEventListener(
      'nativeInertia',
      (e: Event) => resolve((e as CustomEvent<NativeInertiaDetail>).detail),
      { once: true },
    )
  })
}

const flutterHttpClient: HttpClient = {
  async request(config: HttpRequestConfig): Promise<HttpResponse> {
    postToFlutter(config)
    let detail = await awaitFlutterResponse()

    // If Flutter returned a redirect, follow it transparently by making
    // a second GET request to the redirect target.
    if (detail.redirect) {
      postToFlutter({ ...config, method: 'get', url: detail.redirect, data: {} })
      detail = await awaitFlutterResponse()
    }

    return {
      status: 200,
      data: JSON.stringify({
        component: detail.component ?? '',
        props: detail.props ?? {},
        url: detail.url ?? config.url,
        version: detail.version ?? 'flutter',
      }),
      headers: {
        'x-inertia': 'true',
        'content-type': 'application/json',
      },
    }
  },
}

export function setupNativeAdapter(): void {
  // Disable history API – pushState/replaceState are meaningless (and blocked)
  // inside a file:// WebView. Inertia only uses them to update the URL bar.
  history.pushState = () => {}
  history.replaceState = () => {}

  http.setClient(flutterHttpClient)
}
