/* CTG Hub - clickable prototype.
   Mirrors the Flutter app in lib/: same data, same translations, same palette. */

// ----------------------------------------------------------------- helpers
const DB = window.DB;
const byId = (list, id) => list.find((x) => x.id === id);
const esc = (s) =>
  String(s ?? '').replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const state = {
  lang: 'en',
  theme: 'light',
  me: 'u1',
  view: 'chat',
  channel: 'c_general',
  taskOpen: null,
  boardView: true,
  onlyMine: false,
  query: '',
  day: new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate()),
  month: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
  modal: null,
  search: '',
};

function t(key, params) {
  const table = window.I18N[state.lang] || window.I18N.en;
  let s = table[key] ?? window.I18N.en[key] ?? key;
  if (s.indexOf('{count, plural') === 0 || s.indexOf('{count, plural') > -1) {
    s = plural(s, params && params.count);
  }
  if (params) {
    Object.keys(params).forEach((k) => {
      s = s.split('{' + k + '}').join(params[k]);
    });
  }
  return s;
}

function plural(raw, count) {
  const m = raw.match(/\{count,\s*plural,\s*(.*)\}\s*$/s);
  if (!m) return raw;
  const cases = {};
  const re = /(=\d+|zero|one|two|few|many|other)\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}/g;
  let match;
  while ((match = re.exec(m[1]))) cases[match[1]] = match[2];
  let pick = cases['=' + count];
  if (!pick) {
    if (state.lang === 'ar') {
      const mod = count % 100;
      pick = count === 0 ? cases.zero : count === 1 ? cases.one : count === 2 ? cases.two
        : mod >= 3 && mod <= 10 ? cases.few : mod >= 11 ? cases.many : cases.other;
    } else {
      pick = count === 1 ? cases.one : cases.other;
    }
  }
  return (pick || cases.other || raw).split('{count}').join(count);
}

const LOCALE_TAG = { en: 'en-GB', fr: 'fr-FR', ar: 'ar-MA' };
const fmtTime = (d) => new Intl.DateTimeFormat(LOCALE_TAG[state.lang], { hour: '2-digit', minute: '2-digit' }).format(d);
const fmtDay = (d) => new Intl.DateTimeFormat(LOCALE_TAG[state.lang], { day: 'numeric', month: 'long', year: 'numeric' }).format(d);
const fmtShort = (d) => new Intl.DateTimeFormat(LOCALE_TAG[state.lang], { day: 'numeric', month: 'short' }).format(d);
const fmtMonth = (d) => new Intl.DateTimeFormat(LOCALE_TAG[state.lang], { month: 'long', year: 'numeric' }).format(d);
const sameDay = (a, b) => a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();

function relative(date) {
  const mins = Math.floor((Date.now() - date.getTime()) / 60000);
  if (mins < 1) return t('justNow');
  if (mins < 60) return t('minutesAgo', { count: mins });
  if (mins < 60 * 24) return t('hoursAgo', { count: Math.floor(mins / 60) });
  if (mins < 60 * 24 * 7) return t('daysAgo', { count: Math.floor(mins / 1440) });
  return fmtShort(date);
}

// --------------------------------------------------------------- constants
const AVATAR_COLORS = ['#2e4a3a', '#3e6b52', '#6b4a32', '#6e2c2c', '#3a403c', '#4a5a50'];
const avatarColor = (id) => AVATAR_COLORS[[...id].reduce((a, c) => a + c.charCodeAt(0), 0) % AVATAR_COLORS.length];

const STATUS_COLOR = {
  backlog: '#6e7671', todo: '#3a403c', inProgress: '#2e4a3a',
  review: '#6b4a32', done: '#1f5132', blocked: '#6e2c2c',
};
const PRIORITY_COLOR = { low: '#6e7671', medium: '#3e6b52', high: '#6b4a32', urgent: '#6e2c2c' };
const BOARD = ['todo', 'inProgress', 'review', 'done'];
const REACTIONS = ['ack', 'agree', 'watching', 'blocker', 'done'];
const REACTION_KEY = { ack: 'reactionAck', agree: 'reactionAgree', watching: 'reactionWatching', blocker: 'reactionBlocker', done: 'reactionDone' };

const svg = (p, extra = '') =>
  `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"
    stroke-linecap="round" stroke-linejoin="round" ${extra}>${p}</svg>`;

const ICONS = {
  chat: svg('<path d="M21 11.5a8.4 8.4 0 0 1-9 8.4 8.4 8.4 0 0 1-3.8-.9L3 21l1.9-5.1A8.4 8.4 0 1 1 21 11.5z"/>'),
  tasks: svg('<path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>'),
  agenda: svg('<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>'),
  members: svg('<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/>'),
  admin: svg('<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>'),
  settings: svg('<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.6 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.6a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>'),
  send: svg('<path d="M22 2L11 13"/><path d="M22 2l-7 20-4-9-9-4 20-7z"/>'),
  image: svg('<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/>'),
  file: svg('<path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><path d="M13 2v7h7"/>'),
  audio: svg('<path d="M12 1a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/><path d="M19 10v1a7 7 0 0 1-14 0v-1M12 19v4"/>'),
  link: svg('<path d="M10 13a5 5 0 0 0 7.5.5l3-3a5 5 0 0 0-7-7l-1.7 1.7"/><path d="M14 11a5 5 0 0 0-7.5-.5l-3 3a5 5 0 0 0 7 7l1.7-1.7"/>'),
  taskref: svg('<path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>'),
  plus: svg('<path d="M12 5v14M5 12h14"/>'),
  left: svg('<path d="M15 18l-6-6 6-6"/>'),
  right: svg('<path d="M9 18l6-6-6-6"/>'),
  today: svg('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>'),
  search: svg('<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/>'),
  lock: svg('<rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>'),
  hash: svg('<path d="M4 9h16M4 15h16M10 3L8 21M16 3l-2 18"/>'),
  ack: svg('<path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.3a2 2 0 0 0 2-1.7l1.4-9A2 2 0 0 0 19.7 9H14z"/><path d="M7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"/>'),
  agree: svg('<path d="M20 6L9 17l-5-5"/>'),
  watching: svg('<path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z"/><circle cx="12" cy="12" r="3"/>'),
  blocker: svg('<circle cx="12" cy="12" r="10"/><path d="M4.9 4.9l14.2 14.2"/>'),
  done: svg('<path d="M22 11.1V12a10 10 0 1 1-5.9-9.1"/><path d="M22 4L12 14.1l-3-3"/>'),
  trash: svg('<path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>'),
  close: svg('<path d="M18 6L6 18M6 6l12 12"/>'),
  sun: svg('<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>'),
  moon: svg('<path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/>'),
  board: svg('<rect x="3" y="3" width="7" height="18" rx="1"/><rect x="14" y="3" width="7" height="11" rx="1"/>'),
  list: svg('<path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/>'),
  message: svg('<path d="M21 11.5a8.4 8.4 0 0 1-9 8.4 8.4 8.4 0 0 1-3.8-.9L3 21l1.9-5.1A8.4 8.4 0 1 1 21 11.5z"/>'),
  assign: svg('<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M19 8v6M22 11h-6"/>'),
  back: svg('<path d="M19 12H5M12 19l-7-7 7-7"/>'),
  bell: svg('<path d="M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/>'),
  at: svg('<circle cx="12" cy="12" r="4"/><path d="M16 8v5a3 3 0 0 0 6 0v-1a10 10 0 1 0-4 8"/>'),
  clock: svg('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>'),
  swap: svg('<path d="M17 2l4 4-4 4"/><path d="M3 6h18M7 22l-4-4 4-4"/><path d="M21 18H3"/>'),
  checkAll: svg('<path d="M1 12l5 5L17 6"/><path d="M12 17l1 1L23 7"/>'),
};

