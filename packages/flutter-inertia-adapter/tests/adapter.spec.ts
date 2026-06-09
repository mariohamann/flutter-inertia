import { test, expect } from '@playwright/test';

type BridgeResponse = {
  component?: string;
  props?: Record<string, unknown>;
  url?: string;
  version?: string;
  redirect?: string;
};

async function queueResponses(page: import('@playwright/test').Page, responses: BridgeResponse[]) {
  await page.evaluate((resps) => {
    window.__mockBridge.queue.push(...resps);
    window.__mockBridge.received = [];
  }, responses);
}

test.beforeEach(async ({ page }) => {
  await page.goto('/');
  await page.evaluate(() => {
    window.__mockBridge.queue = [];
    window.__mockBridge.received = [];
  });
});

test('basic navigation — bridge receives correct payload and component is rendered', async ({ page }) => {
  await queueResponses(page, [{ component: 'Notes/Index', props: { notes: [] }, url: '/notes', version: 'flutter' }]);

  await page.evaluate(() => window.__visit('/notes'));

  const output = page.getByTestId('output');
  await expect(output).toContainText('Notes/Index');

  const received = await page.evaluate(() => window.__mockBridge.received);
  expect(received[0]).toMatchObject({ method: 'get', url: '/notes' });
});

test('redirect — bridge first responds with redirect, adapter follows and renders final component', async ({ page }) => {
  await queueResponses(page, [
    { redirect: '/dashboard' },
    { component: 'Dashboard', props: { user: 'alice' }, url: '/dashboard', version: 'flutter' },
  ]);

  await page.evaluate(() => window.__visit('/old-path'));

  const output = page.getByTestId('output');
  await expect(output).toContainText('Dashboard');

  const received = await page.evaluate(() => window.__mockBridge.received);
  expect(received).toHaveLength(2);
  expect(received[1]).toMatchObject({ method: 'get', url: '/dashboard' });
});

test('toRoutePath — http URL strips to pathname', async ({ page }) => {
  await queueResponses(page, [{ component: 'Notes/Show', props: { id: 1 }, url: '/notes/1', version: 'flutter' }]);

  await page.evaluate(() => window.__visit('http://localhost/notes/1'));

  const output = page.getByTestId('output');
  await expect(output).toContainText('Notes/Show');

  const received = await page.evaluate(() => window.__mockBridge.received);
  expect(received[0].url).toBe('/notes/1');
});

test('toRoutePath — file:// URL strips to route path', async ({ page }) => {
  await queueResponses(page, [{ component: 'Notes/Show', props: {}, url: '/notes/1', version: 'flutter' }]);

  await page.evaluate(() =>
    window.__visit('file:///data/user/0/com.example.app/flutter_assets/assets/www/notes/1'),
  );

  const output = page.getByTestId('output');
  await expect(output).toContainText('Notes/Show');

  const received = await page.evaluate(() => window.__mockBridge.received);
  expect(received[0].url).toBe('/notes/1');
});

test('toRoutePath — file:// root (index.html) normalizes to /', async ({ page }) => {
  await queueResponses(page, [{ component: 'Home', props: {}, url: '/', version: 'flutter' }]);

  await page.evaluate(() =>
    window.__visit('file:///data/user/0/com.example.app/flutter_assets/assets/www/index.html'),
  );

  const output = page.getByTestId('output');
  await expect(output).toContainText('Home');

  const received = await page.evaluate(() => window.__mockBridge.received);
  expect(received[0].url).toBe('/');
});

test('missing nativeInertia channel — logs error, does not throw', async ({ page }) => {
  const errors: string[] = [];
  page.on('console', (msg) => { if (msg.type() === 'error') errors.push(msg.text()); });

  await page.evaluate(() => { delete window.nativeInertia; });
  await page.evaluate(() => window.__visit('/nowhere'));

  await page.waitForTimeout(200);

  expect(errors.some((e) => e.includes('nativeInertia'))).toBe(true);
});

test('POST with body — bridge receives correct method and data', async ({ page }) => {
  await queueResponses(page, [{ component: 'Notes/Show', props: { id: 99 }, url: '/notes/99', version: 'flutter' }]);

  await page.evaluate(() =>
    window.__visit('/notes', { method: 'post', data: { title: 'hello', body: 'world' } }),
  );

  const output = page.getByTestId('output');
  await expect(output).toContainText('Notes/Show');

  const received = await page.evaluate(() => window.__mockBridge.received);
  expect(received[0]).toMatchObject({ method: 'post', url: '/notes', data: { title: 'hello', body: 'world' } });
});
