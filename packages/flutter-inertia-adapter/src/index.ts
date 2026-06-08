/**
 * flutter-inertia-adapter
 *
 * Registers a custom Inertia v3 HttpClient that routes all navigation
 * requests through the Flutter JavaScriptChannel instead of making real
 * network requests.
 *
 * Call setupNativeAdapter() before createInertiaApp().
 *
 * Works with any Inertia framework adapter (Vue, React, Svelte, etc.).
 */

import { http } from '@inertiajs/core';
import type { HttpClient, HttpRequestConfig, HttpResponse } from '@inertiajs/core';

type NativeInertiaDetail = {
  component?: string;
  props?: Record<string, unknown>;
  url?: string;
  version?: string;
  redirect?: string;
};

/** Extract just the route path from a potentially absolute or file:// URL. */
function toRoutePath(url: string): string {
  try {
    const parsed = new URL(url);
    const pathname = parsed.pathname + parsed.search;
    // file:// URLs from Flutter assets contain the full filesystem path,
    // e.g. /…/flutter_assets/assets/www/notes/1
    // Strip everything up to and including /assets/www
    const marker = '/assets/www';
    const idx = pathname.indexOf(marker);
    if (idx !== -1) {
      const after = pathname.slice(idx + marker.length);
      if (!after || after === '/' || after === '/index.html') return '/';
      return after.startsWith('/') ? after : '/' + after;
    }
    return pathname;
  } catch {
    return url;
  }
}

function postToFlutter(config: HttpRequestConfig): void {
  const channel = (
    window as unknown as { nativeInertia?: { postMessage: (s: string) => void; }; }
  ).nativeInertia;
  if (!channel) {
    console.error('[flutter-inertia] nativeInertia JavaScriptChannel not found');
    return;
  }
  channel.postMessage(
    JSON.stringify({
      method: config.method ?? 'GET',
      url: toRoutePath(config.url),
      data: config.data ?? {},
      headers: config.headers ?? {},
    }),
  );
}

function awaitFlutterResponse(): Promise<NativeInertiaDetail> {
  return new Promise((resolve) => {
    window.addEventListener(
      'nativeInertia',
      (e: Event) => resolve((e as CustomEvent<NativeInertiaDetail>).detail),
      { once: true },
    );
  });
}

const flutterHttpClient: HttpClient = {
  async request(config: HttpRequestConfig): Promise<HttpResponse> {
    postToFlutter(config);
    let detail = await awaitFlutterResponse();

    // If Flutter returned a redirect, follow it transparently with a GET.
    if (detail.redirect) {
      postToFlutter({ ...config, method: 'get', url: detail.redirect, data: {} });
      detail = await awaitFlutterResponse();
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
    };
  },
};

export function setupNativeAdapter(): void {
  // Disable history API — pushState/replaceState are meaningless inside a
  // file:// WebView and cause errors on some platforms.
  history.pushState = () => { };
  history.replaceState = () => { };

  http.setClient(flutterHttpClient);
}