// ------------------------------------------------------------- data access
const me = () => byId(DB.users, state.me);
const userName = (id) => (byId(DB.users, id) || {}).name || id;
const myChannels = () =>
  DB.channels
    .filter((c) => c.members.includes(state.me))
    .map((c) => ({ ...c, last: lastMessage(c.id) }))
    .sort((a, b) => (b.last ? b.last.at : 0) - (a.last ? a.last.at : 0));
const channelMessages = (id) => DB.messages.filter((m) => m.ch === id).sort((a, b) => a.at - b.at);
const lastMessage = (id) => channelMessages(id).slice(-1)[0];
const unread = (c) => {
  const since = c.read[state.me];
  return channelMessages(c.id).filter((m) => m.from !== state.me && (!since || m.at > since)).length;
};
const channelTitle = (c) => {
  if (c.type !== 'dm') return '# ' + c.name;
  const peer = c.members.find((x) => x !== state.me) || state.me;
  return userName(peer);
};
const visibleTasks = () =>
  DB.tasks
    .filter((task) => (!state.onlyMine || task.assignees.includes(state.me)))
    .filter((task) => {
      const q = state.query.trim().toLowerCase();
      if (!q) return true;
      return (task.title + ' ' + task.key + ' ' + task.labels.join(' ')).toLowerCase().includes(q);
    });
const effectiveProgress = (task) => {
  if (task.status === 'done') return 100;
  if (task.checklist.length) return Math.round((task.checklist.filter((c) => c.done).length / task.checklist.length) * 100);
  return task.progress;
};
const isOverdue = (task) => task.status !== 'done' && task.due && task.due < new Date();
const canAssign = () => ['admin', 'lead'].includes(me().role);

const MENTION_RE = /@([\p{L}\p{N}._-]+)/gu;

/** Resolves "@name" tokens to member ids (first name or email handle). */
function parseMentions(text) {
  const ids = new Set();
  for (const match of text.matchAll(MENTION_RE)) {
    const token = match[1].toLowerCase();
    const user = DB.users.find(
      (u) => u.name.split(' ')[0].toLowerCase() === token || u.email.split('@')[0].toLowerCase() === token
    );
    if (user) ids.add(user.id);
  }
  return [...ids];
}

/** Escapes text and wraps recognised mentions in a highlight span. */
function withMentions(text) {
  let out = '';
  let cursor = 0;
  for (const match of text.matchAll(MENTION_RE)) {
    const token = match[1].toLowerCase();
    const user = DB.users.find(
      (u) => u.name.split(' ')[0].toLowerCase() === token || u.email.split('@')[0].toLowerCase() === token
    );
    if (!user) continue;
    out += esc(text.slice(cursor, match.index));
    out += `<b style="color:var(--accent)">${esc(match[0])}</b>`;
    cursor = match.index + match[0].length;
  }
  out += esc(text.slice(cursor));
  return out;
}

const myNotifications = () =>
  DB.notifications.filter((n) => n.uid === state.me).sort((a, b) => b.at - a.at);
const unreadNotifications = () => myNotifications().filter((n) => !n.read).length;

function notify(uid, kind, title, body, route) {
  if (uid === state.me) return;
  DB.notifications.push({ id: uid + Date.now() + Math.random(), uid, kind, title, body, route, read: false, at: new Date() });
}

// ------------------------------------------------------------ small pieces
function avatar(id, cls = '', presence = false) {
  const u = byId(DB.users, id);
  const initials = (u ? u.name : '?').split(' ').slice(0, 2).map((w) => w[0]).join('');
  return `<span class="avatar ${cls}" style="background:${avatarColor(id)}">${esc(initials)}
    ${presence ? `<i class="presence ${u && u.online ? 'on' : ''}"></i>` : ''}</span>`;
}

function stack(ids, max = 4) {
  const shown = ids.slice(0, max);
  const extra = ids.length - shown.length;
  return `<span class="stack">${shown.map((id) => avatar(id, 'sm')).join('')}
    ${extra > 0 ? `<span class="avatar sm" style="background:var(--grey)">+${extra}</span>` : ''}</span>`;
}

const chip = (label, color) =>
  `<span class="chip"${color ? ` style="color:${color};border-color:${color}55"` : ''}>${esc(label)}</span>`;

function progressBar(value) {
  const cls = value >= 100 ? 'done' : value < 50 ? 'low' : '';
  return `<div class="progress ${cls}"><div style="width:${value}%"></div></div>`;
}

// ------------------------------------------------------------------- shell
function render() {
  document.documentElement.dir = state.lang === 'ar' ? 'rtl' : 'ltr';
  document.documentElement.lang = state.lang;
  document.documentElement.dataset.theme = state.theme;

  const nav = [
    ['chat', 'chat'], ['tasks', 'tasks'], ['agenda', 'agenda'],
    ['notifications', 'bell'], ['members', 'members'],
  ];
  if (canAssign()) nav.push(['admin', 'admin']);
  nav.push(['settings', 'settings']);

  const totalUnread = myChannels().reduce((a, c) => a + unread(c), 0);

  document.getElementById('app').innerHTML = `
    <aside class="rail">
      <div class="brand">
        <span class="mark">CTG</span>
        <span class="col"><div class="name">${esc(t('appName'))}</div>
          <div class="sub">${esc(t('tagline').split(',')[0])}</div></span>
      </div>
      ${nav.map(([id, icon]) => `
        <button class="nav-item ${state.view === id ? 'active' : ''}" data-act="view" data-id="${id}">
          ${ICONS[icon]}<span class="label">${esc(id === 'notifications' ? t('notificationCenter') : t(id))}</span>
          ${id === 'chat' && totalUnread ? `<span class="badge">${totalUnread}</span>` : ''}
          ${id === 'notifications' && unreadNotifications() ? `<span class="badge">${unreadNotifications()}</span>` : ''}
        </button>`).join('')}
      <div class="spacer"></div>
      <button class="me-card" data-act="switch-user">
        ${avatar(state.me, '', true)}
        <span class="col"><div class="n">${esc(me().name)}</div>
          <div class="r">${esc(t('role' + me().role[0].toUpperCase() + me().role.slice(1)))}</div></span>
      </button>
    </aside>
    <section class="main">
      ${topbar()}
      <div class="content" id="content">${viewHtml()}</div>
    </section>
    ${state.taskOpen ? taskPanel(byId(DB.tasks, state.taskOpen)) : ''}
    ${state.modal ? state.modal() : ''}
  `;
  afterRender();
}

function topbar() {
  const titles = {
    chat: t('chat'), tasks: t('tasks'), agenda: t('agenda'),
    members: t('members'), admin: t('admin'), settings: t('settings'),
    notifications: t('notificationCenter'),
  };
  return `
    <header class="topbar">
      <h1>${esc(titles[state.view])}</h1>
      <div class="right">
        ${state.view === 'tasks' ? `
          <div class="seg">
            <button class="${state.boardView ? 'on' : ''}" data-act="board-view" data-id="1">${ICONS.board}</button>
            <button class="${!state.boardView ? 'on' : ''}" data-act="board-view" data-id="0">${ICONS.list}</button>
          </div>` : ''}
        <div class="seg">
          ${['en', 'fr', 'ar'].map((l) => `<button class="${state.lang === l ? 'on' : ''}" data-act="lang" data-id="${l}">${l.toUpperCase()}</button>`).join('')}
        </div>
        <button class="btn icon" data-act="theme" title="${esc(t('theme'))}">
          ${state.theme === 'light' ? ICONS.moon : ICONS.sun}
        </button>
      </div>
    </header>`;
}

function viewHtml() {
  switch (state.view) {
    case 'chat': return chatView();
    case 'tasks': return tasksView();
    case 'agenda': return agendaView();
    case 'notifications': return notificationsView();
    case 'members': return membersView();
    case 'admin': return adminView();
    default: return settingsView();
  }
}

