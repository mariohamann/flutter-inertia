import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import { viteSingleFile } from 'vite-plugin-singlefile';
import { resolve } from 'path';

export default defineConfig({
  plugins: [vue(), viteSingleFile()],
  resolve: {
    alias: {
      // Resolve workspace package directly from source — no pre-build needed in dev.
      'flutter-inertia-adapter': resolve(__dirname, '../packages/flutter-inertia-adapter/src/index.ts'),
    },
  },
  build: {
    outDir: resolve(__dirname, '../assets/www'),
    emptyOutDir: true,
    rollupOptions: {
      output: { inlineDynamicImports: true },
    },
  },
});
