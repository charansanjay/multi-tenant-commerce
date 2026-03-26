import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
    include: ['src/**/*.test.{ts,tsx}'],
    exclude: ['e2e/**', 'node_modules/**'],
    coverage: {
      provider: 'v8',
      include: ['src/lib/**', 'src/stores/**'],
      exclude: [
        'src/lib/supabase/**',
        'src/types/**',
        'src/lib/constants.ts', // ← exclude constants — no logic to test
      ],
      reporter: ['text', 'lcov'],
      thresholds: {
        lines: 80,
        functions: 80,
      },
    },
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      '@platform/ui': resolve(__dirname, '../../packages/ui/src/index.ts'),
      '@platform/types': resolve(__dirname, '../../packages/types/src/index.ts'),
      '@platform/utils': resolve(__dirname, '../../packages/utils/src/index.ts'),
    },
  },
});
