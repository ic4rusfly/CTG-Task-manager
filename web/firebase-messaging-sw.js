/**
 * Background push for the web build.
 *
 * Fill in the values printed by `flutterfire configure` (they are public
 * client identifiers, not secrets). Without this file the web app only
 * receives notifications while a tab is open and focused.
 */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'REPLACE_WITH_WEB_API_KEY',
  appId: 'REPLACE_WITH_WEB_APP_ID',
  messagingSenderId: 'REPLACE_WITH_SENDER_ID',
  projectId: 'REPLACE_WITH_PROJECT_ID',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  self.registration.showNotification(notification.title || 'CTG Hub', {
    body: notification.body || '',
    data: payload.data || {},
    tag: (payload.data && payload.data.route) || 'ctg-hub',
  });
});

// Tapping the system notification focuses an open tab, or opens the route.
self.addEventListener('notificationclick', (event) => {
  const route = (event.notification.data && event.notification.data.route) || '/';
  event.notification.close();
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clients) => {
      for (const client of clients) {
        if ('focus' in client) {
          client.postMessage({ type: 'ctg-route', route });
          return client.focus();
        }
      }
      return self.clients.openWindow(route);
    })
  );
});
