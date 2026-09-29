// Seed data for the prototype - mirrors lib/data/mock/mock_db.dart.
(function () {
  const now = new Date();
  const D = (days, h = 9, m = 0) =>
    new Date(now.getFullYear(), now.getMonth(), now.getDate() + days, h, m);
  const ago = (mins) => new Date(now.getTime() - mins * 60000);

  const users = [
    { id: 'u1', name: 'Yasmine Bennani', email: 'yasmine@ctg.ma', title: 'Program Director', team: 't1', role: 'admin', locale: 'fr', online: true, bio: 'Coordinates CTG programs and partnerships.', skills: ['Leadership', 'Partnerships'], phone: '+212 6 12 34 56 78', muted: []  },
    { id: 'u2', name: 'Omar El Idrissi', email: 'omar@ctg.ma', title: 'Tech Lead', team: 't2', role: 'lead', locale: 'en', online: true, bio: 'Builds the CTG platform. Flutter and Firebase.', skills: ['Flutter', 'Firebase', 'CI/CD'], phone: '', muted: []  },
    { id: 'u3', name: 'Salma Ait Taleb', email: 'salma@ctg.ma', title: 'Designer', team: 't2', role: 'member', locale: 'ar', online: false, bio: 'UI/UX, brand and motion.', skills: ['Figma', 'Branding'], phone: '', muted: []  },
    { id: 'u4', name: 'Mehdi Ouazzani', email: 'mehdi@ctg.ma', title: 'Events Coordinator', team: 't3', role: 'lead', locale: 'fr', online: false, bio: 'Logistics, venues and volunteers.', skills: ['Logistics', 'Community'], phone: '', muted: []  },
    { id: 'u5', name: 'Nour Haddad', email: 'nour@ctg.ma', title: 'Communications', team: 't3', role: 'member', locale: 'ar', online: true, bio: 'Social media and press.', skills: ['Copywriting', 'Social'], phone: '', muted: []  },
    { id: 'u6', name: 'Anas Rahmouni', email: 'anas@ctg.ma', title: 'Developer', team: 't2', role: 'member', locale: 'en', online: false, bio: 'Backend and data.', skills: ['Node', 'Firestore'], phone: '', muted: []  },
  ];
  users.forEach((u) => (u.active = true));

  const teams = [
    { id: 't1', name: 'Core', members: ['u1'], lead: 'u1', color: '#2e4a3a' },
    { id: 't2', name: 'Tech', members: ['u2', 'u3', 'u6'], lead: 'u2', color: '#3e6b52' },
    { id: 't3', name: 'Events and Comms', members: ['u4', 'u5'], lead: 'u4', color: '#6b4a32' },
  ];

  const everyone = users.map((u) => u.id);

  const channels = [
    { id: 'c_general', name: 'general', type: 'general', topic: 'Everything CTG - announcements and daily chatter', members: everyone, read: {} },
    { id: 'c_tech', name: 'tech', type: 'public', topic: 'Platform, releases, bugs', members: ['u1', 'u2', 'u3', 'u6'], read: {} },
    { id: 'c_events', name: 'events', type: 'public', topic: 'CTG Day, meetups, logistics', members: ['u1', 'u4', 'u5'], read: {} },
    { id: 'c_board', name: 'board', type: 'private', topic: 'Leads only', members: ['u1', 'u2', 'u4'], read: {} },
    { id: 'c_dm_1_2', name: '', type: 'dm', members: ['u1', 'u2'], read: {} },
    { id: 'c_dm_2_3', name: '', type: 'dm', members: ['u2', 'u3'], read: {} },
  ];

  const messages = [
    { id: 'm1', ch: 'c_general', from: 'u1', at: ago(360), type: 'text', text: 'Good morning everyone. Reminder: the CTG Day planning review is on Thursday.', reactions: { ack: ['u2', 'u5'], agree: ['u3'] } },
    { id: 'm1r1', ch: 'c_general', from: 'u3', at: ago(330), type: 'text', replyTo: 'm1', text: 'Thursday works for me. Can we start at 15:00?', reactions: {} },
    { id: 'm1r2', ch: 'c_general', from: 'u1', at: ago(310), type: 'text', replyTo: 'm1', text: 'Yes, 15:00 in the small meeting room.', reactions: {} },
    { id: 'm2', ch: 'c_general', from: 'u5', at: ago(300), type: 'image', text: 'The new poster draft is ready, feedback welcome.', att: { name: 'ctg-day-poster.png', mime: 'image/png', size: '842 KB' }, reactions: {} },
    { id: 'm3', ch: 'c_general', from: 'u2', at: ago(240), type: 'taskRef', text: '', taskId: 'k3', reactions: {} },
    { id: 'm4', ch: 'c_general', from: 'u4', at: ago(180), type: 'file', text: 'Venue confirmation attached.', att: { name: 'venue-contract.pdf', mime: 'application/pdf', size: '231 KB' }, reactions: {} },
    { id: 'm5', ch: 'c_general', from: 'u3', at: ago(120), type: 'audio', text: 'Playlist for the closing session.', att: { name: 'ctg-day-mix.mp3', mime: 'audio/mpeg', size: '5.3 MB', duration: '3:04' }, reactions: {} },
    { id: 'm6', ch: 'c_general', from: 'u6', at: ago(8), type: 'link', text: 'Useful read on Firestore pricing', url: 'https://firebase.google.com/docs/firestore/pricing', reactions: {} },
    { id: 'm10', ch: 'c_tech', from: 'u2', at: ago(190), type: 'text', text: 'Release 0.4 is on staging, please test the agenda view.', reactions: {} },
    { id: 'm11', ch: 'c_tech', from: 'u6', at: ago(130), type: 'text', text: 'Found a bug with recurring events, opening a ticket.', reactions: { watching: ['u2'] } },
    { id: 'm20', ch: 'c_events', from: 'u4', at: ago(300), type: 'text', text: 'Catering quote received for 120 people.', reactions: {} },
    { id: 'm30', ch: 'c_board', from: 'u1', at: ago(1440), type: 'text', text: 'Budget review notes shared.', reactions: {} },
    { id: 'm40', ch: 'c_dm_1_2', from: 'u1', at: ago(45), type: 'text', text: 'Can you assign the onboarding tasks to the new members today?', reactions: {} },
    { id: 'm41', ch: 'c_dm_1_2', from: 'u2', at: ago(40), type: 'text', text: 'Already done, assigned as a group task.', reactions: {} },
    { id: 'm50', ch: 'c_dm_2_3', from: 'u3', at: ago(180), type: 'text', text: 'Sending the updated palette now.', reactions: {} },
  ];

  const tasks = [
    {
      id: 'k1', key: 'CTG-101', title: 'Finalize CTG Day agenda',
      description: 'Collect the talk list, confirm speakers and publish the schedule.',
      status: 'inProgress', priority: 'high', type: 'task', assignees: ['u4', 'u5'],
      reporter: 'u1', team: 't3', labels: ['ctg-day', 'planning'], progress: 60,
      due: D(3, 17), estimate: 8,
      checklist: [
        { id: 'a', text: 'Collect talk proposals', done: true },
        { id: 'b', text: 'Confirm speakers', done: true },
        { id: 'c', text: 'Publish schedule', done: false },
      ],
      comments: [
        { id: 'tc1', by: 'u5', at: ago(1200), text: 'Two speakers still have not confirmed, I will follow up today.' },
        { id: 'tc2', by: 'u1', at: ago(1080), text: 'Thanks - let us lock the schedule before Thursday.' },
      ],
    },
    {
      id: 'k2', key: 'CTG-102', title: 'Fix recurring events bug',
      description: 'Weekly events repeat one day off in the month view.',
      status: 'todo', priority: 'urgent', type: 'bug', assignees: ['u2'], reporter: 'u6',
      team: 't2', labels: ['agenda', 'bug'], progress: 0, due: D(1, 12), estimate: 3,
      checklist: [], comments: [],
    },
    {
      id: 'k3', key: 'CTG-103', title: 'CTG Day poster and social kit',
      description: 'Poster, story templates and a cover image in three languages.',
      status: 'review', priority: 'medium', type: 'feature', assignees: ['u3'], reporter: 'u1',
      team: 't2', labels: ['design'], progress: 90, due: D(2, 18), estimate: 6,
      checklist: [], comments: [],
    },
    {
      id: 'k4', key: 'CTG-104', title: 'Onboard new members (welcome pack)',
      description: 'Send the welcome pack, add to the general channel, schedule the intro call.',
      status: 'todo', priority: 'medium', type: 'task', assignees: ['u3', 'u5', 'u6'],
      reporter: 'u2', team: null, labels: ['onboarding'], progress: 20, due: D(5, 17),
      group: 'g-onboarding', checklist: [], comments: [],
    },
    {
      id: 'k5', key: 'CTG-105', title: 'Publish quarterly newsletter',
      description: '', status: 'done', priority: 'low', type: 'task', assignees: ['u5'],
      reporter: 'u1', team: 't3', labels: [], progress: 100, due: D(-2, 17),
      checklist: [], comments: [],
    },
    {
      id: 'k6', key: 'CTG-106', title: 'Sponsor deck v2',
      description: 'Update the numbers and add the 2026 program roadmap.',
      status: 'backlog', priority: 'medium', type: 'task', assignees: ['u1', 'u3'],
      reporter: 'u1', team: null, labels: ['sponsors'], progress: 0, due: D(14, 17),
      checklist: [], comments: [],
    },
  ];

  const events = [
    { id: 'e1', title: 'Weekly CTG standup', description: 'Quick round of updates from every team.', start: D(0, 10), end: D(0, 10, 30), by: 'u1', location: 'Meeting room A', color: '#2e4a3a', attendees: everyone, rsvp: { u2: 'going', u5: 'going' } },
    { id: 'e2', title: 'CTG Day planning review', description: '', start: D(3, 15), end: D(3, 16, 30), by: 'u4', location: 'Hybrid', color: '#6b4a32', attendees: ['u1', 'u4', 'u5'], rsvp: {} },
    { id: 'e3', title: 'Design review - poster and social kit', description: '', start: D(1, 14), end: D(1, 15), by: 'u2', location: '', color: '#3e6b52', attendees: ['u2', 'u3', 'u1'], rsvp: {}, task: 'k3' },
    { id: 'e4', title: 'CTG Day', description: 'The annual CTG gathering.', start: D(9, 9), end: D(9, 18), by: 'u1', location: 'Agadir - Technopark', color: '#6e2c2c', attendees: everyone, rsvp: {}, allDay: true },
    { id: 'e5', title: 'Release 0.4 to production', description: '', start: D(5, 11), end: D(5, 12), by: 'u2', location: '', color: '#3e6b52', attendees: ['u2', 'u6'], rsvp: {} },
  ];

  const byIdLocal = (list, id) => list.find((x) => x.id === id);

  // Task trail, mirroring tasks/{id}/activity.
  const activity = [
    { id: 'a1', task: 'k1', by: 'u1', kind: 'created', at: ago(5760) },
    { id: 'a2', task: 'k1', by: 'u1', kind: 'assigned', to: 'u4,u5', at: ago(5760) },
    { id: 'a3', task: 'k1', by: 'u4', kind: 'status', from: 'todo', to: 'inProgress', at: ago(2880) },
    { id: 'a4', task: 'k1', by: 'u4', kind: 'progress', from: '20', to: '45', at: ago(1200) },
    { id: 'a5', task: 'k3', by: 'u2', kind: 'created', at: ago(4320) },
    { id: 'a6', task: 'k3', by: 'u3', kind: 'status', from: 'inProgress', to: 'review', at: ago(300) },
  ];

  const notifications = [
    { id: 'n1', uid: 'u1', kind: 'taskStatus', title: 'Task updated', body: 'CTG-103 moved to Review', route: { view: 'tasks', task: 'k3' }, read: false, at: ago(240) },
    { id: 'n2', uid: 'u1', kind: 'dueSoon', title: 'Task due soon', body: 'CTG-102 is due within 24 hours: Fix recurring events bug', route: { view: 'tasks', task: 'k2' }, read: false, at: ago(90) },
    { id: 'n3', uid: 'u2', kind: 'mention', title: 'Yasmine Bennani mentioned you', body: 'Can you assign the onboarding tasks to the new members today?', route: { view: 'chat', channel: 'c_dm_1_2' }, read: false, at: ago(45) },
  ];

  // Seeded read receipts, so the chat shows "Seen" and "Seen by N".
  Object.assign(byIdLocal(channels, 'c_general').read, {
    u2: ago(5), u3: ago(6), u4: ago(240),
  });
  Object.assign(byIdLocal(channels, 'c_dm_1_2').read, { u1: ago(35), u2: ago(30) });
  Object.assign(byIdLocal(channels, 'c_tech').read, { u6: ago(60) });

  window.DB = { users, teams, channels, messages, tasks, events, notifications, activity };
})();
