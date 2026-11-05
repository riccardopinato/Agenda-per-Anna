import { chromium } from 'playwright';
import { mkdirSync, statSync, writeFileSync } from 'node:fs';
import path from 'node:path';

const dir = path.resolve('build/cap0160-visual');
mkdirSync(dir, { recursive: true });
const log = [];
const browser = await chromium.launch({
  headless: true,
  executablePath: '/usr/bin/google-chrome',
  args: ['--no-sandbox', '--disable-dev-shm-usage'],
});
const context = await browser.newContext({
  viewport: { width: 430, height: 932 },
  deviceScaleFactor: 1,
  isMobile: true,
  hasTouch: true,
  locale: 'it-IT',
  recordVideo: { dir: path.join(dir, 'videos'), size: { width: 430, height: 932 } },
});
const page = await context.newPage();
page.on('pageerror', err => log.push('PAGE ERROR: ' + err.message));
page.on('console', msg => {
  if (msg.type() === 'error') log.push('CONSOLE: ' + msg.text().slice(0, 500));
});
async function capture(name) {
  const filename = path.join(dir, name + '.png');
  await page.screenshot({ path: filename, fullPage: true });
  log.push(name + ': screenshot=' + statSync(filename).size + ' bytes, url=' + page.url());
}
async function clickText(label) {
  const locator = page.getByText(label, { exact: true }).first();
  if (await locator.count()) {
    try {
      await locator.click({ timeout: 2500 });
      log.push('CLICKED TEXT: ' + label);
      await page.waitForTimeout(1000);
      return true;
    } catch (error) {
      log.push('CLICK FAILED: ' + label + ' :: ' + error.message.slice(0, 140));
    }
  }
  return false;
}
async function snapshotAccessibility(stage) {
  const raw = await page.evaluate(() => {
    const all = document.querySelectorAll('[role], [aria-label], button, flt-semantics-placeholder');
    return Array.from(all).slice(0, 400).map(el => ({
      tag: el.tagName,
      role: el.getAttribute('role'),
      label: el.getAttribute('aria-label'),
      text: (el.textContent || '').trim().slice(0, 90),
    }));
  });
  writeFileSync(path.join(dir, stage + '-accessibility.json'), JSON.stringify(raw, null, 2));
  log.push('ACCESSIBILITY NODES ' + stage + ': ' + raw.length);
}
let ready = false;
try {
  await page.goto('http://127.0.0.1:8765/', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(12000);
  const placeholder = page.locator('flt-semantics-placeholder');
  if (await placeholder.count()) {
    try {
      await placeholder.first().evaluate((element) => element.click());
      log.push('Requested Flutter accessibility programmatically');
    } catch (e) {
      log.push('Flutter accessibility placeholder inaccessible: ' + e.message.slice(0, 200));
    }
  }
  await page.waitForTimeout(2500);
  ready = !!(await page.locator('flutter-view, flt-glass-pane').count());
  log.push('Flutter engine surface detected: ' + ready);
  await capture('01-launch');
  await snapshotAccessibility('01-launch');

  let usedLocal = await clickText('Usa su questo dispositivo');
  if (!usedLocal) {
    // Coordinates grounded in the captured 430x932 entry-screen screenshot.
    await page.mouse.click(215, 520);
    log.push('TAPPED mobile local-only entry at x=215,y=520');
    await page.waitForTimeout(2500);
  }
  await capture('02-after-local-entry');
  await snapshotAccessibility('02-after-local-entry');
  for (const label of ['Salta', 'Avanti', 'Continua', 'Inizia', 'Completo', 'Conferma', 'OK']) {
    if (await clickText(label)) {
      await capture('02a-after-setup-step');
    }
  }
  await snapshotAccessibility('02-post-onboarding');
  for (const label of ['Altro','Esplora','Inbox']) {
    if (await clickText(label)) {
      await capture('03-open-' + label.toLowerCase());
      if (label === 'Inbox') break;
    }
  }
  await capture('04-current-screen');
  await snapshotAccessibility('04-current-screen');

  const captureRoute = await context.newPage();
  await captureRoute.goto('http://127.0.0.1:8765/?capture=1', { waitUntil: 'domcontentloaded', timeout: 45000 });
  await captureRoute.waitForTimeout(5000);
  await captureRoute.screenshot({ path: path.join(dir, '05-quick-capture-route.png') });
  log.push('Capture-route screenshot acquired');
  await captureRoute.close();
} finally {
  writeFileSync(path.join(dir, 'RESULT.txt'), log.join('\n') + '\n');
  await context.close();
  await browser.close();
}
if (!ready) {
  throw new Error('Flutter Web engine was not rendered');
}
console.log(log.join('\n'));
