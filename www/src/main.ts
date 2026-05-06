import { createApp, h, type DefineComponent } from 'vue';
import { createInertiaApp } from '@inertiajs/vue3';
import { setupNativeAdapter } from './inertia-native-adapter';

// Must be called before createInertiaApp so the XHR shim is in place
// when Inertia makes its initial page request.
setupNativeAdapter();

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob<{ default: DefineComponent; }>('./pages/**/*.vue', {
      eager: true,
    });
    const mod = pages[`./pages/${name}.vue`];
    if (!mod) throw new Error(`[flutter_inertia] Page not found: ${name}`);
    return mod.default;
  },
  setup({ el, App, props, plugin }) {
    createApp({ render: () => h(App, props) })
      .use(plugin)
      .mount(el);
  },
});