// -------------------------------------------------------------------- chat
function chatView() {
  const channels = myChannels();
  const rooms = channels.filter((c) => c.type !== 'dm');
  const dms = channels.filter((c) => c.type === 'dm');
  const current = byId(DB.channels, state.channel) || channels[0];
  if (current) current.read[state.me] = new Date();

  const conv = (c) => {
    const u = unread(c);
    const peer = c.type === 'dm' ? c.members.find((x) => x !== state.me) : null;
    return `
      <button class="conv ${current && c.id === current.id ? 'active' : ''}" data-act="channel" data-id="${c.id}">
        ${peer ? avatar(peer, '', true) : `<span class="hash">${c.type === 'private' ? ICONS.lock : ICONS.hash}</span>`}
        <span class="grow">
          <div class="t">${esc(channelTitle(c))}</div>
          <div class="p">${esc(c.last ? (c.last.text || c.last.att?.name || t('attachments')) : c.topic)}</div>
        </span>
        <span class="meta">
          <div>${c.last ? esc(relative(c.last.at)) : ''}</div>
          ${u ? `<span class="unread">${u}</span>` : ''}
        </span>
      </button>`;
  };

  return `
    <div class="chat-wrap">
      <div class="chat-list">
        <div style="padding:10px 10px 2px">
          <input type="search" id="msg-search" placeholder="${esc(t('searchMessages'))}" value="${esc(state.search)}">
        </div>
        ${state.search.trim().length > 1 ? searchResults() : ''}
        <div class="section-title">${esc(t('channels'))}</div>
        ${rooms.map(conv).join('')}
        <div class="section-title">${esc(t('directMessages'))}</div>
        ${dms.map(conv).join('')}
      </div>
      <div class="chat-main">
        ${current ? chatMain(current) : `<div class="empty">${esc(t('channels'))}</div>`}
      </div>
    </div>`;
}

function searchResults() {
  const q = state.search.trim().toLowerCase();
  const mine = myChannels().map((c) => c.id);
  const hits = DB.messages
    .filter((m) => mine.includes(m.ch))
    .filter((m) => ((m.text || '') + ' ' + (m.att ? m.att.name : '')).toLowerCase().includes(q))
    .sort((a, b) => b.at - a.at);

  return `
    <div class="section-title">${esc(t('resultsCount', { count: hits.length }))}</div>
    ${hits.length ? hits.map((m) => {
      const c = byId(DB.channels, m.ch);
      return `<button class="conv" data-act="open-hit" data-id="${m.id}">
        ${avatar(m.from, 'sm')}
        <span class="grow">
          <div class="t">${esc(userName(m.from))} <span class="muted small">${esc(t('inChannel', { channel: channelTitle(c) }))}</span></div>
          <div class="p">${esc(m.text || (m.att ? m.att.name : ''))}</div>
        </span>
        <span class="meta">${esc(relative(m.at))}</span>
      </button>`;
    }).join('') : `<div class="small muted" style="padding:6px 12px">${esc(t('noResults'))}</div>`}`;
}

function chatMain(c) {
  const msgs = channelMessages(c.id);
  const peer = c.type === 'dm' ? byId(DB.users, c.members.find((x) => x !== state.me)) : null;
  let lastDay = null;
  const rows = msgs.map((m) => {
    let sep = '';
    if (!lastDay || !sameDay(lastDay, m.at)) {
      lastDay = m.at;
      const label = sameDay(m.at, new Date()) ? t('today')
        : sameDay(m.at, new Date(Date.now() - 86400000)) ? t('yesterday') : fmtDay(m.at);
      sep = `<div class="day-sep">${esc(label)}</div>`;
    }
    return sep + messageHtml(m);
  }).join('');

  return `
    <div class="topbar" style="border-top:0">
      <div>
        <h1>${esc(channelTitle(c))}</h1>
        <div class="sub">${esc(peer ? (peer.online ? t('online') : t('offline')) : (c.topic || t('membersCount', { count: c.members.length })))}</div>
      </div>
      <div class="right">${stack(c.members)}</div>
    </div>
    <div class="messages" id="messages">${rows || `<div class="empty">${esc(t('messageHint'))}</div>`}</div>
    <div class="composer">
      <div class="tools">
        <button class="btn small ghost" data-act="attach" data-id="image">${ICONS.image}${esc(t('attachImage'))}</button>
        <button class="btn small ghost" data-act="attach" data-id="file">${ICONS.file}${esc(t('attachFile'))}</button>
        <button class="btn small ghost" data-act="attach" data-id="audio">${ICONS.audio}${esc(t('attachAudio'))}</button>
        <button class="btn small ghost" data-act="attach" data-id="link">${ICONS.link}${esc(t('attachLink'))}</button>
        <button class="btn small ghost" data-act="attach" data-id="taskRef">${ICONS.taskref}${esc(t('linkTask'))}</button>
        <button class="btn small ghost" data-act="mention">${ICONS.at}${esc(t('mentionSomeone'))}</button>
      </div>
      <div class="line">
        <input type="text" id="composer-input" placeholder="${esc(t('messageHint'))}" autocomplete="off">
        <button class="btn primary" data-act="send">${ICONS.send}${esc(t('send'))}</button>
      </div>
    </div>`;
}

function messageHtml(m) {
  const mine = m.from === state.me;
  let body = '';
  if (m.type === 'image') {
    body = `<div style="width:320px;height:190px;border-radius:8px;background:
      linear-gradient(135deg, var(--surface-2), var(--grey-light));display:grid;place-items:center;color:var(--text-dim)">
      ${ICONS.image}</div><div class="small muted" style="margin-top:4px">${esc(m.att.name)} - ${esc(m.att.size)}</div>`;
  } else if (m.type === 'file') {
    body = `<div class="attach">${ICONS.file}<span><b>${esc(m.att.name)}</b><br><span class="small muted">${esc(m.att.size)}</span></span></div>`;
  } else if (m.type === 'audio') {
    body = `<div class="attach">${ICONS.audio}<span class="grow"><b>${esc(m.att.name)}</b>
      <div class="progress" style="margin-top:6px"><div style="width:0"></div></div></span>
      <span class="small muted">${esc(m.att.duration || '')}</span></div>`;
  } else if (m.type === 'link') {
    body = `<div class="link-preview"><div>${esc(m.text)}</div>
      <div class="small" style="color:var(--accent)">${esc(m.url)}</div></div>`;
  } else if (m.type === 'taskRef') {
    const task = byId(DB.tasks, m.taskId);
    body = task ? `<div class="task-ref" data-act="open-task" data-id="${task.id}">
      <div class="key">${esc(task.key)}</div>
      <div style="font-weight:600;margin:3px 0 7px">${esc(task.title)}</div>
      ${progressBar(effectiveProgress(task))}
      <div class="small muted" style="margin-top:5px">${effectiveProgress(task)}%</div></div>` : '';
  }
  const mentionsMe = (parseMentions(m.text || '')).includes(state.me);
  const text = m.text && m.type !== 'link'
    ? `<div style="margin-top:${body ? '6px' : '0'};${mentionsMe
        ? 'background:var(--surface-2);border-radius:6px;padding:3px 6px' : ''}">${withMentions(m.text)}</div>`
    : '';

  const reactions = Object.keys(m.reactions || {}).map((code) => {
    const on = m.reactions[code].includes(state.me);
    return `<button class="reaction ${on ? 'on' : ''}" data-act="react" data-id="${m.id}" data-code="${code}">
      ${ICONS[code] || ICONS.done}${m.reactions[code].length}</button>`;
  }).join('');

  const picker = REACTIONS.map((code) =>
    `<button class="btn icon small ghost" title="${esc(t(REACTION_KEY[code]))}"
      data-act="react" data-id="${m.id}" data-code="${code}">${ICONS[code]}</button>`).join('');

  return `
    <div class="msg ${mine ? 'mine' : ''}">
      ${avatar(m.from)}
      <div class="body grow">
        <div class="head"><span class="who">${esc(userName(m.from))}</span>
          <span class="when">${esc(fmtTime(m.at))}</span></div>
        <div class="bubble">${body}${text}</div>
        <div class="reactions">${reactions}</div>
      </div>
      <div class="msg-actions">${picker}
        ${mine ? `<button class="btn icon small ghost" data-act="del-msg" data-id="${m.id}"
          title="${esc(t('deleteMessage'))}">${ICONS.trash}</button>` : ''}</div>
    </div>`;
}

