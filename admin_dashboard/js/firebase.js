// Firebase Web SDK Setup (Connecting to EXISTING Firebase Project)
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js";
import { getAuth, GoogleAuthProvider } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js";
import { getFirestore, collection, getDocs, limit, query } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";
import DOMPurify from "https://cdn.jsdelivr.net/npm/dompurify@3.2.6/+esm";

// Existing Firebase Web configuration from lib/firebase_options.dart
const firebaseConfig = {
    apiKey: "AIzaSyDa2Kztf7K0CDAUc2vaN_al7EE6iy9je2A",
    authDomain: "mess-management-app-5c883.firebaseapp.com",
    projectId: "mess-management-app-5c883",
    storageBucket: "mess-management-app-5c883.firebasestorage.app",
    messagingSenderId: "666532902328",
    appId: "1:666532902328:web:9180ee6fcfade017644b4d"
};

// Initialize Firebase Core Services
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const googleProvider = new GoogleAuthProvider();

function setSafeHTML(element, markup) {
    if (element.tagName === "TBODY") {
        const template = document.createElement("template");
        template.innerHTML = DOMPurify.sanitize(`<table><tbody>${markup}</tbody></table>`);
        const safeTbody = template.content.querySelector("tbody");
        element.replaceChildren(...(safeTbody ? safeTbody.childNodes : []));
        return;
    }

    element.innerHTML = DOMPurify.sanitize(markup);
}

console.log("Firebase initialized successfully");

export { app, auth, db, googleProvider, setSafeHTML };
