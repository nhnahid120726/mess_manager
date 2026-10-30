// IMPORTANT:
// Real database security must be enforced by Firestore Security Rules.
// This JavaScript role check is not a replacement for server-side security rules.

import { auth, db } from "./firebase.js";
import { signInWithEmailAndPassword, sendPasswordResetEmail, signOut, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js";
import { doc, getDoc } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";

// DOM Elements
const loginForm = document.getElementById("login-form");
const emailInput = document.getElementById("email-input");
const passwordInput = document.getElementById("password-input");
const togglePasswordBtn = document.getElementById("toggle-password-btn");
const emailLoginBtn = document.getElementById("email-login-btn");
const btnText = document.getElementById("btn-text");
const forgotPasswordBtn = document.getElementById("forgot-password-btn");

const statusMsg = document.getElementById("status-msg");
const loginError = document.getElementById("login-error");
const loginSuccess = document.getElementById("login-success");
const logoutBtn = document.getElementById("logout-btn");

const adminNameEl = document.getElementById("admin-name");
const adminEmailEl = document.getElementById("admin-email");
const adminAvatarEl = document.getElementById("admin-avatar");
let resolveAdminAccess;
export const adminAccessReady = new Promise((resolve) => {
    resolveAdminAccess = resolve;
});

// Helper: Show Error Box
function showError(message) {
    if (loginError) {
        loginError.textContent = message;
        loginError.classList.add("visible");
    }
    if (loginSuccess) {
        loginSuccess.style.display = "none";
        loginSuccess.classList.remove("visible");
    }
}

// Helper: Clear Error Box
function clearError() {
    if (loginError) {
        loginError.textContent = "";
        loginError.classList.remove("visible");
    }
}

// Helper: Show Success Message Box
function showSuccess(message) {
    if (loginSuccess) {
        loginSuccess.textContent = message;
        loginSuccess.style.display = "block";
        loginSuccess.classList.add("visible");
    }
    clearError();
}

// Helper: Update Status Message
function updateStatus(message) {
    if (statusMsg) {
        statusMsg.textContent = message;
    }
}

// Helper: Set Button Loading State
function setLoadingState(isLoading, text = "Log In") {
    if (emailLoginBtn) {
        emailLoginBtn.disabled = isLoading;
    }
    if (btnText) {
        btnText.textContent = text;
    }
}

// Toggle Show/Hide Password
if (togglePasswordBtn && passwordInput) {
    togglePasswordBtn.addEventListener("click", () => {
        const isPassword = passwordInput.type === "password";
        passwordInput.type = isPassword ? "text" : "password";
        togglePasswordBtn.textContent = isPassword ? "🙈" : "👁️";
    });
}

// Verify Admin Role in Firestore: members/{user.email}
async function verifyAdminRole(user) {
    if (!user || !user.email) {
        console.warn("Auth check failed: User email missing.");
        return false;
    }

    try {
        const memberRef = doc(db, "members", user.email);
        const memberSnap = await getDoc(memberRef);

        if (!memberSnap.exists()) {
            console.warn(`User document not found in Firestore for email: ${user.email}`);
            return false;
        }

        const data = memberSnap.data();
        const isRoleAdmin = data.role === "admin";
        const isAuthorized = data.isAuthorized === true;

        console.log(`Role Check [${user.email}]: role=${data.role}, isAuthorized=${data.isAuthorized}`);

        return isRoleAdmin && isAuthorized;
    } catch (error) {
        console.error("Firestore Error during admin verification:", error);
        return false;
    }
}

// Populate Admin Details on Dashboard
function updateDashboardUserInfo(user) {
    if (adminNameEl) {
        adminNameEl.textContent = user.displayName || "Admin User";
    }
    if (adminEmailEl) {
        adminEmailEl.textContent = user.email || "";
    }
    if (adminAvatarEl && user.photoURL) {
        adminAvatarEl.src = user.photoURL;
        adminAvatarEl.style.display = "block";
    }
}

// Execute Email/Password Sign-In
async function handleEmailLogin(e) {
    if (e) e.preventDefault();
    clearError();

    const email = emailInput ? emailInput.value.trim() : "";
    const password = passwordInput ? passwordInput.value.trim() : "";

    if (!email) {
        showError("Please enter your admin email address.");
        return;
    }

    if (!password) {
        showError("Please enter your password.");
        return;
    }

    setLoadingState(true, "Logging in...");
    updateStatus("Authenticating with Firebase...");

    try {
        const result = await signInWithEmailAndPassword(auth, email, password);
        const user = result.user;

        updateStatus("Verifying admin access in Firestore...");

        const isAdmin = await verifyAdminRole(user);

        if (isAdmin) {
            updateStatus("Access granted! Redirecting to Dashboard...");
            window.location.href = "dashboard.html";
        } else {
            await signOut(auth);
            updateStatus("");
            showError("Access denied. You are not authorized to access the Admin Dashboard.");
            setLoadingState(false, "Log In");
        }
    } catch (error) {
        console.error("Firebase Email Auth Error:", error);
        setLoadingState(false, "Log In");
        updateStatus("");

        if (error.code === "auth/invalid-credential" || error.code === "auth/wrong-password" || error.code === "auth/user-not-found") {
            showError("Invalid email or password. Please check your credentials.");
        } else if (error.code === "auth/invalid-email") {
            showError("Invalid email address format.");
        } else if (error.code === "auth/too-many-requests") {
            showError("Too many failed attempts. Account temporarily locked for security. Please try again later or reset password.");
        } else if (error.code === "auth/network-request-failed") {
            showError("Network connection error. Please check your internet connection.");
        } else {
            showError(`Login failed: ${error.message || "Unknown authentication error."}`);
        }
    }
}

// Execute Forgot Password Request
async function handleForgotPassword(e) {
    if (e) e.preventDefault();
    clearError();

    const email = emailInput ? emailInput.value.trim() : "";

    if (!email) {
        showError("Please enter your admin email address to send a password reset link.");
        if (emailInput) emailInput.focus();
        return;
    }

    try {
        updateStatus("Sending password reset email...");
        await sendPasswordResetEmail(auth, email);
        updateStatus("");
        showSuccess(`Password reset email sent to ${email}. Please check your inbox or spam folder.`);
    } catch (error) {
        console.error("Forgot Password Error:", error);
        updateStatus("");
        if (error.code === "auth/user-not-found") {
            showError("No account found with this email address.");
        } else if (error.code === "auth/invalid-email") {
            showError("Invalid email address format.");
        } else {
            showError(`Failed to send password reset email: ${error.message || "Unknown error."}`);
        }
    }
}

// Bind Form & Button Listeners
if (loginForm) {
    loginForm.addEventListener("submit", handleEmailLogin);
}

if (forgotPasswordBtn) {
    forgotPasswordBtn.addEventListener("click", handleForgotPassword);
}

// Bind Logout Button Event
if (logoutBtn) {
    logoutBtn.addEventListener("click", async () => {
        try {
            await signOut(auth);
            window.location.href = "login.html";
        } catch (error) {
            console.error("Logout Error:", error);
        }
    });
}

// Authentication State Listener (Session Persistence & Access Control)
onAuthStateChanged(auth, async (user) => {
    const isDashboardPage = window.location.pathname.includes("dashboard.html");
    const isLoginPage = window.location.pathname.includes("login.html") || window.location.pathname.endsWith("/");

    if (user) {
        console.log(`Auth State Change: User authenticated (${user.email})`);

        if (isLoginPage) {
            updateStatus("Verifying session permissions...");
            setLoadingState(true, "Verifying...");
            const isAdmin = await verifyAdminRole(user);

            if (isAdmin) {
                updateStatus("Redirecting to Dashboard...");
                window.location.href = "dashboard.html";
            } else {
                await signOut(auth);
                setLoadingState(false, "Log In");
                updateStatus("");
                showError("Access denied. You are not authorized to access the Admin Dashboard.");
            }
        } else if (isDashboardPage) {
            const isAdmin = await verifyAdminRole(user);
            if (isAdmin) {
                updateDashboardUserInfo(user);
                resolveAdminAccess(true);
            } else {
                await signOut(auth);
                resolveAdminAccess(false);
                window.location.href = "login.html";
            }
        }
    } else {
        console.log("Auth State Change: No user authenticated.");
        if (isDashboardPage) {
            resolveAdminAccess(false);
            window.location.href = "login.html";
        }
    }
});