// ------------------------------------------------------------------- tasks
function tasksView() {
  const tasks = visibleTasks();
  const controls = `
    <div class="row" style="padding:14px 16px 0;gap:10px">
      <div class="grow" style="max-width:320px"><input type="search" id="task-search"
        placeholder="${esc(t('searchTasks'))}" value="${esc(state.query)}"></div>
      <button class="chip select ${state.onlyMine ? 'on' : ''}" data-act="only-mine">${esc(t('myTasks'))}</button>
      <div class="grow"></div>
      ${canAssign() ? `<button class="btn primary" data-act="new-task">${ICONS.plus}${esc(t('newTask'))}</button>` : ''}
    </div>`;

  if (!state.boardView) {
    return controls + `<div class="pad tasklist">
      ${tasks.length ? tasks.map(taskCard).join('') : `<div class="empty">${esc(t('noTasks'))}</div>`}</div>`;
  }

  return controls + `
    <div class="board">
      ${BOARD.map((status) => {
        const items = tasks.filter((task) => task.status === status);
        return `<div class="column" data-drop="${status}">
          <h3><span class="chip" style="color:${STATUS_COLOR[status]};border-color:${STATUS_COLOR[status]}55">
            <i class="dot"></i>${esc(t('status' + status[0].toUpperCase() + status.slice(1)))}</span>
            <span class="count">${items.length}</span></h3>
          ${items.map(taskCard).join('')}
          ${items.length ? '' : `<div class="small muted" style="text-align:center;padding:18px 0">${esc(t('noTasks'))}</div>`}
        </div>`;
      }).join('')}
    </div>`;
}

function taskCard(task) {
  const p = effectiveProgress(task);
  return `
    <div class="card task" draggable="true" data-task="${task.id}" data-act="open-task" data-id="${task.id}">
      <div class="row">
        <span class="key">${esc(task.key)}</span>
        <div class="grow"></div>
        ${chip(t('priority' + task.priority[0].toUpperCase() + task.priority.slice(1)), PRIORITY_COLOR[task.priority])}
      </div>
      <div class="title">${esc(task.title)}</div>
      ${task.labels.length ? `<div class="wrap" style="margin-bottom:9px">${task.labels.map((l) => chip(l)).join('')}</div>` : ''}
      ${progressBar(p)}
      <div class="row" style="margin-top:9px">
        ${stack(task.assignees)}
        <div class="grow"></div>
        ${task.checklist.length ? `<span class="small muted">${task.checklist.filter((c) => c.done).length}/${task.checklist.length}</span>` : ''}
        ${task.due ? `<span class="chip" style="${isOverdue(task) ? 'color:#6e2c2c;border-color:#6e2c2c55' : ''}">${esc(fmtShort(task.due))}</span>` : ''}
      </div>
    </div>`;
}

function taskPanel(task) {
  if (!task) return '';
  const p = effectiveProgress(task);
  const statuses = ['backlog', 'todo', 'inProgress', 'review', 'done', 'blocked'];
  return `
    <div class="overlay" data-act="close-panel">
      <div class="panel" data-stop="1">
        <div class="panel-head">
          <button class="btn icon ghost" data-act="close-panel">${ICONS.close}</button>
          <b>${esc(task.key)}</b>
          <div class="grow"></div>
          ${me().role === 'admin' ? `<button class="btn small" data-act="del-task" data-id="${task.id}">${ICONS.trash}${esc(t('delete'))}</button>` : ''}
        </div>
        <div class="pad">
          <h2 style="margin:0 0 12px">${esc(task.title)}</h2>
          <div class="wrap">
            ${chip(t('status' + task.status[0].toUpperCase() + task.status.slice(1)), STATUS_COLOR[task.status])}
            ${chip(t('priority' + task.priority[0].toUpperCase() + task.priority.slice(1)), PRIORITY_COLOR[task.priority])}
            ${chip(t('type' + task.type[0].toUpperCase() + task.type.slice(1)))}
            ${task.due ? chip(fmtDay(task.due), isOverdue(task) ? '#6e2c2c' : null) : ''}
            ${task.group ? chip(t('assignToGroup'), '#6b4a32') : ''}
          </div>
          ${task.description ? `<p class="muted">${esc(task.description)}</p>` : ''}

          <div class="sep"></div>
          <div class="row"><b>${esc(t('progress'))}</b><div class="grow"></div><span>${p}%</span></div>
          <input class="slider" type="range" min="0" max="100" step="5" value="${p}"
            data-act="progress" data-id="${task.id}" ${task.checklist.length ? 'disabled' : ''}>
          ${task.checklist.length ? `<div class="small muted">${esc(t('checklist'))} - ${task.checklist.filter((c) => c.done).length}/${task.checklist.length}</div>` : ''}

          <div class="section-title">${esc(t('status'))}</div>
          <div class="wrap">
            ${statuses.map((s) => `<button class="chip select ${task.status === s ? 'on' : ''}"
              data-act="set-status" data-id="${task.id}" data-code="${s}">
              ${esc(t('status' + s[0].toUpperCase() + s.slice(1)))}</button>`).join('')}
          </div>

          <div class="section-title">${esc(t('assignees'))}</div>
          <div class="wrap">${task.assignees.map((id) =>
            `<span class="chip">${avatar(id, 'sm')} ${esc(userName(id))}</span>`).join('') || '-'}</div>
          <div class="section-title">${esc(t('reporter'))}</div>
          <div class="wrap"><span class="chip">${avatar(task.reporter, 'sm')} ${esc(userName(task.reporter))}</span></div>

          ${task.checklist.length ? `
            <div class="section-title">${esc(t('checklist'))}</div>
            ${task.checklist.map((c) => `<label class="row" style="padding:5px 0">
              <input type="checkbox" ${c.done ? 'checked' : ''} data-act="check" data-id="${task.id}" data-code="${c.id}">
              <span style="${c.done ? 'text-decoration:line-through;color:var(--text-dim)' : ''}">${esc(c.text)}</span>
            </label>`).join('')}` : ''}

          <div class="section-title">${esc(t('comments'))}</div>
          ${task.comments.map((c) => `
            <div class="row" style="align-items:flex-start;margin-bottom:10px">
              ${avatar(c.by, 'sm')}
              <div class="grow"><div class="small"><b>${esc(userName(c.by))}</b>
                <span class="muted"> ${esc(relative(c.at))}</span></div>
                <div>${esc(c.text)}</div></div>
            </div>`).join('') || `<div class="small muted">-</div>`}
          <div class="row" style="margin-top:10px">
            <input type="text" id="comment-input" placeholder="${esc(t('addComment'))}">
            <button class="btn primary" data-act="add-comment" data-id="${task.id}">${ICONS.send}</button>
          </div>
        </div>
      </div>
    </div>`;
}

