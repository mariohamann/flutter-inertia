import { router } from '@inertiajs/core';
import { setupNativeAdapter } from '../../src/index';

// ── Mock Flutter bridge ─────────────────────────────────────────────────────
//
// Tests configure window.__mockBridge via page.evaluate() before visiting.
// Each entry in the queue is the NativeInertiaDetail that the bridge will
// dispatch as a CustomEvent in response to the next postMessage.

type BridgeResponse = {
  component?: string;
  props?: Record<string, unknown>;
  url?: string;
  version?: string;
  redirect?: string;
};

declare global {
  interface Window {
    __mockBridge: {
      queue: BridgeResponse[];
      received: { method: string; url: string; data: unknown; headers: unknown; }[];
    };
    nativeInertia?: { postMessage: (s: string) => void; };
    // Exposed so Playwright tests can trigger visits via page.evaluate()
    __visit: (url: string, options?: Record<string, unknown>) => void;
  }
}

window.__mockBridge = { queue: [], received: [] };

window.nativeInertia = {
  postMessage(json: string) {
    const msg = JSON.parse(json);
    window.__mockBridge.received.push(msg);
    const response = window.__mockBridge.queue.shift();
    if (response !== undefined) {
      // Use setTimeout to match real Flutter bridge async behavior.
      // postToFlutter() registers the listener AFTER calling postMessage, so a
      // synchronous dispatch would fire before the listener is attached.
      setTimeout(() => {
        window.dispatchEvent(new CustomEvent('nativeInertia', { detail: response }));
      }, 0);
    }
  },
};

// ── Adapter setup ────────────────────────────────────────────────────────────
setupNativeAdapter();

// ── Inertia init ─────────────────────────────────────────────────────────────
const output = document.getElementById('output')!;

router.init({
  initialPage: { component: 'Init', props: {}, url: '/', version: 'flutter' },
  resolveComponent: (name) => name,
  swapComponent: async ({ component, page }) => {
    output.textContent = JSON.stringify({ component, props: page.props });
  },
});

window.__visit = (url, options) => router.visit(url, options as Parameters<typeof router.visit>[1]);
