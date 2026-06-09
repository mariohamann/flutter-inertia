import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  root: __dirname,
  resolve: {
    alias: {
      '../../src/index': resolve(__dirname, '../../src/index.ts'),
    },
  },
});
