// web/firebase-messaging-sw.js

importScripts("https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js");

// Replace these values with YOUR project settings from firebase_options.dart
firebase.initializeApp({
  apiKey: "AIzaSyBgTw1kg3ogEQDCQ0aPoLC1pkTcj65T8Yo",
  authDomain: "pil-project-43392.firebaseapp.com",
  projectId: "pil-project-43392",
  storageBucket: "pil-project-43392.appspot.com",
  messagingSenderId: "134041370565",
  appId: "1:134041370565:web:2ec146a71d5e6d0a77d5ac",
});

const messaging = firebase.messaging();
