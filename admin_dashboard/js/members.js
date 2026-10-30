// Phase 5: Members Management Module (Read-Only Directory & Directory Analytics)
import { db, setSafeHTML } from "./firebase.js";
import { collection, getDocs } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";

// DOM Reference
const contentArea = document.getElementById("content-area");

// Local Module State
let allMembersList = [];
let filteredMembersList = [];
let searchQuery = "";
let roleFilter = "all";
let authFilter = "all";

// Role Display Badge Mapping
function getRoleBadge(role) {
    const r = (role || "").toLowerCase();
    if (r === "admin") {
        return `<span class="role-badge role-badge-admin">Admin</span>`;
    } else if (r === "wallet_only") {
        return `<span class="role-badge role-badge-wallet">Wallet Only</span>`;
    } else {
        return `<span class="role-badge role-badge-member">General Member</span>`;
    }
}

// Auth Status Display Badge Mapping
function getAuthBadge(isAuthorized) {
    if (isAuthorized === true) {
        return `<span class="status-pill auth-status-true">Authorized</span>`;
    } else {
        return `<span class="status-pill auth-status-false">Unauthorized</span>`;
    }
}

// Load and Process Members Data
export async function loadMembersModule() {
    if (!contentArea) return;

    setSafeHTML(contentArea, `
        <div class="loading-box">
            <div class="spinner"></div>
            <p>Loading members directory from Firestore...</p>
        </div>
    `);

    try {
        const membersSnap = await getDocs(collection(db, "members"));
        allMembersList = [];

        membersSnap.forEach((docSnap) => {
            const data = docSnap.data();
            allMembersList.push({
                docId: docSnap.id,
                name: data.name || "Unknown Name",
                email: data.email || docSnap.id,
                role: (data.role || "member").toLowerCase(),
                isAuthorized: data.isAuthorized === true
            });
        });

        // Sort alphabetically by name
        allMembersList.sort((a, b) => a.name.localeCompare(b.name));

        // Render Page Structure
        renderMembersUI();

    } catch (error) {
        console.error("Error loading members collection:", error);
        setSafeHTML(contentArea, `
            <div class="error-msg visible" style="margin-top: 0;">
                <strong>Error Loading Members:</strong> ${error.message || "Failed to fetch 'members' collection from Firestore."}
            </div>
        `);
    }
}

// Render Main Members Page UI
function renderMembersUI() {
    // 1. Calculate Summary Stats
    const totalMembers = allMembersList.length;
    const adminMembers = allMembersList.filter(m => m.role === "admin").length;
    const generalMembers = allMembersList.filter(m => m.role === "member").length;
    const walletMembers = allMembersList.filter(m => m.role === "wallet_only").length;
    const authorizedMembers = allMembersList.filter(m => m.isAuthorized === true).length;
    const unauthorizedMembers = allMembersList.filter(m => m.isAuthorized !== true).length;

    setSafeHTML(contentArea, `
        <!-- Summary Cards (6 Cards) -->
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Directory Users</span>
                    <div class="card-icon icon-blue">👥</div>
                </div>
                <div class="card-value">${totalMembers}</div>
                <div class="card-subtext">All accounts in database</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Admin Users</span>
                    <div class="card-icon icon-red">👑</div>
                </div>
                <div class="card-value">${adminMembers}</div>
                <div class="card-subtext">System administrators</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">General Mess Members</span>
                    <div class="card-icon icon-indigo">🏠</div>
                </div>
                <div class="card-value">${generalMembers}</div>
                <div class="card-subtext">Mess active members (Max 8)</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Wallet Only Users</span>
                    <div class="card-icon icon-purple">💳</div>
                </div>
                <div class="card-value">${walletMembers}</div>
                <div class="card-subtext">Personal wallet module users</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Authorized Users</span>
                    <div class="card-icon icon-green">✅</div>
                </div>
                <div class="card-value">${authorizedMembers}</div>
                <div class="card-subtext">Access granted users</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Unauthorized Users</span>
                    <div class="card-icon icon-amber">🚫</div>
                </div>
                <div class="card-value">${unauthorizedMembers}</div>
                <div class="card-subtext">Blocked / Pending authorization</div>
            </div>
        </div>

        <!-- Search & Filter Controls -->
        <div class="filter-bar">
            <input
                type="text"
                id="member-search-input"
                class="search-input"
                placeholder="🔍 Search by Name or Email..."
                value="${searchQuery}"
            />

            <select id="member-role-filter" class="select-filter">
                <option value="all" ${roleFilter === "all" ? "selected" : ""}>All Roles</option>
                <option value="admin" ${roleFilter === "admin" ? "selected" : ""}>Admin</option>
                <option value="member" ${roleFilter === "member" ? "selected" : ""}>General Member</option>
                <option value="wallet_only" ${roleFilter === "wallet_only" ? "selected" : ""}>Wallet Only</option>
            </select>

            <select id="member-auth-filter" class="select-filter">
                <option value="all" ${authFilter === "all" ? "selected" : ""}>All Statuses</option>
                <option value="authorized" ${authFilter === "authorized" ? "selected" : ""}>Authorized</option>
                <option value="unauthorized" ${authFilter === "unauthorized" ? "selected" : ""}>Unauthorized</option>
            </select>
        </div>

        <!-- Table Card -->
        <div class="table-card">
            <div class="card-header-row" style="margin-bottom: 16px;">
                <h4>Members Directory (<span id="filtered-count">${totalMembers}</span>)</h4>
            </div>

            <div class="table-responsive">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th style="width: 50px;">#</th>
                            <th>Member Name</th>
                            <th>Email Address</th>
                            <th>Role</th>
                            <th>Status</th>
                            <th>Document ID</th>
                            <th style="width: 100px; text-align: right;">Action</th>
                        </tr>
                    </thead>
                    <tbody id="members-table-body">
                        <!-- Rows injected via applyFilters() -->
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Details Modal Container -->
        <div id="member-details-modal" class="modal-backdrop" style="display: none;"></div>
    `);

    // Bind Event Listeners
    const searchInput = document.getElementById("member-search-input");
    const roleSelect = document.getElementById("member-role-filter");
    const authSelect = document.getElementById("member-auth-filter");

    if (searchInput) {
        searchInput.addEventListener("input", (e) => {
            searchQuery = e.target.value.trim().toLowerCase();
            applyFilters();
        });
    }

    if (roleSelect) {
        roleSelect.addEventListener("change", (e) => {
            roleFilter = e.target.value;
            applyFilters();
        });
    }

    if (authSelect) {
        authSelect.addEventListener("change", (e) => {
            authFilter = e.target.value;
            applyFilters();
        });
    }

    // Apply Initial Filters & Render Table Body
    applyFilters();
}

