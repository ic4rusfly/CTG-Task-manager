/**
 * Headless smoke test for the clickable prototype.
 *
 * It loads prototype/index.html in jsdom, signs in and exercises the flows we
 * care about: navigation, notifications, message search, mentions, threads,
 * attachments, the three languages and the no-emoji rule.
 *
 *   cd tool && npm install     # one-off, pulls jsdom
 *   node tool/prototype_smoke.js
 */
const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

const ROOT = path.join(__dirname, '..', 'prototype');

const dom = new JSDOM(fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8'), {
  runScripts: 'outside-only',
  url: 'http://localhost/',
  pretendToBeVisual: true,
});
const w = dom.window;
w.matchMedia =
  w.matchMedia || (() => ({ matches: false, addEventListener() {}, addListener() {} }));
for (const file of ['i18n.js', 'data.js', 'app.js']) {
  w.eval(fs.readFileSync(path.join(ROOT, file), 'utf8'));
}

const doc = w.document;
const failures = [];
const ok = (condition, message) => {
  console.log(`${condition ? 'PASS' : 'FAIL'} ${message}`);
  if (!condition) failures.push(message);
};
const fire = (el) => el.dispatchEvent(new w.Event('click', { bubbles: true }));
/** Checkboxes in the prototype are driven by the change event. */
const toggle = (selector) => {
  const el = doc.querySelector(selector);
  if (!el) throw new Error(`missing element: ${selector}`);
  el.checked = !el.checked;
  el.dispatchEvent(new w.Event('change', { bubbles: true }));
};
const click = (selector) => {
  const el = doc.querySelector(selector);
  if (!el) throw new Error(`missing element: ${selector}`);
  fire(el);
};

// --------------------------------------------------------------- sign in ---
ok(!!doc.querySelector('.login-card'), 'the app starts on the sign-in screen');
ok(!doc.querySelector('.nav-item'), 'no shell before signing in');
doc.getElementById('login-email').value = 'nobody@ctg.ma';
click('[data-act="login"]');
ok(!!doc.querySelector('.login-card') && /login-error|maroon/.test(doc.body.innerHTML),
  'an unknown address shows an inline error');
doc.getElementById('login-email').value = 'yasmine@ctg.ma';
click('[data-act="login"]');
ok(!!doc.querySelector('.nav-item'), 'app shell renders after sign in');

// -------------------------------------------------------- notifications ----
const navIds = [...doc.querySelectorAll('.nav-item')].map((e) => e.dataset.id);
ok(navIds.includes('notifications'), `notification tab present (${navIds.join(', ')})`);
ok(!!doc.querySelector('.nav-item[data-id="notifications"] .badge'), 'unread badge shown');
click('.nav-item[data-id="notifications"]');
ok(doc.querySelectorAll('[data-act="open-notif"]').length >= 2, 'notification list rendered');
ok(!!doc.querySelector('[data-act="read-all"]'), 'mark all read offered');
click('[data-act="read-all"]');
ok(
  !doc.querySelector('.nav-item[data-id="notifications"] .badge'),
  'badge cleared after mark all read'
);

// --------------------------------------------------------------- search ----
click('.nav-item[data-id="chat"]');
const searchBox = doc.getElementById('msg-search');
ok(!!searchBox, 'message search box present');
searchBox.value = 'onboarding';
searchBox.dispatchEvent(new w.Event('input', { bubbles: true }));
const hits = doc.querySelectorAll('[data-act="open-hit"]');
ok(hits.length > 0, `search returns hits (${hits.length})`);
fire(hits[0]);
ok(!doc.getElementById('msg-search').value, 'search clears when a hit is opened');

// ------------------------------------------------------------- mentions ----
ok(!!doc.querySelector('[data-act="mention"]'), 'mention button in the composer');
click('[data-act="mention"]');
const candidates = doc.querySelectorAll('[data-act="pick-mention"]');
ok(candidates.length > 0, `mention picker lists members (${candidates.length})`);
fire(candidates[0]);
const composer = doc.getElementById('composer-input');
ok(/@\S+\s$/.test(composer.value), `mention token inserted (${composer.value.trim()})`);
composer.value += 'please review';
click('[data-act="send"]');
ok(
  [...doc.querySelectorAll('.msg')].some((b) => b.innerHTML.includes('color:var(--accent)')),
  'sent mention is highlighted'
);

// -------------------------------------------------------------- threads ----
click('[data-act="channel"][data-id="c_general"]');
const threadButtons = [...doc.querySelectorAll('[data-act="open-thread"]')];
ok(threadButtons.length > 0, `thread affordances rendered (${threadButtons.length})`);
fire(threadButtons.find((e) => e.dataset.id === 'm1'));
ok(!!doc.getElementById('thread-input'), 'thread panel opens');
ok(
  doc.querySelectorAll('.panel .msg').length === 3,
  `root plus two seeded replies (${doc.querySelectorAll('.panel .msg').length})`
);
doc.getElementById('thread-input').value = 'Noted, see you then.';
click('[data-act="send-reply"]');
ok(doc.querySelectorAll('.panel .msg').length === 4, 'reply is appended to the thread');
ok(
  ![...doc.querySelectorAll('.messages .msg')].some((e) =>
    e.textContent.includes('Noted, see you then')
  ),
  'replies stay out of the channel timeline'
);
click('[data-act="close-thread"]');
ok(!doc.getElementById('thread-input'), 'thread panel closes');

// ---------------------------------------------------------- attachments ----
const fileInput = doc.getElementById('file-input');
ok(!!fileInput, 'hidden file input is wired for real uploads');
let opened = false;
fileInput.click = () => {
  opened = true;
};
click('[data-act="attach"][data-id="image"]');
ok(opened, 'the image action opens the platform file picker');
ok(fileInput.accept === 'image/*', `picker filters on images (${fileInput.accept})`);