// ------------------------------------------------------------------ agenda
function agendaView() {
  const first = new Date(state.month.getFullYear(), state.month.getMonth(), 1);
  const days = new Date(state.month.getFullYear(), state.month.getMonth() + 1, 0).getDate();
  const leading = (first.getDay() + 6) % 7;
  const cells = [];
  for (let i = 0; i < leading; i++) cells.push(null);
  for (let d = 1; d <= days; d++) cells.push(new Date(state.month.getFullYear(), state.month.getMonth(), d));

  const dow = [...Array(7)].map((_, i) =>
    new Intl.DateTimeFormat(LOCALE_TAG[state.lang], { weekday: 'short' })
      .format(new Date(2024, 0, 1 + i)));

  const dayEvents = DB.events
    .filter((e) => sameDay(e.start, state.day) || (e.start <= state.day && e.end >= state.day))
    .sort((a, b) => a.start - b.start);
  const dayTasks = DB.tasks.filter((task) => task.due && sameDay(task.due, state.day));

  return `
    <div class="pad">
      <div class="row" style="margin-bottom:12px">
        <b>${esc(fmtMonth(state.month))}</b>
        <div class="grow"></div>
        <button class="btn icon" data-act="month" data-id="-1">${ICONS.left}</button>
        <button class="btn icon" data-act="month" data-id="0">${ICONS.today}</button>
        <button class="btn icon" data-act="month" data-id="1">${ICONS.right}</button>
        <button class="btn primary" data-act="new-event">${ICONS.plus}${esc(t('newEvent'))}</button>
      </div>
      <div class="cal">
        ${dow.map((d) => `<div class="dow">${esc(d)}</div>`).join('')}
        ${cells.map((d) => {
          if (!d) return '<div class="cell blank"></div>';
          const dots = DB.events.filter((e) => sameDay(e.start, d)).slice(0, 3);
          const cls = [sameDay(d, state.day) ? 'sel' : '', sameDay(d, new Date()) ? 'today' : ''].join(' ');
          return `<div class="cell ${cls}" data-act="day" data-id="${d.toISOString()}">
            <div>${d.getDate()}</div>
            <div class="dots">${dots.map((e) => `<i style="background:${sameDay(d, state.day) ? 'var(--on-accent)' : e.color}"></i>`).join('')}</div>
          </div>`;
        }).join('')}
      </div>

      <div class="section-title">${esc(fmtDay(state.day))}</div>
      ${dayEvents.length || dayTasks.length ? '' : `<div class="empty">${esc(t('noEvents'))}</div>`}
      ${dayEvents.map((e) => `
        <div class="card event" style="margin-bottom:10px">
          <div class="bar" style="background:${e.color}"></div>
          <div class="grow">
            <div class="row"><b>${esc(e.title)}</b><div class="grow"></div>${stack(e.attendees)}</div>
            <div class="small muted">${e.allDay ? esc(t('allDay'))
              : esc(fmtTime(e.start) + ' - ' + fmtTime(e.end))}${e.location ? ' - ' + esc(e.location) : ''}</div>
            ${e.description ? `<div class="small" style="margin-top:6px">${esc(e.description)}</div>` : ''}
            <div class="wrap" style="margin-top:9px">
              ${['going', 'maybe', 'no'].map((r) => `<button class="chip select ${e.rsvp[state.me] === r ? 'on' : ''}"
                data-act="rsvp" data-id="${e.id}" data-code="${r}">
                ${esc(t(r === 'going' ? 'going' : r === 'maybe' ? 'maybe' : 'declined'))}</button>`).join('')}
            </div>
          </div>
        </div>`).join('')}
      ${dayTasks.map((task) => `
        <div class="card row" style="margin-bottom:10px;cursor:pointer" data-act="open-task" data-id="${task.id}">
          ${ICONS.tasks}<span class="grow">${esc(task.key)} - ${esc(task.title)}</span>
          ${chip(t('dueDate'))}
        </div>`).join('')}
    </div>`;
}

// ----------------------------------------------------------- notifications
const NOTIF_ICON = { mention: 'at', message: 'chat', taskAssigned: 'assign', taskStatus: 'swap', dueSoon: 'clock', eventInvite: 'agenda' };
const NOTIF_COLOR = { mention: 'var(--chocolate)', taskAssigned: 'var(--green)', dueSoon: 'var(--maroon)' };

function notificationsView() {
  const items = myNotifications();
  const unread = unreadNotifications();
  return `
    <div class="pad" style="max-width:760px">
      <div class="row" style="margin-bottom:12px">
        <span class="small muted">${esc(t('unreadCount', { count: unread }))}</span>
        <div class="grow"></div>
        ${unread ? `<button class="btn small" data-act="read-all">${ICONS.checkAll}${esc(t('markAllRead'))}</button>` : ''}
      </div>
      ${items.length ? items.map((n) => {
        const color = NOTIF_COLOR[n.kind] || 'var(--grey)';
        return `<div class="card row" style="align-items:flex-start;margin-bottom:9px;cursor:pointer;
            ${n.read ? '' : `border-color:${color}`}" data-act="open-notif" data-id="${n.id}">
          <span style="width:32px;height:32px;border-radius:8px;display:grid;place-items:center;
            color:${color};background:var(--surface-2);flex:none">${ICONS[NOTIF_ICON[n.kind]] || ICONS.bell}</span>
          <span class="grow">
            <div style="font-weight:${n.read ? 500 : 700}">${esc(n.title)}</div>
            <div class="small muted">${esc(n.body)}</div>
          </span>
          <span class="small muted">${esc(relative(n.at))}</span>
        </div>`;
      }).join('') : `<div class="empty">${esc(t('noNotifications'))}</div>`}
    </div>`;
}

// ----------------------------------------------------------------- members
function membersView() {
  return `
    <div class="pad">
      <div style="max-width:340px;margin-bottom:14px">
        <input type="search" id="member-search" placeholder="${esc(t('searchMembers'))}" value="${esc(state.query)}">
      </div>
      ${DB.teams.map((team) => {
        const members = DB.users.filter((u) => u.team === team.id &&
          (u.name + u.title + u.skills.join(' ')).toLowerCase().includes(state.query.toLowerCase()));
        if (!members.length) return '';
        return `<div class="section-title">${esc(team.name)} - ${esc(t('membersCount', { count: team.members.length }))}</div>
          <div class="grid-cards">${members.map(memberCard).join('')}</div>`;
      }).join('')}
    </div>`;
}

function memberCard(u) {
  return `
    <div class="card">
      <div class="row">
        ${avatar(u.id, 'lg', true)}
        <div class="grow">
          <div class="row"><b>${esc(u.name)}</b>
            ${u.role !== 'member' ? chip(t('role' + u.role[0].toUpperCase() + u.role.slice(1)), '#2e4a3a') : ''}</div>
          <div class="small muted">${esc(u.title)}</div>
          <div class="wrap" style="margin-top:7px">${u.skills.map((s) => chip(s)).join('')}</div>
        </div>
      </div>
      <div class="row" style="margin-top:11px">
        <button class="btn small" data-act="dm" data-id="${u.id}">${ICONS.message}${esc(t('message'))}</button>
        ${canAssign() ? `<button class="btn small" data-act="new-task" data-id="${u.id}">${ICONS.assign}${esc(t('assignTask'))}</button>` : ''}
      </div>
    </div>`;
}

