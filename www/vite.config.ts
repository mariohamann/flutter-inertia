import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import { viteSingleFile } from 'vite-plugin-singlefile';
import { resolve } from 'path';

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue(), viteSingleFile()],
  build: {
    outDir: resolve(__dirname, '../assets/www'),
    emptyOutDir: true,
    // Needed for singlefile: no code splitting
    rollupOptions: {
      output: {
        inlineDynamicImports: true,
      },
    },
  },
});
