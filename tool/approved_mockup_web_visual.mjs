import { chromium } from 'playwright';
import { mkdirSync, statSync, writeFileSync } from 'node:fs';
import path from 'node:path';

const root = path.resolve('build/approved-mockup-qa');
mkdirSync(root, { recursive: true });
const log = [];
const browser = await chromium.launch({
  executablePath: '/usr/bin/google-chrome',
  args: ['--no-sandbox', '--disable-dev-shm-usage'],
  headless: true,
});
const context = await browser.newContext({
  viewport: { width: 430, height: 932 },
  isMobile: true,
  hasTouch: true,
  deviceScaleFactor: 1,
  locale: 'it-IT',
});
const page = await context.newPage();
page.on('pageerror', e => log.push('PAGE ERROR: ' + e.message));
page.on('console', m => {
  if (m.type() === 'error') log.push('CONSOLE ERROR: ' + m.text().slice(0, 250));
});
async function screenshot(name) {
  const dest = path.join(root, name + '.png');
  await page.screenshot({ path: dest });
  log.push('SCREEN ' + name + ' ' + statSync(dest).size + ' bytes');
}
async function semantics(name) {
  const a = await page.evaluate(() => Array.from(
    document.querySelectorAll('[role], [aria-label], flt-semantics-placeholder')
  ).slice(0, 500).map(el => ({
    tag: el.tagName, role: el.getAttribute('role'),
    aria: el.getAttribute('aria-label'),
    text: (el.textContent || '').trim().slice(0, 120),
  })));
  writeFileSync(path.join(root, name + '.json'), JSON.stringify(a, null, 2));
  return a;
}
async function click(label) {
  for (const locator of [
    page.getByRole('button', { name: label, exact: true }).first(),
    page.getByRole('tab', { name: label, exact: true }).first(),
    page.getByText(label, { exact: true }).first(),
    page.locator('flt-semantics[role="button"]').filter({hasText:label}).first(),
  ]) {
    try {
      if (!await locator.count()) continue;
      await locator.click({timeout:2200});
      await page.waitForTimeout(850);
      log.push('CLICK: ' + label);
      return true;
    } catch(e) {
      log.push('click locator fallback ' + label + ': ' + e.message.slice(0, 85));
    }
  }
  return false;
}
async function check(label, name) {
  const a = await semantics(name);
  const found = a.some(x => [x.aria, x.text].some(t => t?.includes(label)));
  log.push('SEMANTIC CHECK ' + label + ': ' + found);
  return found;
}
let ready = false;
let openedToday = false;
try {
  await page.goto('http://127.0.0.1:8765/', {
    waitUntil: 'domcontentloaded', timeout:60000
  });
  await page.waitForTimeout(11500);
  const placeholder = page.locator('flt-semantics-placeholder');
  if (await placeholder.count()) {
    try { await placeholder.first().evaluate(el => el.click()); }
    catch(e) {log.push('Semantics placeholder: '+e.message.slice(0,140));}
  }
  await page.waitForTimeout(2200);
  ready = !!(await page.locator('flutter-view, flt-glass-pane').count());
  await screenshot('01-launch');
  await semantics('01-launch');
  if (!(await click('Usa su questo dispositivo'))) {
    // Coordinate from stable 430x932 onboarding mockup; semantics fallback.
    await page.mouse.click(215, 520);
    await page.waitForTimeout(1500);
  }
  await screenshot('02-entry');
  for (const label of ['Salta','Avanti','Continua','Inizia','Completo','Conferma','OK']) {
    await click(label);
  }
  await click('Apri l’agenda');
  await page.waitForTimeout(1200);
  openedToday = (await check('Giorno precedente','03-today-semantics')) ||
    (await check('Giorno successivo','03-today-semantics-again'));
  await screenshot('03-today-r3');
  const prev = await click('Giorno precedente');
  if (prev) await screenshot('04-today-previous');
  const next = await click('Giorno successivo');
  if (next) await screenshot('05-today-next');
  log.push('TODAY ARROWS: ' + (prev && next));
  if (await click('Calendario')) {
    await screenshot('06-calendar-r4');
    if (await click('Timeline oraria')) {
      await screenshot('07-timeline-open');
      await semantics('07-timeline-open');
      const available = page.getByText(/Crea\s+appuntamento/i).first();
      if (await available.count()) {
        try {
          await available.scrollIntoViewIfNeeded();
          await available.click({timeout:6000});
          await page.waitForTimeout(900);
          await screenshot('08-appointment-prefilled');
          await semantics('08-appointment-prefilled');
          log.push('CALENDAR SLOT EDITOR OPEN: true');
          const titleField = page.locator('input[aria-label="Titolo"]').first();
          const saveButton = page.getByRole('button', { name: 'Salva', exact: true }).first();
          if (await titleField.count() && await saveButton.count()) {
            await titleField.fill('QA appuntamento 07 - mockup R4');
            await screenshot('09-event-draft-filled');
            await saveButton.scrollIntoViewIfNeeded();
            await saveButton.click({ timeout: 5000 });
            await page.waitForTimeout(1200);
            await screenshot('10-event-after-save');
            await semantics('10-event-after-save');
            const saved = await page.getByText(
              'QA appuntamento 07 - mockup R4', { exact: true }).count();
            log.push('CANONICAL EVENT SAVE IN CALENDAR: ' + saved);
            if (!saved) throw new Error(
              'The 07:00 appointment was not visible after explicit Save');
          } else {
            log.push('CANONICAL EVENT SAVE: title or save control was not accessible');
          }
        } catch(e) {
          log.push('CALENDAR SLOT EDITOR: ' + e.message.slice(0,200));
        }
      } else {
        log.push('CALENDAR SLOT EDITOR: slot action not exposed in DOM');
      }
    }
  } else {
    log.push('Calendar entry not accessible');
  }
} finally {
  writeFileSync(path.join(root,'RESULT.txt'),
    ['Source SHA: 863d12ed7b1b4b587567dbe153a77fb49844697b',
      'Actual tested browser: Flutter Web release, synthetic local profile',
      ...log].join('\n')+'\n');
  await context.close();
  await browser.close();
}
if (!ready || !openedToday) {
  throw new Error('Flutter Web/Oggi R3 flow could not be verified');
}
console.log(log.join('\n'));
