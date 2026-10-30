// Phase 9: Personal Records Management Module (Read-Only Subcollections Handler)
import { db, setSafeHTML } from "./firebase.js";
import { collection, getDocs } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";

// DOM Reference
const contentArea = document.getElementById("content-area");

// Module State
let membersDirectory = [];
let selectedUserEmail = "";
let activeSubTab = "overview"; // 'overview', 'accounts', 'transactions', 'budgets', 'savings', 'debts'

// Cached User Subcollections Data
let userAccounts = [];
let userTransactions = [];
let userBudgets = [];
let userSavingsGoals = [];
let userDebts = [];

// Transactions Filter State
let txSearchQuery = "";
let txTypeFilter = "all";
let txStatusFilter = "all";
let txStartDate = "";
let txEndDate = "";
let txPage = 1;
const txPageSize = 10;

// Format Money Helper (1 Taka = 100 Paisa)
function formatTaka(paisa) {
    const taka = (paisa || 0) / 100;
    return `৳ ${taka.toLocaleString('en-IN', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;
}

// Format Date Helper
function formatDate(timestamp, dateString = "") {
    if (dateString && dateString.trim() !== "") return dateString;
    if (!timestamp) return "N/A";
    try {
        const d = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
        if (isNaN(d.getTime())) return dateString || "N/A";
        return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    } catch (e) {
        return dateString || "N/A";
    }
}

// Mask Account Number Helper (e.g. '01712345678' -> '****5678')
function maskAccountNumber(accNum) {
    if (!accNum || typeof accNum !== "string") return "N/A";
    const clean = accNum.trim();
    if (clean.length <= 4) return clean;
    return `****${clean.slice(-4)}`;
}

// Load and Initialize Personal Records Module
export async function loadWalletModule() {
    if (!contentArea) return;

    setSafeHTML(contentArea, `
        <div class="loading-box">
            <div class="spinner"></div>
            <p>Loading member directory for Personal Records...</p>
        </div>
    `);

    try {
        // 1. Fetch Members Directory for Member Selector
        const membersSnap = await getDocs(collection(db, "members"));
        membersDirectory = [];

        membersSnap.forEach((docSnap) => {
            const data = docSnap.data();
            const email = docSnap.id || data.email;
            if (email) {
                membersDirectory.push({
                    docId: docSnap.id,
                    name: data.name || email,
                    email: email,
                    role: (data.role || "member").toLowerCase(),
                    isAuthorized: data.isAuthorized === true
                });
            }
        });

        // Sort Members alphabetically
        membersDirectory.sort((a, b) => a.name.localeCompare(b.name));

        if (membersDirectory.length === 0) {
            setSafeHTML(contentArea, `
                <div class="placeholder-tab">
                    <h2>Personal Records</h2>
                    <p>No member profiles found in <code>members</code> collection.</p>
                </div>
            `);
            return;
        }

        // Default to first member if none selected
        if (!selectedUserEmail || !membersDirectory.some(m => m.email === selectedUserEmail)) {
            selectedUserEmail = membersDirectory[0].email;
        }

        // Load Selected User's Subcollections
        await loadUserData(selectedUserEmail);

    } catch (error) {
        console.error("Error initializing Personal Records module:", error);
        setSafeHTML(contentArea, `
            <div class="error-msg visible" style="margin-top: 0;">
                <strong>Error Loading Module:</strong> ${error.message || "Failed to initialize Personal Records module."}
            </div>
        `);
    }
}

// Fetch all 5 Subcollections for Selected Member: /personal_records/{userEmail}/...
async function loadUserData(userEmail) {
    if (!contentArea) return;

    renderMemberSelectorShell("Loading member's personal records...");

    try {
        // Clear subcollections cache
        userAccounts = [];
        userTransactions = [];
        userBudgets = [];
        userSavingsGoals = [];
        userDebts = [];

        // Fetch Subcollection: personalAccounts
        try {
            const accSnap = await getDocs(collection(db, "personal_records", userEmail, "personalAccounts"));
            accSnap.forEach(d => userAccounts.push({ docId: d.id, ...d.data() }));
        } catch (e) {
            console.warn("personalAccounts fetch info:", e.message);
        }

        // Fetch Subcollection: transactions
        try {
            const txSnap = await getDocs(collection(db, "personal_records", userEmail, "transactions"));
            txSnap.forEach(d => userTransactions.push({ docId: d.id, ...d.data() }));
            // Sort Transactions newest first
            userTransactions.sort((a, b) => {
                const dateA = a.transactionDate?.toDate ? a.transactionDate.toDate() : new Date(a.createdAt || 0);
                const dateB = b.transactionDate?.toDate ? b.transactionDate.toDate() : new Date(b.createdAt || 0);
                return dateB - dateA;
            });
        } catch (e) {
            console.warn("transactions fetch info:", e.message);
        }

        // Fetch Subcollection: personalBudgets
        try {
            const bgtSnap = await getDocs(collection(db, "personal_records", userEmail, "personalBudgets"));
            bgtSnap.forEach(d => userBudgets.push({ docId: d.id, ...d.data() }));
        } catch (e) {
            console.warn("personalBudgets fetch info:", e.message);
        }

        // Fetch Subcollection: savingsGoals
        try {
            const svgSnap = await getDocs(collection(db, "personal_records", userEmail, "savingsGoals"));
            svgSnap.forEach(d => userSavingsGoals.push({ docId: d.id, ...d.data() }));
        } catch (e) {
            console.warn("savingsGoals fetch info:", e.message);
        }

        // Fetch Subcollection: debts
        try {
            const dbtSnap = await getDocs(collection(db, "personal_records", userEmail, "debts"));
            dbtSnap.forEach(d => userDebts.push({ docId: d.id, ...d.data() }));
        } catch (e) {
            console.warn("debts fetch info:", e.message);
        }

        // Reset Subtab Views
        renderActiveSubTabView();

    } catch (error) {
        console.error("Error loading user personal records:", error);
        renderMemberSelectorShell(`Error loading personal records: ${error.message}`);
    }
}

// Render Base Shell with Member Selector Bar & Sub-Tabs Bar
function renderMemberSelectorShell(statusMessage = "") {
    const selectedMember = membersDirectory.find(m => m.email === selectedUserEmail) || {
        name: selectedUserEmail,
        email: selectedUserEmail,
        role: "member",
        isAuthorized: true
    };

    let memberOptionsHTML = "";
    membersDirectory.forEach((m) => {
        const isSel = m.email === selectedUserEmail ? "selected" : "";
        memberOptionsHTML += `<option value="${m.email}" ${isSel}>${m.name} (${m.email})</option>`;
    });

    setSafeHTML(contentArea, `
        <!-- Member Selector Bar -->
        <div class="member-selector-bar">
            <div>
                <h3 style="font-size: 18px; font-weight: 700; color: var(--primary-dark);">Personal Records & Wallets</h3>
                <p style="font-size: 13px; color: var(--text-muted); margin-top: 2px;">Inspect 100% private personal financial records for selected member</p>
            </div>
            <div style="display: flex; align-items: center; gap: 10px;">
                <label style="font-size: 13.5px; font-weight: 700; color: var(--text-muted);">Select Member:</label>
                <select id="wallet-member-select" class="member-select">
                    ${memberOptionsHTML}
                </select>
            </div>
        </div>

        <!-- Sub-Tab Navigation Bar -->
        <div class="subtab-bar">
            <button class="subtab-btn ${activeSubTab === "overview" ? "active" : ""}" data-subtab="overview">Overview</button>
            <button class="subtab-btn ${activeSubTab === "accounts" ? "active" : ""}" data-subtab="accounts">Accounts (${userAccounts.length})</button>
            <button class="subtab-btn ${activeSubTab === "transactions" ? "active" : ""}" data-subtab="transactions">Transactions (${userTransactions.length})</button>
            <button class="subtab-btn ${activeSubTab === "budgets" ? "active" : ""}" data-subtab="budgets">Budgets (${userBudgets.length})</button>
            <button class="subtab-btn ${activeSubTab === "savings" ? "active" : ""}" data-subtab="savings">Savings Goals (${userSavingsGoals.length})</button>
            <button class="subtab-btn ${activeSubTab === "debts" ? "active" : ""}" data-subtab="debts">Debts (${userDebts.length})</button>
        </div>

        <!-- Dynamic Subtab Content Container -->
        <div id="subtab-content-area">
            ${statusMessage ? `<div class="loading-box"><div class="spinner"></div><p>${statusMessage}</p></div>` : ""}
        </div>
    `);

    // Bind Member Selector Change Listener
    const memberSelect = document.getElementById("wallet-member-select");
    if (memberSelect) {
        memberSelect.addEventListener("change", (e) => {
            selectedUserEmail = e.target.value;
            loadUserData(selectedUserEmail);
        });
    }

    // Bind Sub-Tab Navigation Listeners
    document.querySelectorAll(".subtab-btn").forEach((btn) => {
        btn.addEventListener("click", () => {
            document.querySelectorAll(".subtab-btn").forEach(b => b.classList.remove("active"));
            btn.classList.add("active");
            activeSubTab = btn.getAttribute("data-subtab");
            renderActiveSubTabView();
        });
    });
}

// Render Active Subtab Content inside #subtab-content-area
function renderActiveSubTabView() {
    renderMemberSelectorShell();
    const container = document.getElementById("subtab-content-area");
    if (!container) return;

    if (activeSubTab === "overview") {
        renderPersonalOverview(container);
    } else if (activeSubTab === "accounts") {
        renderPersonalAccounts(container);
    } else if (activeSubTab === "transactions") {
        renderPersonalTransactions(container);
    } else if (activeSubTab === "budgets") {
        renderPersonalBudgets(container);
    } else if (activeSubTab === "savings") {
        renderPersonalSavingsGoals(container);
    } else if (activeSubTab === "debts") {
        renderPersonalDebts(container);
    }
}

// 1. Personal Overview Subtab View
function renderPersonalOverview(container) {
    const activeAccounts = userAccounts.filter(a => a.isArchived !== true);
    const totalBalancePaisa = activeAccounts.reduce((sum, a) => sum + (a.currentBalancePaisa || 0), 0);

    let totalPostedIncomePaisa = 0;
    let totalPostedExpensePaisa = 0;
    let pendingTxCount = 0;

    userTransactions.forEach((tx) => {
        const amountPaisa = tx.amountPaisa || 0;
        const status = (tx.status || "posted").toLowerCase();
        const type = (tx.type || "expense").toLowerCase();

        if (status === "posted") {
            if (type === "income" || type === "refund" || type === "debt_received") {
                totalPostedIncomePaisa += amountPaisa;
            } else if (type === "expense" || type === "debt_repayment") {
                totalPostedExpensePaisa += amountPaisa;
            }
        } else if (status === "pending") {
            pendingTxCount++;
        }
    });

    let totalBorrowedPaisa = 0;
    let totalLentPaisa = 0;

    userDebts.forEach((d) => {
        const principal = d.principalAmountPaisa || 0;
        const repaid = d.repaidAmountPaisa || 0;
        const remaining = Math.max(0, principal - repaid);
        if (d.type === "borrowed") {
            totalBorrowedPaisa += remaining;
        } else if (d.type === "lent") {
            totalLentPaisa += remaining;
        }
    });

    const member = membersDirectory.find(m => m.email === selectedUserEmail) || { name: selectedUserEmail, email: selectedUserEmail };

    setSafeHTML(container, `
        <!-- Member Profile Header -->
        <div class="monthly-card" style="margin-bottom: 24px;">
            <h3>Member Personal Wallet Overview</h3>
            <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px;">
                <div>
                    <h2 style="font-size:22px; font-weight:800; color:#FFFFFF;">${member.name}</h2>
                    <p style="font-size:13px; color:#E0F2FE; margin-top:2px;">${member.email}</p>
                </div>
                <div style="text-align:right;">
                    <div style="font-size:12px; color:#94A3B8;">Total Active Balance</div>
                    <div style="font-size:28px; font-weight:800; color:#38BDF8;">${formatTaka(totalBalancePaisa)}</div>
                </div>
            </div>
        </div>

        <!-- Metrics Grid (6 Cards) -->
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Active Accounts</span>
                    <div class="card-icon icon-blue">💳</div>
                </div>
                <div class="card-value">${activeAccounts.length}</div>
                <div class="card-subtext">Active wallets & bank accounts</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Posted Income</span>
                    <div class="card-icon icon-green">📈</div>
                </div>
                <div class="card-value">${formatTaka(totalPostedIncomePaisa)}</div>
                <div class="card-subtext">Received income records</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Posted Expense</span>
                    <div class="card-icon icon-red">📉</div>
                </div>
                <div class="card-value">${formatTaka(totalPostedExpensePaisa)}</div>
                <div class="card-subtext">Personal expense records</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Savings Goals</span>
                    <div class="card-icon icon-cyan">🎯</div>
                </div>
                <div class="card-value">${userSavingsGoals.length}</div>
                <div class="card-subtext">Target savings goals count</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Outstanding Borrowed</span>
                    <div class="card-icon icon-amber">🔻</div>
                </div>
                <div class="card-value">${formatTaka(totalBorrowedPaisa)}</div>
                <div class="card-subtext">Money owed to contacts</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Outstanding Lent</span>
                    <div class="card-icon icon-indigo">🔺</div>
                </div>
                <div class="card-value">${formatTaka(totalLentPaisa)}</div>
                <div class="card-subtext">Money lent to contacts</div>
            </div>
        </div>
    `);
}

// 2. Personal Accounts Subtab View
function renderPersonalAccounts(container) {
    if (userAccounts.length === 0) {
        setSafeHTML(container, `
            <div class="table-card">
                <div class="empty-state">No personal accounts or wallets found for ${selectedUserEmail}.</div>
            </div>
        `);
        return;
    }

    let cardsHTML = "";
    userAccounts.forEach((acc) => {
        const typeClass = `type-${(acc.type || 'other').toLowerCase()}`;
        const isArchived = acc.isArchived === true;

        cardsHTML += `
            <div class="account-card" style="${isArchived ? 'opacity: 0.6;' : ''}">
                <div class="account-card-header">
                    <div class="account-card-title">${acc.name || 'Unnamed Account'}</div>
                    <span class="account-type-badge ${typeClass}">${acc.type || 'wallet'}</span>
                </div>
                <div class="account-balance-large">${formatTaka(acc.currentBalancePaisa)}</div>
                <div style="font-size: 12.5px; color: var(--text-muted); display:flex; justify-content:space-between;">
                    <span>Opening: ${formatTaka(acc.openingBalancePaisa)}</span>
                    <span>No: ${maskAccountNumber(acc.accountNumber)}</span>
                </div>
                <div style="font-size: 11.5px; color: var(--text-muted); display:flex; justify-content:space-between; margin-top:4px;">
                    <span>Currency: ${acc.currency || 'BDT'}</span>
                    <span>Status: <strong>${isArchived ? 'Archived' : 'Active'}</strong></span>
                </div>
            </div>
        `;
    });

    setSafeHTML(container, `
        <div class="account-card-grid">
            ${cardsHTML}
        </div>
    `);
}

// 3. Personal Transactions Subtab View
function renderPersonalTransactions(container) {
    let typeOptionsHTML = `
        <option value="all">All Types</option>
        <option value="income">Income</option>
        <option value="expense">Expense</option>
        <option value="transfer">Transfer</option>
        <option value="refund">Refund</option>
        <option value="debt_received">Debt Received</option>
        <option value="debt_repayment">Debt Repayment</option>
        <option value="savings_contribution">Savings Contribution</option>
        <option value="savings_withdrawal">Savings Withdrawal</option>
        <option value="adjustment">Adjustment</option>
    `;

    setSafeHTML(container, `
        <div class="filter-bar">
            <input
                type="text"
                id="tx-search-input"
                class="search-input"
                placeholder="🔍 Search Description, Category, Source ID..."
                value="${txSearchQuery}"
            />

            <select id="tx-type-filter" class="select-filter">
                ${typeOptionsHTML}
            </select>

            <select id="tx-status-filter" class="select-filter">
                <option value="all" ${txStatusFilter === "all" ? "selected" : ""}>All Statuses</option>
                <option value="posted" ${txStatusFilter === "posted" ? "selected" : ""}>Posted</option>
                <option value="pending" ${txStatusFilter === "pending" ? "selected" : ""}>Pending</option>
                <option value="cancelled" ${txStatusFilter === "cancelled" ? "selected" : ""}>Cancelled</option>
            </select>

            <div class="date-group">
                <label>From:</label>
                <input type="date" id="tx-start-date" class="date-input" value="${txStartDate}" />
                <label>To:</label>
                <input type="date" id="tx-end-date" class="date-input" value="${txEndDate}" />
            </div>
        </div>

        <div class="table-card">
            <div class="card-header-row" style="margin-bottom: 16px;">
                <h4>Personal Transactions Records (<span id="tx-filtered-count">${userTransactions.length}</span>)</h4>
            </div>

            <div class="table-responsive">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th style="width: 50px;">#</th>
                            <th>Date</th>
                            <th>Type</th>
                            <th>Category</th>
                            <th>Description</th>
                            <th>Amount</th>
                            <th>Source Account</th>
                            <th>Status</th>
                            <th style="width: 100px; text-align: right;">Action</th>
                        </tr>
                    </thead>
                    <tbody id="tx-table-body">
                        <!-- Injected via applyTxFilters() -->
                    </tbody>
                </table>
            </div>

            <!-- Pagination Bar -->
            <div class="pagination-bar">
                <div class="page-info" id="tx-pagination-info">Showing 0-0 of 0</div>
                <div class="pagination-controls">
                    <button class="btn btn-outline btn-sm" id="prev-tx-btn" disabled>Previous</button>
                    <span class="page-info" id="current-tx-page-label">Page 1</span>
                    <button class="btn btn-outline btn-sm" id="next-tx-btn" disabled>Next</button>
                </div>
            </div>
        </div>

        <div id="tx-details-modal" class="modal-backdrop" style="display: none;"></div>
    `);

    // Set select values
    const typeSelect = document.getElementById("tx-type-filter");
    if (typeSelect) typeSelect.value = txTypeFilter;

    // Bind Filter Event Listeners
    const searchInput = document.getElementById("tx-search-input");
    const statusSelect = document.getElementById("tx-status-filter");
    const startDateInput = document.getElementById("tx-start-date");
    const endDateInput = document.getElementById("tx-end-date");

    if (searchInput) searchInput.addEventListener("input", e => { txSearchQuery = e.target.value.trim().toLowerCase(); txPage = 1; applyTxFilters(); });
    if (typeSelect) typeSelect.addEventListener("change", e => { txTypeFilter = e.target.value; txPage = 1; applyTxFilters(); });
    if (statusSelect) statusSelect.addEventListener("change", e => { txStatusFilter = e.target.value; txPage = 1; applyTxFilters(); });
    if (startDateInput) startDateInput.addEventListener("change", e => { txStartDate = e.target.value; txPage = 1; applyTxFilters(); });
    if (endDateInput) endDateInput.addEventListener("change", e => { txEndDate = e.target.value; txPage = 1; applyTxFilters(); });

    // Pagination Listeners
    const prevBtn = document.getElementById("prev-tx-btn");
    const nextBtn = document.getElementById("next-tx-btn");

    if (prevBtn) prevBtn.addEventListener("click", () => { if (txPage > 1) { txPage--; renderTxTableRows(); } });
    if (nextBtn) nextBtn.addEventListener("click", () => { const maxP = Math.ceil(getFilteredTransactions().length / txPageSize) || 1; if (txPage < maxP) { txPage++; renderTxTableRows(); } });

    applyTxFilters();
}

function getFilteredTransactions() {
    return userTransactions.filter((tx) => {
        const desc = (tx.description || "").toLowerCase();
        const cat = (tx.categoryName || "").toLowerCase();
        const src = (tx.sourceAccountId || "").toLowerCase();
        const typeStr = (tx.type || "").toLowerCase();

        const matchesSearch = desc.includes(txSearchQuery) || cat.includes(txSearchQuery) || src.includes(txSearchQuery) || typeStr.includes(txSearchQuery);

        let matchesType = true;
        if (txTypeFilter !== "all") matchesType = typeStr === txTypeFilter;

        let matchesStatus = true;
        if (txStatusFilter !== "all") matchesStatus = (tx.status || "posted").toLowerCase() === txStatusFilter;

        let matchesDate = true;
        const txDateStr = tx.transactionDate ? (tx.transactionDate.toDate ? tx.transactionDate.toDate().toISOString().split('T')[0] : "") : "";
        if (txStartDate && txDateStr && txDateStr < txStartDate) matchesDate = false;
        if (txEndDate && txDateStr && txDateStr > txEndDate) matchesDate = false;

        return matchesSearch && matchesType && matchesStatus && matchesDate;
    });
}

function applyTxFilters() {
    txPage = 1;
    renderTxTableRows();
}

function renderTxTableRows() {
    const tbody = document.getElementById("tx-table-body");
    const countEl = document.getElementById("tx-filtered-count");
    const paginationInfoEl = document.getElementById("tx-pagination-info");
    const pageLabelEl = document.getElementById("current-tx-page-label");
    const prevBtn = document.getElementById("prev-tx-btn");
    const nextBtn = document.getElementById("next-tx-btn");

    const filtered = getFilteredTransactions();
    const total = filtered.length;

    if (countEl) countEl.textContent = total;
    if (!tbody) return;

    if (total === 0) {
        setSafeHTML(tbody, `<tr><td colspan="9" class="empty-state">No transactions found matching selected filters.</td></tr>`);
        if (paginationInfoEl) paginationInfoEl.textContent = "Showing 0-0 of 0";
        if (pageLabelEl) pageLabelEl.textContent = "Page 1";
        if (prevBtn) prevBtn.disabled = true;
        if (nextBtn) nextBtn.disabled = true;
        return;
    }

    const maxPage = Math.ceil(total / txPageSize) || 1;
    if (txPage > maxPage) txPage = maxPage;

    const start = (txPage - 1) * txPageSize;
    const end = Math.min(start + txPageSize, total);
    const paginated = filtered.slice(start, end);

    if (paginationInfoEl) paginationInfoEl.textContent = `Showing ${start + 1}-${end} of ${total}`;
    if (pageLabelEl) pageLabelEl.textContent = `Page ${txPage} of ${maxPage}`;
    if (prevBtn) prevBtn.disabled = txPage === 1;
    if (nextBtn) nextBtn.disabled = txPage === maxPage;

    let rowsHTML = "";
    paginated.forEach((tx, idx) => {
        const serialNo = start + idx + 1;
        const statusClass = `tx-${(tx.status || 'posted').toLowerCase()}`;
        const typeBadge = `<span class="badge" style="background:#F1F5F9; color:#1E293B;">${(tx.type || 'expense').toUpperCase()}</span>`;

        rowsHTML += `
            <tr style="cursor: pointer;" class="tx-row" data-id="${tx.docId}">
                <td><strong>${serialNo}</strong></td>
                <td>${formatDate(tx.transactionDate)}</td>
                <td>${typeBadge}</td>
                <td>${tx.categoryName || 'General'}</td>
                <td><strong>${tx.description || 'Transaction'}</strong></td>
                <td><strong>${formatTaka(tx.amountPaisa)}</strong></td>
                <td><code>${tx.sourceAccountId || 'N/A'}</code></td>
                <td><span class="status-pill ${statusClass}">${tx.status || 'posted'}</span></td>
                <td style="text-align: right;">
                    <button class="btn btn-outline btn-sm view-tx-details-btn" data-id="${tx.docId}">
                        View Details
                    </button>
                </td>
            </tr>
        `;
    });

    setSafeHTML(tbody, rowsHTML);

    // Attach Details Click Handlers
    document.querySelectorAll(".view-tx-details-btn").forEach((btn) => {
        btn.addEventListener("click", (e) => {
            e.stopPropagation();
            showTxDetailsModal(btn.getAttribute("data-id"));
        });
    });

    document.querySelectorAll(".tx-row").forEach((row) => {
        row.addEventListener("click", () => {
            showTxDetailsModal(row.getAttribute("data-id"));
        });
    });
}

function showTxDetailsModal(txId) {
    const tx = userTransactions.find(t => t.docId === txId);
    if (!tx) return;

    const modal = document.getElementById("tx-details-modal");
    if (!modal) return;

    const receiptHTML = tx.receiptUrl
        ? `<a href="${tx.receiptUrl}" target="_blank" rel="noopener noreferrer" style="color:var(--accent-color); font-weight:bold;">View Receipt Photo 🔗</a>`
        : "No Receipt Attached";

    setSafeHTML(modal, `
        <div class="modal-box">
            <div class="modal-header">
                <h3>Personal Transaction Details</h3>
                <button class="close-btn" id="close-tx-modal-btn">&times;</button>
            </div>
            <div class="modal-body">
                <div class="detail-row"><span class="detail-label">Transaction Doc ID</span><span class="detail-val"><code>${tx.docId}</code></span></div>
                <div class="detail-row"><span class="detail-label">Type</span><span class="detail-val"><strong>${(tx.type || 'expense').toUpperCase()}</strong></span></div>
                <div class="detail-row"><span class="detail-label">Amount</span><span class="detail-val" style="font-size:18px; color:var(--primary-dark);">${formatTaka(tx.amountPaisa)}</span></div>
                <div class="detail-row"><span class="detail-label">Category</span><span class="detail-val">${tx.categoryName || 'General'} (${tx.categoryId || 'N/A'})</span></div>
                <div class="detail-row"><span class="detail-label">Description</span><span class="detail-val">${tx.description || 'N/A'}</span></div>
                <div class="detail-row"><span class="detail-label">Source Account</span><span class="detail-val"><code>${tx.sourceAccountId || 'N/A'}</code></span></div>
                ${tx.destinationAccountId ? `<div class="detail-row"><span class="detail-label">Destination Account</span><span class="detail-val"><code>${tx.destinationAccountId}</code></span></div>` : ''}
                <div class="detail-row"><span class="detail-label">Status</span><span class="detail-val"><span class="status-pill tx-${(tx.status || 'posted').toLowerCase()}">${tx.status || 'posted'}</span></span></div>
                <div class="detail-row"><span class="detail-label">Notes</span><span class="detail-val">${tx.notes || 'N/A'}</span></div>
                <div class="detail-row"><span class="detail-label">Receipt</span><span class="detail-val">${receiptHTML}</span></div>
                <div class="detail-row"><span class="detail-label">Transaction Date</span><span class="detail-val">${formatDate(tx.transactionDate)}</span></div>
                <div class="detail-row"><span class="detail-label">Created At</span><span class="detail-val">${formatDate(tx.createdAt)}</span></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline btn-sm" id="modal-close-tx-btn">Close</button>
            </div>
        </div>
    `);

    modal.style.display = "flex";

    const closeX = document.getElementById("close-tx-modal-btn");
    const closeBtn = document.getElementById("modal-close-tx-btn");

    const closeModal = () => modal.style.display = "none";
    if (closeX) closeX.addEventListener("click", closeModal);
    if (closeBtn) closeBtn.addEventListener("click", closeModal);
    modal.addEventListener("click", e => { if (e.target === modal) closeModal(); });
}

// 4. Personal Budgets Subtab View
function renderPersonalBudgets(container) {
    if (userBudgets.length === 0) {
        setSafeHTML(container, `<div class="table-card"><div class="empty-state">No personal budgets found for ${selectedUserEmail}.</div></div>`);
        return;
    }

    let rowsHTML = "";
    userBudgets.forEach((b, idx) => {
        const thresholds = Array.isArray(b.alertThresholds) ? b.alertThresholds.map(t => `${Math.round(t * 100)}%`).join(", ") : "50%, 75%, 90%, 100%";

        rowsHTML += `
            <tr>
                <td><strong>${idx + 1}</strong></td>
                <td><strong>${b.budgetName || 'Category Budget'}</strong></td>
                <td>${b.categoryName || 'General'}</td>
                <td><span class="badge" style="background:#E0F2FE; color:#0369A1;">${b.monthId || 'N/A'}</span></td>
                <td><strong>${formatTaka(b.budgetAmountPaisa)}</strong></td>
                <td>${b.period || 'monthly'}</td>
                <td>${b.rollover ? 'Yes' : 'No'}</td>
                <td><small style="color:var(--text-muted);">${thresholds}</small></td>
                <td>${formatDate(b.createdAt)}</td>
            </tr>
        `;
    });

    setSafeHTML(container, `
        <div class="table-card">
            <div class="card-header-row" style="margin-bottom: 16px;">
                <h4>Personal Budgets Directory (${userBudgets.length})</h4>
            </div>
            <div class="table-responsive">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th style="width: 50px;">#</th>
                            <th>Budget Name</th>
                            <th>Category</th>
                            <th>Month ID</th>
                            <th>Budget Limit</th>
                            <th>Period</th>
                            <th>Rollover</th>
                            <th>Alert Thresholds</th>
                            <th>Created At</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${rowsHTML}
                    </tbody>
                </table>
            </div>
        </div>
    `);
}

// 5. Personal Savings Goals Subtab View
function renderPersonalSavingsGoals(container) {
    if (userSavingsGoals.length === 0) {
        setSafeHTML(container, `<div class="table-card"><div class="empty-state">No savings goals found for ${selectedUserEmail}.</div></div>`);
        return;
    }

    let cardsHTML = "";
    userSavingsGoals.forEach((goal) => {
        const targetPaisa = goal.targetAmountPaisa || 0;
        const savedPaisa = goal.currentSavedPaisa || 0;
        const remainingPaisa = Math.max(0, targetPaisa - savedPaisa);
        const pct = targetPaisa > 0 ? Math.min(100, Math.round((savedPaisa / targetPaisa) * 100)) : 0;

        cardsHTML += `
            <div class="account-card">
                <div class="account-card-header">
                    <div class="account-card-title">${goal.goalName || 'Savings Goal'}</div>
                    <span class="status-pill status-confirmed">${goal.status || 'active'}</span>
                </div>
                <div class="account-balance-large" style="color:var(--success-color);">${formatTaka(savedPaisa)} <small style="font-size:13px; color:var(--text-muted);">/ ${formatTaka(targetPaisa)}</small></div>
                <div class="comparison-bar-bg">
                    <div class="comparison-bar-fill" style="width: ${pct}%;"></div>
                </div>
                <div style="font-size:12.5px; color:var(--text-muted); display:flex; justify-content:space-between; margin-top:6px;">
                    <span>Remaining: <strong>${formatTaka(remainingPaisa)}</strong></span>
                    <span>Progress: <strong>${pct}%</strong></span>
                </div>
                <div style="font-size:11.5px; color:var(--text-muted); display:flex; justify-content:space-between; margin-top:4px;">
                    <span>Target Date: ${formatDate(goal.targetDate)}</span>
                    <span>Linked Account: <code>${goal.linkedAccountId || 'N/A'}</code></span>
                </div>
            </div>
        `;
    });

    setSafeHTML(container, `
        <div class="account-card-grid">
            ${cardsHTML}
        </div>
    `);
}

// 6. Personal Debts Subtab View
function renderPersonalDebts(container) {
    if (userDebts.length === 0) {
        setSafeHTML(container, `<div class="table-card"><div class="empty-state">No debt records found for ${selectedUserEmail}.</div></div>`);
        return;
    }

    let cardsHTML = "";
    userDebts.forEach((debt) => {
        const principal = debt.principalAmountPaisa || 0;
        const repaid = debt.repaidAmountPaisa || 0;
        const remaining = Math.max(0, principal - repaid);
        const isBorrowed = (debt.type || "borrowed").toLowerCase() === "borrowed";
        const cardClass = isBorrowed ? "debt-card-borrowed" : "debt-card-lent";
        const typeBadge = isBorrowed
            ? `<span class="badge" style="background:#FEE2E2; color:#991B1B;">Borrowed (I Owe)</span>`
            : `<span class="badge" style="background:#D1FAE5; color:#065F46;">Lent (They Owe Me)</span>`;

        cardsHTML += `
            <div class="account-card ${cardClass}">
                <div class="account-card-header">
                    <div class="account-card-title">${debt.contactName || 'Unknown Contact'}</div>
                    ${typeBadge}
                </div>
                <div style="font-size:12.5px; color:var(--text-muted);">Phone: ${debt.contactPhone || 'N/A'}</div>
                <div class="account-balance-large" style="color: ${isBorrowed ? 'var(--danger-color)' : 'var(--success-color)'};">
                    ${formatTaka(remaining)} <small style="font-size:13px; color:var(--text-muted);">remaining</small>
                </div>
                <div style="font-size:12.5px; color:var(--text-muted); display:flex; justify-content:space-between;">
                    <span>Principal: ${formatTaka(principal)}</span>
                    <span>Repaid: ${formatTaka(repaid)}</span>
                </div>
                <div style="font-size:11.5px; color:var(--text-muted); display:flex; justify-content:space-between; margin-top:4px;">
                    <span>Status: <strong>${debt.status || 'outstanding'}</strong></span>
                    <span>Due Date: ${formatDate(debt.dueDate)}</span>
                </div>
                ${debt.notes ? `<div style="font-size:12px; color:var(--text-muted); background:#F8FAFC; padding:8px; border-radius:6px; margin-top:6px;">Notes: ${debt.notes}</div>` : ''}
            </div>
        `;
    });

    setSafeHTML(container, `
        <div class="account-card-grid">
            ${cardsHTML}
        </div>
    `);
}