// ------------------------------------------------------------------- admin
function adminView() {
  if (!canAssign()) return `<div class="empty">${esc(t('adminOnly'))}</div>`;
  const open = DB.tasks.filter((task) => task.status !== 'done').length;
  const overdue = DB.tasks.filter(isOverdue).length;
  const isAdmin = me().role === 'admin';

  return `
    <div class="pad">
      <div class="metrics">
        <div class="card metric"><div class="v">${DB.users.filter((u) => u.active).length}</div><div class="l">${esc(t('members'))}</div></div>
        <div class="card metric"><div class="v">${open}</div><div class="l">${esc(t('overviewOpenTasks'))}</div></div>
        <div class="card metric"><div class="v">${overdue}</div><div class="l">${esc(t('overdue'))}</div></div>
        <div class="card metric"><div class="v">${DB.channels.length}</div><div class="l">${esc(t('channels'))}</div></div>
      </div>

      <div class="section-title">${esc(t('team'))}</div>
      ${DB.teams.map((team) => `
        <div class="card row" style="margin-bottom:10px">
          <span class="chip" style="color:${team.color};border-color:${team.color}55"><i class="dot"></i>${esc(team.name)}</span>
          <span class="grow small muted">${esc(t('membersCount', { count: team.members.length }))}</span>
          <button class="btn small" data-act="new-task" data-team="${team.id}">${ICONS.assign}${esc(t('assignToGroup'))}</button>
        </div>`).join('')}

      <div class="section-title">${esc(t('manageMembers'))}</div>
      <div class="card">
        <table class="members">
          ${DB.users.map((u) => `
            <tr>
              <td style="width:42px">${avatar(u.id, '', true)}</td>
              <td><b>${esc(u.name)}</b><div class="small muted">${esc(u.title)}</div></td>
              <td style="width:150px">
                <select data-act="role" data-id="${u.id}" ${isAdmin ? '' : 'disabled'}>
                  ${['member', 'lead', 'admin'].map((r) => `<option value="${r}" ${u.role === r ? 'selected' : ''}>
                    ${esc(t('role' + r[0].toUpperCase() + r.slice(1)))}</option>`).join('')}
                </select>
              </td>
              <td style="width:120px" class="small">
                <label class="row"><input type="checkbox" ${u.active ? 'checked' : ''}
                  data-act="active" data-id="${u.id}" ${isAdmin ? '' : 'disabled'}>
                  ${esc(u.active ? t('activate') : t('deactivate'))}</label>
              </td>
            </tr>`).join('')}
        </table>
      </div>
    </div>`;
}

// ---------------------------------------------------------------- settings
function settingsView() {
  return `
    <div class="pad" style="max-width:620px">
      <div class="banner">${esc(t('demoSignInHint'))}</div>

      <div class="section-title">${esc(t('language'))}</div>
      <div class="card">
        ${[['en', 'English'], ['fr', 'Français'], ['ar', 'العربية']].map(([code, label]) => `
          <label class="row" style="padding:7px 0">
            <input type="radio" name="lang" ${state.lang === code ? 'checked' : ''} data-act="lang" data-id="${code}">
            <span class="grow">${esc(label)}</span>
            <span class="small muted">${code === 'ar' ? 'RTL' : 'LTR'}</span>
          </label>`).join('')}
      </div>

      <div class="section-title">${esc(t('theme'))}</div>
      <div class="card">
        ${[['light', t('themeLight')], ['dark', t('themeDark')]].map(([code, label]) => `
          <label class="row" style="padding:7px 0">
            <input type="radio" name="theme" ${state.theme === code ? 'checked' : ''} data-act="theme-set" data-id="${code}">
            <span>${esc(label)}</span>
          </label>`).join('')}
      </div>

      <div class="section-title">${esc(t('account'))}</div>
      <div class="card">
        <div class="row">
          ${avatar(state.me, 'lg', true)}
          <div class="grow">
            <b>${esc(me().name)}</b>
            <div class="small muted">${esc(me().email)} - ${esc(t('role' + me().role[0].toUpperCase() + me().role.slice(1)))}</div>
          </div>
          <button class="btn" data-act="switch-user">${esc(t('signIn'))}</button>
        </div>
      </div>
    </div>`;
}

// ------------------------------------------------------------------ modals
function userModal() {
  return modalShell(t('demoSignInHint'), `
    ${DB.users.map((u) => `
      <button class="card row" style="width:100%;margin-bottom:8px;text-align:start;cursor:pointer"
        data-act="pick-user" data-id="${u.id}">
        ${avatar(u.id, '', true)}
        <span class="grow"><b>${esc(u.name)}</b><div class="small muted">${esc(u.title)} -
          ${esc(t('role' + u.role[0].toUpperCase() + u.role.slice(1)))}</div></span>
      </button>`).join('')}`, '');
}

let draft = {};

function taskModal() {
  const people = DB.users;
  return modalShell(t('newTask'), `
    <label class="field"><span>${esc(t('taskTitle'))}</span>
      <input type="text" id="nt-title" value="${esc(draft.title || '')}"></label>
    <label class="field"><span>${esc(t('description'))}</span>
      <textarea id="nt-desc">${esc(draft.description || '')}</textarea></label>
    <label class="field"><span>${esc(t('dueDate'))}</span>
      <input type="date" id="nt-due" value="${draft.due || ''}"></label>

    <div class="field"><span class="small muted">${esc(t('priority'))}</span>
      <div class="wrap" style="margin-top:5px">
        ${['low', 'medium', 'high', 'urgent'].map((p) => `<button class="chip select ${(draft.priority || 'medium') === p ? 'on' : ''}"
          data-act="draft" data-key="priority" data-id="${p}">${esc(t('priority' + p[0].toUpperCase() + p.slice(1)))}</button>`).join('')}
      </div></div>

    <div class="field"><span class="small muted">${esc(t('type'))}</span>
      <div class="wrap" style="margin-top:5px">
        ${['task', 'bug', 'feature'].map((p) => `<button class="chip select ${(draft.type || 'task') === p ? 'on' : ''}"
          data-act="draft" data-key="type" data-id="${p}">${esc(t('type' + p[0].toUpperCase() + p.slice(1)))}</button>`).join('')}
      </div></div>

    <div class="field"><span class="small muted">${esc(t('selectTeam'))}</span>
      <div class="wrap" style="margin-top:5px">
        ${DB.teams.map((team) => `<button class="chip select ${draft.team === team.id ? 'on' : ''}"
          data-act="draft-team" data-id="${team.id}">${esc(team.name)}</button>`).join('')}
      </div></div>

    <div class="field"><span class="small muted">${esc(t('selectPeople'))}</span>
      <div class="wrap" style="margin-top:5px">
        ${people.map((u) => `<button class="chip select ${(draft.assignees || []).includes(u.id) ? 'on' : ''}"
          data-act="draft-person" data-id="${u.id}">${avatar(u.id, 'sm')} ${esc(u.name.split(' ')[0])}</button>`).join('')}
      </div></div>

    ${(draft.assignees || []).length > 1 ? `
      <div class="field"><span class="small muted">${esc(t('assignMode'))}</span>
        <div class="seg" style="margin-top:5px">
          <button class="${!draft.clone ? 'on' : ''}" data-act="draft" data-key="clone" data-id="">${esc(t('sharedTask'))}</button>
          <button class="${draft.clone ? 'on' : ''}" data-act="draft" data-key="clone" data-id="1">${esc(t('oneTaskEach'))}</button>
        </div></div>` : ''}
  `, `<button class="btn" data-act="close-modal">${esc(t('cancel'))}</button>
      <button class="btn primary" data-act="create-task">${esc(t('assign'))}</button>`);
}

function eventModal() {
  const iso = (d) => new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 10);
  return modalShell(t('newEvent'), `
    <label class="field"><span>${esc(t('eventTitle'))}</span>
      <input type="text" id="ne-title" value="${esc(draft.title || '')}"></label>
    <label class="field"><span>${esc(t('location'))}</span>
      <input type="text" id="ne-loc" value="${esc(draft.location || '')}"></label>
    <div class="row">
      <label class="field grow"><span>${esc(t('startsAt'))}</span>
        <input type="date" id="ne-date" value="${draft.date || iso(state.day)}"></label>
      <label class="field grow"><span>${esc(t('startsAt'))}</span>
        <input type="time" id="ne-start" value="${draft.start || '10:00'}"></label>
      <label class="field grow"><span>${esc(t('endsAt'))}</span>
        <input type="time" id="ne-end" value="${draft.end || '11:00'}"></label>
    </div>
    <label class="row" style="margin-bottom:12px">
      <input type="checkbox" id="ne-allday" ${draft.allDay ? 'checked' : ''}> ${esc(t('allDay'))}</label>
    <div class="field"><span class="small muted">${esc(t('attendees'))}</span>
      <div class="wrap" style="margin-top:5px">
        ${DB.users.map((u) => `<button class="chip select ${(draft.attendees || []).includes(u.id) ? 'on' : ''}"
          data-act="draft-attendee" data-id="${u.id}">${avatar(u.id, 'sm')} ${esc(u.name.split(' ')[0])}</button>`).join('')}
      </div></div>
  `, `<button class="btn" data-act="close-modal">${esc(t('cancel'))}</button>
      <button class="btn primary" data-act="create-event">${esc(t('create'))}</button>`);
}

