importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyD-KVtmg-myJCatc2eGCwe9CBDLvSup-oc",
  authDomain: "sync-team-project.firebaseapp.com",
  projectId: "sync-team-project",
  storageBucket: "sync-team-project.firebasestorage.app",
  messagingSenderId: "1039676366270",
  appId: "1:1039676366270:web:17bdc93d2ea54f322a2def",
  measurementId: "G-4E9W3FN7E5"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png",
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});

// Tambahan agar syarat PWA lengkap (Installable)
self.addEventListener('install', (event) => {
  console.log('Service Worker installed');
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  console.log('Service Worker activated');
});

self.addEventListener('fetch', (event) => {
  // Formalitas agar tombol Install muncul
});