/** A 1x1 PNG, so the upload path handles real bytes. */
const pngBytes = Uint8Array.from(
  atob(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='
  ),
  (c) => c.charCodeAt(0)
);

async function uploadRun() {
  const file = new w.File([pngBytes], 'poster.png', { type: 'image/png' });
  Object.defineProperty(fileInput, 'files', { value: [file], configurable: true });
  fileInput.onchange();
  await new Promise((resolve) => w.setTimeout(resolve, 60));
  ok(!!doc.querySelector('.composer .progress'), 'a progress bar is shown while uploading');
  await new Promise((resolve) => w.setTimeout(resolve, 1200));
  const image = doc.querySelector('.messages img[src^="data:image/png"]');
  ok(!!image, 'the uploaded picture is posted and rendered');
  ok(
    doc.body.innerHTML.includes('poster.png'),
    'the attachment keeps its file name and size'
  );
}

uploadRun().then(() => {
  // ------------------------------------------------------ edit a message ----
  click('.nav-item[data-id="chat"]');
  click('[data-act="channel"][data-id="c_general"]');
  doc.getElementById('composer-input').value = 'Draft note';
  click('[data-act="send"]');
  const mine = [...doc.querySelectorAll('.msg.mine')].pop();
  fire(mine.querySelector('[data-act="edit-msg"]'));
  ok(!!doc.getElementById('edit-input'), 'the edit dialog opens on my own message');
  doc.getElementById('edit-input').value = 'Draft note, corrected';
  click('[data-act="save-edit"]');
  const editedBubble = [...doc.querySelectorAll('.msg.mine')].pop().textContent;
  ok(editedBubble.includes('corrected'), 'the message text is updated');
  const editedLabels = Object.values(w.I18N).map((table) => table.edited);
  ok(editedLabels.some((label) => editedBubble.includes(label)), 'the bubble is marked as edited');

  // ----------------------------------------------------- task attachments ---
  click('.nav-item[data-id="tasks"]');
  fire(doc.querySelector('[data-act="open-task"]'));
  ok(!!doc.querySelector('[data-act="task-attach"]'), 'a task can take attachments');
  let taskPickerOpened = false;
  fileInput.click = () => {
    taskPickerOpened = true;
  };
  click('[data-act="task-attach"]');
  ok(taskPickerOpened, 'the task attach action opens the file picker');

  // ------------------------------------------------------- mute and seen ----
  click('.nav-item[data-id="chat"]');
  click('[data-act="channel"][data-id="c_general"]');
  doc.getElementById('composer-input').value = 'Agenda for Thursday attached soon.';
  click('[data-act="send"]');
  const receipt = doc.querySelector('.messages .msg:last-child .body').textContent;
  const receiptLabels = Object.values(w.I18N).flatMap((table) => [table.sent, table.seen]);
  ok(
    receiptLabels.some((label) => receipt.includes(label)),
    `the last message I sent carries a read receipt (${receipt.trim().split('\n').pop().trim()})`
  );
  click('[data-act="toggle-mute"]');
  const mutedLabels = Object.values(w.I18N).map((table) => table.muted);
  ok(
    mutedLabels.includes(doc.querySelector('.chat-main .sub').textContent.trim()),
    'muting a conversation is reflected in the header'
  );
  ok(
    !!doc.querySelector('.conv .t svg'),
    'the conversation list marks the muted conversation'
  );
  click('[data-act="toggle-mute"]');
  ok(!doc.querySelector('.conv .t svg'), 'unmuting clears the marker');

  // ----------------------------------------------------------------- push ----
  click('.nav-item[data-id="settings"]');
  const pushToggle = doc.querySelector('[data-act="toggle-push"]');
  ok(!!pushToggle && pushToggle.checked, 'signing in registers the device for push');
  click('[data-act="test-push"]');
  ok(!!doc.querySelector('.toast'), 'a foreground notification shows an in-app banner');
  click('[data-act="open-toast"]');
  ok(!doc.querySelector('.toast'), 'opening the banner dismisses it');
  ok(doc.querySelector('.nav-item.active').dataset.id === 'notifications',
    'the banner routes to its target');
  click('.nav-item[data-id="settings"]');
  toggle('[data-act="toggle-push"]');
  ok(!doc.querySelector('[data-act="toggle-push"]').checked, 'push can be turned off');
  ok(!doc.querySelector('[data-act="test-push"]'), 'the test action disappears with push off');

  // --------------------------------------------------------- other views -----
  for (const view of ['tasks', 'agenda', 'members']) {
    click(`.nav-item[data-id="${view}"]`);
    ok(doc.getElementById('content').children.length > 0, `${view} view renders`);
  }

  // ------------------------------------------------------------ languages ----
  for (const lang of ['fr', 'ar', 'en']) {
    click('.nav-item[data-id="notifications"]');
    click(`[data-act="lang"][data-id="${lang}"]`);
    ok(
      !doc.body.innerHTML.includes('undefined{'),
      `${lang} renders without missing translations`
    );
  }

  // ---------------------------------------------------------- house rules ----
  ok(
    !/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/u.test(doc.body.innerHTML),
    'no emoji in the rendered DOM'
  );

  // ---------------------------------------------------------- sign out ------
  click('.nav-item[data-id="settings"]');
  click('[data-act="sign-out"]');
  ok(!!doc.querySelector('.login-card'), 'sign out returns to the sign-in screen');

  console.log(failures.length ? `\nFAILURES: ${failures.length}` : '\nALL PASS');
  process.exit(failures.length ? 1 : 0);
});