function taskPickerModal() {
  return modalShell(t('linkTask'),
    DB.tasks.map((task) => `<button class="card row" style="width:100%;margin-bottom:8px;cursor:pointer;text-align:start"
      data-act="pick-task" data-id="${task.id}">
      <span class="key">${esc(task.key)}</span><span class="grow">${esc(task.title)}</span></button>`).join(''),
    `<button class="btn" data-act="close-modal">${esc(t('close'))}</button>`);
}

function modalShell(title, body, foot) {
  return `<div class="modal-wrap" data-act="close-modal">
    <div class="modal" data-stop="1">
      <div class="modal-head">${esc(title)}</div>
      <div class="modal-body">${body}</div>
      ${foot ? `<div class="modal-foot">${foot}</div>` : ''}
    </div></div>`;
}

// ----------------------------------------------------------------- actions
const uid = (p) => p + Math.random().toString(36).slice(2, 8);

function sendMessage(type, payload) {
  const input = document.getElementById('composer-input');
  const text = payload && payload.text !== undefined ? payload.text : (input ? input.value.trim() : '');
  if (!text && !payload) return;
  DB.messages.push({
    id: uid('m'), ch: state.channel, from: state.me, at: new Date(),
    type: type || 'text', text, reactions: {}, ...(payload || {}),
  });
  // Mentions notify the people named, in their own language (like the
  // Cloud Functions do in production).
  for (const target of parseMentions(text || '')) {
    const lang = byId(DB.users, target).locale;
    const copy = (window.I18N[lang] || window.I18N.en).mentionedYou.split('{name}').join(userName(state.me));
    notify(target, 'mention', copy, text, { view: 'chat', channel: state.channel });
  }
  render();
  const box = document.getElementById('messages');
  if (box) box.scrollTop = box.scrollHeight;
}

function handle(act, el) {
  const id = el.dataset.id;
  const code = el.dataset.code;
  switch (act) {
    case 'view': state.view = id; state.query = ''; break;
    case 'lang': state.lang = id; break;
    case 'theme': state.theme = state.theme === 'light' ? 'dark' : 'light'; break;
    case 'theme-set': state.theme = id; break;
    case 'switch-user': state.modal = userModal; break;
    case 'pick-user':
      state.me = id;
      state.lang = byId(DB.users, id).locale;
      state.modal = null;
      if (state.view === 'admin' && !canAssign()) state.view = 'chat';
      break;
    case 'channel': state.channel = id; break;
    case 'send': sendMessage('text'); return;
    case 'attach':
      if (id === 'image') sendMessage('image', { text: '', att: { name: 'photo.jpg', mime: 'image/jpeg', size: '480 KB' } });
      else if (id === 'file') sendMessage('file', { text: '', att: { name: 'ctg-document.pdf', mime: 'application/pdf', size: '182 KB' } });
      else if (id === 'audio') sendMessage('audio', { text: '', att: { name: 'voice-note.m4a', mime: 'audio/mp4', size: '320 KB', duration: '0:34' } });
      else if (id === 'link') sendMessage('link', { text: 'CTG website', url: 'https://ctg.ma' });
      else state.modal = taskPickerModal;
      break;
    case 'pick-task':
      state.modal = null;
      sendMessage('taskRef', { text: '', taskId: id });
      return;
    case 'react': {
      const m = byId(DB.messages, id);
      const list = (m.reactions[code] = m.reactions[code] || []);
      const i = list.indexOf(state.me);
      i === -1 ? list.push(state.me) : list.splice(i, 1);
      if (!list.length) delete m.reactions[code];
      break;
    }
    case 'del-msg': {
      const i = DB.messages.findIndex((m) => m.id === id);
      if (i > -1) DB.messages.splice(i, 1);
      break;
    }
    case 'dm': {
      let c = DB.channels.find((x) => x.type === 'dm' && x.members.length === 2 &&
        x.members.includes(state.me) && x.members.includes(id));
      if (!c) {
        c = { id: uid('c'), name: '', type: 'dm', members: [state.me, id], read: {} };
        DB.channels.push(c);
      }
      state.channel = c.id;
      state.view = 'chat';
      break;
    }
    case 'board-view': state.boardView = id === '1'; break;
    case 'only-mine': state.onlyMine = !state.onlyMine; break;
    case 'open-task': state.taskOpen = id; break;
    case 'close-panel': state.taskOpen = null; break;
    case 'set-status': {
      const task = byId(DB.tasks, id);
      task.status = code;
      if (code === 'done') task.progress = 100;
      break;
    }
    case 'check': {
      const task = byId(DB.tasks, id);
      const item = task.checklist.find((c) => c.id === code);
      item.done = !item.done;
      break;
    }
    case 'del-task': {
      const i = DB.tasks.findIndex((x) => x.id === id);
      if (i > -1) DB.tasks.splice(i, 1);
      state.taskOpen = null;
      break;
    }
    case 'add-comment': {
      const input = document.getElementById('comment-input');
      if (!input || !input.value.trim()) return;
      byId(DB.tasks, id).comments.push({ id: uid('tc'), by: state.me, at: new Date(), text: input.value.trim() });
      break;
    }
    case 'new-task':
      draft = { priority: 'medium', type: 'task', assignees: id ? [id] : [], clone: false };
      if (el.dataset.team) {
        draft.team = el.dataset.team;
        draft.assignees = byId(DB.teams, el.dataset.team).members.slice();
      }
      state.modal = taskModal;
      break;
    case 'draft':
      draft[el.dataset.key] = el.dataset.key === 'clone' ? id === '1' : id;
      captureTaskDraft();
      break;
    case 'draft-team': {
      draft.team = draft.team === id ? null : id;
      if (draft.team) {
        const members = byId(DB.teams, id).members;
        draft.assignees = Array.from(new Set([...(draft.assignees || []), ...members]));
      }
      captureTaskDraft();
      break;
    }
    case 'draft-person': {
      draft.assignees = draft.assignees || [];
      const i = draft.assignees.indexOf(id);
      i === -1 ? draft.assignees.push(id) : draft.assignees.splice(i, 1);
      captureTaskDraft();
      break;
    }
    case 'draft-attendee': {
      draft.attendees = draft.attendees || [];
      const i = draft.attendees.indexOf(id);
      i === -1 ? draft.attendees.push(id) : draft.attendees.splice(i, 1);
      captureEventDraft();
      break;
    }
    case 'create-task': {
      captureTaskDraft();
      const people = draft.assignees || [];
      if (!draft.title || !people.length) return;
      const next = () => 'CTG-' + (Math.max(...DB.tasks.map((x) => parseInt(x.key.split('-')[1], 10))) + 1);
      const base = {
        description: draft.description || '', status: 'todo', priority: draft.priority || 'medium',
        type: draft.type || 'task', reporter: state.me, team: draft.team || null, labels: [],
        progress: 0, due: draft.due ? new Date(draft.due + 'T17:00') : null, checklist: [], comments: [],
      };
      const group = draft.clone || people.length > 1 ? uid('g') : null;
      if (draft.clone) {
        people.forEach((p) => DB.tasks.push({ id: uid('k'), key: next(), title: draft.title, assignees: [p], group, ...base }));
      } else {
        DB.tasks.push({ id: uid('k'), key: next(), title: draft.title, assignees: people, group, ...base });
      }
      state.modal = null;
      state.view = 'tasks';
      break;
    }
    case 'new-event':
      draft = { attendees: [state.me] };
      state.modal = eventModal;
      break;
    case 'create-event': {
      captureEventDraft();
      if (!draft.title) return;
      const d = draft.date ? new Date(draft.date + 'T00:00') : state.day;
      const mk = (hhmm) => new Date(d.getFullYear(), d.getMonth(), d.getDate(),
        +hhmm.split(':')[0], +hhmm.split(':')[1]);
      DB.events.push({
        id: uid('e'), title: draft.title, description: '', location: draft.location || '',
        start: draft.allDay ? new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0) : mk(draft.start || '10:00'),
        end: draft.allDay ? new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59) : mk(draft.end || '11:00'),
        by: state.me, color: '#2e4a3a', attendees: draft.attendees || [state.me], rsvp: {}, allDay: !!draft.allDay,
      });
      state.day = d;
      state.month = new Date(d.getFullYear(), d.getMonth(), 1);
      state.modal = null;
      break;
    }
    case 'read-all':
      DB.notifications.filter((n) => n.uid === state.me).forEach((n) => { n.read = true; });
      break;
    case 'open-notif': {
      const n = DB.notifications.find((x) => x.id === id);
      if (!n) return;
      n.read = true;
      state.view = n.route.view;
      if (n.route.channel) state.channel = n.route.channel;
      if (n.route.task) state.taskOpen = n.route.task;
      break;
    }
    case 'open-hit': {
      const m = byId(DB.messages, id);
      if (m) { state.channel = m.ch; state.search = ''; }
      break;
    }
    case 'mention': {
      const channel = byId(DB.channels, state.channel);
      const candidates = channel.members.filter((x) => x !== state.me);
      state.modal = () => modalShell(t('mentionSomeone'),
        candidates.map((cid) => `<button class="card row" style="width:100%;margin-bottom:8px;cursor:pointer;text-align:start"
          data-act="pick-mention" data-id="${cid}">${avatar(cid, '', true)}
          <span class="grow"><b>${esc(userName(cid))}</b></span></button>`).join(''),
        `<button class="btn" data-act="close-modal">${esc(t('cancel'))}</button>`);
      break;
    }
    case 'pick-mention': {
      state.modal = null;
      state.pendingMention = userName(id).split(' ')[0];
      break;
    }
    case 'close-modal': state.modal = null; break;
    case 'month':
      if (id === '0') {
        const n = new Date();
        state.month = new Date(n.getFullYear(), n.getMonth(), 1);
        state.day = new Date(n.getFullYear(), n.getMonth(), n.getDate());
      } else {
        state.month = new Date(state.month.getFullYear(), state.month.getMonth() + Number(id), 1);
      }
      break;
    case 'day': state.day = new Date(id); break;
    case 'rsvp': byId(DB.events, id).rsvp[state.me] = code; break;
    case 'role': byId(DB.users, id).role = el.value; break;
    case 'active': byId(DB.users, id).active = el.checked; break;
    default: return;
  }
  render();
}