// Apply Search & Filter Conditions
function applyFilters() {
    filteredMembersList = allMembersList.filter((m) => {
        // Search Filter (Name or Email)
        const matchesSearch =
            m.name.toLowerCase().includes(searchQuery) ||
            m.email.toLowerCase().includes(searchQuery);

        // Role Filter
        let matchesRole = true;
        if (roleFilter !== "all") {
            matchesRole = m.role === roleFilter;
        }

        // Auth Filter
        let matchesAuth = true;
        if (authFilter === "authorized") {
            matchesAuth = m.isAuthorized === true;
        } else if (authFilter === "unauthorized") {
            matchesAuth = m.isAuthorized !== true;
        }

        return matchesSearch && matchesRole && matchesAuth;
    });

    renderTableRows();
}

// Render Filtered Table Rows
function renderTableRows() {
    const tbody = document.getElementById("members-table-body");
    const filteredCountEl = document.getElementById("filtered-count");

    if (filteredCountEl) {
        filteredCountEl.textContent = filteredMembersList.length;
    }

    if (!tbody) return;

    if (filteredMembersList.length === 0) {
        setSafeHTML(tbody, `
            <tr>
                <td colspan="7" class="empty-state">
                    No members found matching the selected search criteria.
                </td>
            </tr>
        `);
        return;
    }

    let rowsHTML = "";
    filteredMembersList.forEach((member, index) => {
        rowsHTML += `
            <tr style="cursor: pointer;" data-email="${member.email}" class="member-row">
                <td><strong>${index + 1}</strong></td>
                <td><strong>${member.name}</strong></td>
                <td>${member.email}</td>
                <td>${getRoleBadge(member.role)}</td>
                <td>${getAuthBadge(member.isAuthorized)}</td>
                <td><code>${member.docId}</code></td>
                <td style="text-align: right;">
                    <button class="btn btn-outline btn-sm view-details-btn" data-email="${member.email}">
                        View Details
                    </button>
                </td>
            </tr>
        `;
    });

    setSafeHTML(tbody, rowsHTML);

    // Attach Row Click & View Details Listeners
    document.querySelectorAll(".view-details-btn").forEach((btn) => {
        btn.addEventListener("click", (e) => {
            e.stopPropagation();
            const email = btn.getAttribute("data-email");
            showMemberDetailsModal(email);
        });
    });

    document.querySelectorAll(".member-row").forEach((row) => {
        row.addEventListener("click", () => {
            const email = row.getAttribute("data-email");
            showMemberDetailsModal(email);
        });
    });
}

// Show Read-Only Member Details Modal
function showMemberDetailsModal(email) {
    const member = allMembersList.find((m) => m.email === email);
    if (!member) return;

    const modalContainer = document.getElementById("member-details-modal");
    if (!modalContainer) return;

    setSafeHTML(modalContainer, `
        <div class="modal-box">
            <div class="modal-header">
                <h3>Member Profile Details</h3>
                <button class="close-btn" id="close-modal-btn">&times;</button>
            </div>
            <div class="modal-body">
                <div class="detail-row">
                    <span class="detail-label">Member Name</span>
                    <span class="detail-val">${member.name}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Email Address</span>
                    <span class="detail-val">${member.email}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">System Role</span>
                    <span class="detail-val">${getRoleBadge(member.role)}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Authorization Status</span>
                    <span class="detail-val">${getAuthBadge(member.isAuthorized)}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Firestore Document ID</span>
                    <span class="detail-val"><code>${member.docId}</code></span>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline btn-sm" id="modal-close-btn">Close</button>
            </div>
        </div>
    `);

    modalContainer.style.display = "flex";

    // Bind Close Handlers
    const closeX = document.getElementById("close-modal-btn");
    const closeBtn = document.getElementById("modal-close-btn");

    const closeModal = () => {
        modalContainer.style.display = "none";
    };

    if (closeX) closeX.addEventListener("click", closeModal);
    if (closeBtn) closeBtn.addEventListener("click", closeModal);

    modalContainer.addEventListener("click", (e) => {
        if (e.target === modalContainer) {
            closeModal();
        }
    });
}