function captureTaskDraft() {
  const title = document.getElementById('nt-title');
  const desc = document.getElementById('nt-desc');
  const due = document.getElementById('nt-due');
  if (title) draft.title = title.value;
  if (desc) draft.description = desc.value;
  if (due) draft.due = due.value;
}

function captureEventDraft() {
  const g = (x) => document.getElementById(x);
  if (g('ne-title')) draft.title = g('ne-title').value;
  if (g('ne-loc')) draft.location = g('ne-loc').value;
  if (g('ne-date')) draft.date = g('ne-date').value;
  if (g('ne-start')) draft.start = g('ne-start').value;
  if (g('ne-end')) draft.end = g('ne-end').value;
  if (g('ne-allday')) draft.allDay = g('ne-allday').checked;
}

// ------------------------------------------------------------------ wiring
function afterRender() {
  const search = document.getElementById('task-search');
  if (search) {
    search.oninput = (e) => { state.query = e.target.value; const pos = e.target.selectionStart; render();
      const again = document.getElementById('task-search'); again.focus(); again.setSelectionRange(pos, pos); };
  }
  const msearch = document.getElementById('member-search');
  if (msearch) {
    msearch.oninput = (e) => { state.query = e.target.value; const pos = e.target.selectionStart; render();
      const again = document.getElementById('member-search'); again.focus(); again.setSelectionRange(pos, pos); };
  }
  const searchBox = document.getElementById('msg-search');
  if (searchBox) {
    searchBox.oninput = (e) => {
      state.search = e.target.value;
      const pos = e.target.selectionStart;
      render();
      const again = document.getElementById('msg-search');
      again.focus();
      again.setSelectionRange(pos, pos);
    };
  }
  const composer = document.getElementById('composer-input');
  if (composer) {
    if (state.pendingMention) {
      composer.value = `${composer.value}${composer.value && !composer.value.endsWith(' ') ? ' ' : ''}@${state.pendingMention} `;
      state.pendingMention = null;
    }
    composer.onkeydown = (e) => { if (e.key === 'Enter') { e.preventDefault(); sendMessage('text'); } };
    composer.focus();
  }
  const comment = document.getElementById('comment-input');
  if (comment) {
    comment.onkeydown = (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        handle('add-comment', { dataset: { id: state.taskOpen } });
      }
    };
  }
  const box = document.getElementById('messages');
  if (box) box.scrollTop = box.scrollHeight;

  // Kanban drag and drop
  document.querySelectorAll('.task[draggable]').forEach((card) => {
    card.addEventListener('dragstart', (e) => {
      e.dataTransfer.setData('text/plain', card.dataset.task);
      card.classList.add('dragging');
    });
    card.addEventListener('dragend', () => card.classList.remove('dragging'));
  });
  document.querySelectorAll('[data-drop]').forEach((col) => {
    col.addEventListener('dragover', (e) => { e.preventDefault(); col.classList.add('over'); });
    col.addEventListener('dragleave', () => col.classList.remove('over'));
    col.addEventListener('drop', (e) => {
      e.preventDefault();
      col.classList.remove('over');
      const task = byId(DB.tasks, e.dataTransfer.getData('text/plain'));
      if (!task) return;
      task.status = col.dataset.drop;
      if (task.status === 'done') task.progress = 100;
      render();
    });
  });
}

document.addEventListener('click', (e) => {
  const stop = e.target.closest('[data-stop]');
  const target = e.target.closest('[data-act]');
  if (!target) return;
  if (target.dataset.act === 'close-modal' && stop && !e.target.closest('[data-act="close-modal"]').isSameNode(target)) return;
  if (target.tagName === 'INPUT' && target.type === 'radio') { handle(target.dataset.act, target); return; }
  if (target.tagName === 'INPUT' && target.type === 'checkbox') return; // handled on change
  e.preventDefault();
  handle(target.dataset.act, target);
});

document.addEventListener('change', (e) => {
  const target = e.target.closest('[data-act]');
  if (!target) return;
  if (target.tagName === 'SELECT' || target.type === 'checkbox') handle(target.dataset.act, target);
});

document.addEventListener('input', (e) => {
  const target = e.target.closest('[data-act="progress"]');
  if (!target) return;
  const task = byId(DB.tasks, target.dataset.id);
  task.progress = Number(target.value);
  if (task.progress === 100) task.status = 'done';
  else if (task.status === 'done') task.status = 'inProgress';
  const label = target.previousElementSibling.querySelector('span:last-child');
  if (label) label.textContent = task.progress + '%';
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    if (state.modal) { state.modal = null; render(); }
    else if (state.taskOpen) { state.taskOpen = null; render(); }
  }
});

render();
