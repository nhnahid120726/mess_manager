// Phase 7: Deposits Management Module (Read-Only Directory & Financial Analytics)
import { db, setSafeHTML } from "./firebase.js";
import { collection, getDocs } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";

// DOM Reference
const contentArea = document.getElementById("content-area");

// Local Module State
let allDepositsList = [];
let filteredDepositsList = [];
let memberMap = {}; // email -> name lookup map

// Filter States
let searchQuery = "";
let statusFilter = "all";
let methodFilter = "all";
let monthFilter = "all";
let startDateFilter = "";
let endDateFilter = "";

// Pagination State
let currentPage = 1;
const pageSize = 10;

// Format Money Helper (1 Taka = 100 Paisa)
function formatTaka(paisa) {
    const taka = (paisa || 0) / 100;
    return `৳ ${taka.toLocaleString('en-IN', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;
}

// Format Date Helper
function formatDate(timestamp) {
    if (!timestamp) return "N/A";
    try {
        const d = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
        if (isNaN(d.getTime())) return "N/A";
        return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    } catch (e) {
        return "N/A";
    }
}

// Current Month Helper (YYYY-MM)
function getCurrentMonthId() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    return `${year}-${month}`;
}

// Status Display Badge Mapping
function getStatusBadge(status) {
    const s = (status || "").toLowerCase();
    if (s === "confirmed") {
        return `<span class="status-pill status-confirmed">Confirmed</span>`;
    } else if (s === "pending") {
        return `<span class="status-pill status-pending">Pending</span>`;
    } else if (s === "rejected") {
        return `<span class="status-pill status-rejected">Rejected</span>`;
    } else {
        return `<span class="status-pill status-unknown">${status || "Unknown"}</span>`;
    }
}

// Load and Process Deposits Module
export async function loadDepositsModule() {
    if (!contentArea) return;

    setSafeHTML(contentArea, `
        <div class="loading-box">
            <div class="spinner"></div>
            <p>Fetching deposit records from Firestore...</p>
        </div>
    `);

    try {
        // 1. Load Members for Email -> Name Mapping if not loaded yet
        if (Object.keys(memberMap).length === 0) {
            const membersSnap = await getDocs(collection(db, "members"));
            membersSnap.forEach((docSnap) => {
                const data = docSnap.data();
                if (data.name) memberMap[docSnap.id || data.email] = data.name;
            });
        }

        // 2. Fetch 'deposits' Collection
        const depositsSnap = await getDocs(collection(db, "deposits"));
        allDepositsList = [];
        const monthSet = new Set();
        const methodSet = new Set();

        depositsSnap.forEach((docSnap) => {
            const data = docSnap.data() || {};
            const monthId = data.monthId || "";
            const method = data.paymentMethod || "Cash";
            const status = (data.status || "pending").toLowerCase();

            if (monthId) monthSet.add(monthId);
            if (method) methodSet.add(method);

            allDepositsList.push({
                docId: docSnap.id,
                monthId: monthId,
                memberEmail: data.memberEmail || "",
                amountInPaisa: typeof data.amountInPaisa === "number" ? data.amountInPaisa : 0,
                paymentMethod: method,
                status: status,
                confirmedByAdminEmail: data.confirmedByAdminEmail || "",
                createdAt: data.createdAt || null
            });
        });

        // Sort Deposits (Newest date first)
        allDepositsList.sort((a, b) => {
            const dateA = a.createdAt?.toDate ? a.createdAt.toDate() : new Date(0);
            const dateB = b.createdAt?.toDate ? b.createdAt.toDate() : new Date(0);
            return dateB - dateA;
        });

        const availableMonths = Array.from(monthSet).sort().reverse();
        const availableMethods = Array.from(methodSet).sort();

        // Render Page Structure
        renderDepositsUI(availableMonths, availableMethods);

    } catch (error) {
        console.error("Error loading deposits collection:", error);
        setSafeHTML(contentArea, `
            <div class="error-msg visible" style="margin-top: 0;">
                <strong>Error Loading Deposits:</strong> ${error.message || "Failed to fetch 'deposits' collection from Firestore."}
            </div>
        `);
    }
}

// Render Main Deposits Page UI
function renderDepositsUI(availableMonths, availableMethods) {
    const currentMonthId = getCurrentMonthId();

    // Calculate Summary Metrics
    let totalDepositsPaisa = 0;
    let confirmedDepositsPaisa = 0;
    let pendingDepositsPaisa = 0;
    let rejectedDepositsPaisa = 0;
    let currentMonthDepositsPaisa = 0;
    const totalTransactions = allDepositsList.length;

    allDepositsList.forEach((dep) => {
        const amountPaisa = dep.amountInPaisa || 0;
        totalDepositsPaisa += amountPaisa;

        if (dep.status === "confirmed") {
            confirmedDepositsPaisa += amountPaisa;
            if (dep.monthId === currentMonthId) {
                currentMonthDepositsPaisa += amountPaisa;
            }
        } else if (dep.status === "pending") {
            pendingDepositsPaisa += amountPaisa;
        } else if (dep.status === "rejected") {
            rejectedDepositsPaisa += amountPaisa;
        }
    });

    // Build Month Filter Options
    let monthOptionsHTML = `<option value="all">All Months</option>`;
    availableMonths.forEach((m) => {
        monthOptionsHTML += `<option value="${m}" ${monthFilter === m ? "selected" : ""}>${m}</option>`;
    });

    // Build Method Filter Options
    let methodOptionsHTML = `<option value="all">All Payment Methods</option>`;
    availableMethods.forEach((meth) => {
        methodOptionsHTML += `<option value="${meth}" ${methodFilter === meth ? "selected" : ""}>${meth}</option>`;
    });

    setSafeHTML(contentArea, `
        <!-- Summary Cards (6 Cards) -->
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Deposits</span>
                    <div class="card-icon icon-blue">📂</div>
                </div>
                <div class="card-value">${formatTaka(totalDepositsPaisa)}</div>
                <div class="card-subtext">All submitted deposits combined</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Confirmed Deposits</span>
                    <div class="card-icon icon-green">✅</div>
                </div>
                <div class="card-value">${formatTaka(confirmedDepositsPaisa)}</div>
                <div class="card-subtext">Approved and added to mess fund</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Pending Deposits</span>
                    <div class="card-icon icon-amber">⏳</div>
                </div>
                <div class="card-value">${formatTaka(pendingDepositsPaisa)}</div>
                <div class="card-subtext">Awaiting admin review</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Rejected Deposits</span>
                    <div class="card-icon icon-red">🚫</div>
                </div>
                <div class="card-value">${formatTaka(rejectedDepositsPaisa)}</div>
                <div class="card-subtext">Cancelled or rejected requests</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Records</span>
                    <div class="card-icon icon-indigo">📊</div>
                </div>
                <div class="card-value">${totalTransactions}</div>
                <div class="card-subtext">Total deposit entries count</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Current Month (${currentMonthId})</span>
                    <div class="card-icon icon-cyan">📅</div>
                </div>
                <div class="card-value">${formatTaka(currentMonthDepositsPaisa)}</div>
                <div class="card-subtext">Confirmed deposits in current month</div>
            </div>
        </div>

        <!-- Search & Filter Controls -->
        <div class="filter-bar">
            <input
                type="text"
                id="deposit-search-input"
                class="search-input"
                placeholder="🔍 Search Member, Email, Method, or Status..."
                value="${searchQuery}"
            />

            <select id="deposit-status-filter" class="select-filter">
                <option value="all" ${statusFilter === "all" ? "selected" : ""}>All Statuses</option>
                <option value="confirmed" ${statusFilter === "confirmed" ? "selected" : ""}>Confirmed</option>
                <option value="pending" ${statusFilter === "pending" ? "selected" : ""}>Pending</option>
                <option value="rejected" ${statusFilter === "rejected" ? "selected" : ""}>Rejected</option>
            </select>

            <select id="deposit-method-filter" class="select-filter">
                ${methodOptionsHTML}
            </select>

            <select id="deposit-month-filter" class="select-filter">
                ${monthOptionsHTML}
            </select>

            <div class="date-group">
                <label>From:</label>
                <input type="date" id="deposit-start-date" class="date-input" value="${startDateFilter}" />
                <label>To:</label>
                <input type="date" id="deposit-end-date" class="date-input" value="${endDateFilter}" />
            </div>
        </div>

        <!-- Table Card -->
        <div class="table-card">
            <div class="card-header-row" style="margin-bottom: 16px;">
                <h4>Deposits Directory (<span id="filtered-count">${totalTransactions}</span>)</h4>
            </div>

            <div class="table-responsive">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th style="width: 50px;">#</th>
                            <th>Member Name</th>
                            <th>Member Email</th>
                            <th>Month</th>
                            <th>Amount</th>
                            <th>Method</th>
                            <th>Status</th>
                            <th>Deposit Date</th>
                            <th>Confirmed By</th>
                            <th style="width: 110px; text-align: right;">Action</th>
                        </tr>
                    </thead>
                    <tbody id="deposits-table-body">
                        <!-- Rows injected via applyDepositFilters() -->
                    </tbody>
                </table>
            </div>

            <!-- Pagination Bar -->
            <div class="pagination-bar">
                <div class="page-info" id="deposit-pagination-info">Showing 0-0 of 0</div>
                <div class="pagination-controls">
                    <button class="btn btn-outline btn-sm" id="prev-deposit-btn" disabled>Previous</button>
                    <span class="page-info" id="current-deposit-page-label">Page 1</span>
                    <button class="btn btn-outline btn-sm" id="next-deposit-btn" disabled>Next</button>
                </div>
            </div>
        </div>

        <!-- Details Modal Container -->
        <div id="deposit-details-modal" class="modal-backdrop" style="display: none;"></div>
    `);

    // Bind Filter Listeners
    const searchInput = document.getElementById("deposit-search-input");
    const statusSelect = document.getElementById("deposit-status-filter");
    const methodSelect = document.getElementById("deposit-method-filter");
    const monthSelect = document.getElementById("deposit-month-filter");
    const startDateInput = document.getElementById("deposit-start-date");
    const endDateInput = document.getElementById("deposit-end-date");

    if (searchInput) {
        searchInput.addEventListener("input", (e) => {
            searchQuery = e.target.value.trim().toLowerCase();
            currentPage = 1;
            applyDepositFilters();
        });
    }

    if (statusSelect) {
        statusSelect.addEventListener("change", (e) => {
            statusFilter = e.target.value;
            currentPage = 1;
            applyDepositFilters();
        });
    }

    if (methodSelect) {
        methodSelect.addEventListener("change", (e) => {
            methodFilter = e.target.value;
            currentPage = 1;
            applyDepositFilters();
        });
    }

    if (monthSelect) {
        monthSelect.addEventListener("change", (e) => {
            monthFilter = e.target.value;
            currentPage = 1;
            applyDepositFilters();
        });
    }

    if (startDateInput) {
        startDateInput.addEventListener("change", (e) => {
            startDateFilter = e.target.value;
            currentPage = 1;
            applyDepositFilters();
        });
    }

    if (endDateInput) {
        endDateInput.addEventListener("change", (e) => {
            endDateFilter = e.target.value;
            currentPage = 1;
            applyDepositFilters();
        });
    }

    // Bind Pagination Listeners
    const prevBtn = document.getElementById("prev-deposit-btn");
    const nextBtn = document.getElementById("next-deposit-btn");

    if (prevBtn) {
        prevBtn.addEventListener("click", () => {
            if (currentPage > 1) {
                currentPage--;
                renderDepositTableRows();
            }
        });
    }

    if (nextBtn) {
        nextBtn.addEventListener("click", () => {
            const maxPage = Math.ceil(filteredDepositsList.length / pageSize) || 1;
            if (currentPage < maxPage) {
                currentPage++;
                renderDepositTableRows();
            }
        });
    }

    // Apply Initial Filters & Render Table
    applyDepositFilters();
}

// Apply Search & Filter Conditions
function applyDepositFilters() {
    filteredDepositsList = allDepositsList.filter((dep) => {
        const memberName = (memberMap[dep.memberEmail] || dep.memberEmail).toLowerCase();
        const emailStr = dep.memberEmail.toLowerCase();
        const methodStr = dep.paymentMethod.toLowerCase();
        const monthStr = dep.monthId.toLowerCase();
        const statusStr = dep.status.toLowerCase();

        // 1. Search Matching
        const matchesSearch =
            memberName.includes(searchQuery) ||
            emailStr.includes(searchQuery) ||
            methodStr.includes(searchQuery) ||
            monthStr.includes(searchQuery) ||
            statusStr.includes(searchQuery);

        // 2. Status Filter Matching
        let matchesStatus = true;
        if (statusFilter !== "all") {
            matchesStatus = dep.status === statusFilter;
        }

        // 3. Payment Method Filter Matching
        let matchesMethod = true;
        if (methodFilter !== "all") {
            matchesMethod = dep.paymentMethod === methodFilter;
        }

        // 4. Month Filter Matching
        let matchesMonth = true;
        if (monthFilter !== "all") {
            matchesMonth = dep.monthId === monthFilter;
        }

        // 5. Date Range Matching (Based on createdAt)
        let matchesDate = true;
        let recordDateObj = null;

        if (dep.createdAt) {
            try {
                recordDateObj = dep.createdAt.toDate ? dep.createdAt.toDate() : new Date(dep.createdAt);
            } catch (e) {
                recordDateObj = null;
            }
        }

        if (recordDateObj && !isNaN(recordDateObj.getTime())) {
            if (startDateFilter) {
                const startObj = new Date(`${startDateFilter}T00:00:00`);
                if (recordDateObj < startObj) matchesDate = false;
            }
            if (endDateFilter) {
                const endObj = new Date(`${endDateFilter}T23:59:59.999`);
                if (recordDateObj > endObj) matchesDate = false;
            }
        }

        return matchesSearch && matchesStatus && matchesMethod && matchesMonth && matchesDate;
    });

    currentPage = 1;
    renderDepositTableRows();
}

// Render Table Rows with Pagination
function renderDepositTableRows() {
    const tbody = document.getElementById("deposits-table-body");
    const filteredCountEl = document.getElementById("filtered-count");
    const paginationInfoEl = document.getElementById("deposit-pagination-info");
    const currentPageLabelEl = document.getElementById("current-deposit-page-label");
    const prevBtn = document.getElementById("prev-deposit-btn");
    const nextBtn = document.getElementById("next-deposit-btn");

    const totalFiltered = filteredDepositsList.length;

    if (filteredCountEl) {
        filteredCountEl.textContent = totalFiltered;
    }

    if (!tbody) return;

    if (totalFiltered === 0) {
        setSafeHTML(tbody, `
            <tr>
                <td colspan="10" class="empty-state">
                    No deposit records found matching the selected filters.
                </td>
            </tr>
        `);
        if (paginationInfoEl) paginationInfoEl.textContent = "Showing 0-0 of 0";
        if (currentPageLabelEl) currentPageLabelEl.textContent = "Page 1";
        if (prevBtn) prevBtn.disabled = true;
        if (nextBtn) nextBtn.disabled = true;
        return;
    }

    // Pagination Slicing
    const maxPage = Math.ceil(totalFiltered / pageSize) || 1;
    if (currentPage > maxPage) currentPage = maxPage;

    const startIndex = (currentPage - 1) * pageSize;
    const endIndex = Math.min(startIndex + pageSize, totalFiltered);
    const paginatedList = filteredDepositsList.slice(startIndex, endIndex);

    // Update Pagination Controls
    if (paginationInfoEl) {
        paginationInfoEl.textContent = `Showing ${startIndex + 1}-${endIndex} of ${totalFiltered}`;
    }
    if (currentPageLabelEl) {
        currentPageLabelEl.textContent = `Page ${currentPage} of ${maxPage}`;
    }
    if (prevBtn) prevBtn.disabled = currentPage === 1;
    if (nextBtn) nextBtn.disabled = currentPage === maxPage;

    // Build Rows HTML
    let rowsHTML = "";
    paginatedList.forEach((dep, index) => {
        const serialNo = startIndex + index + 1;
        const memberName = memberMap[dep.memberEmail] || dep.memberEmail || "Unknown";
        const confirmedBy = dep.confirmedByAdminEmail
            ? (memberMap[dep.confirmedByAdminEmail] || dep.confirmedByAdminEmail)
            : `<span style="color:var(--text-muted); font-size:12px;">N/A</span>`;

        rowsHTML += `
            <tr style="cursor: pointer;" class="deposit-row" data-id="${dep.docId}">
                <td><strong>${serialNo}</strong></td>
                <td><strong>${memberName}</strong></td>
                <td>${dep.memberEmail || "N/A"}</td>
                <td><span class="badge" style="background:#F1F5F9; color:#334155;">${dep.monthId || "N/A"}</span></td>
                <td><strong>${formatTaka(dep.amountInPaisa)}</strong></td>
                <td>${dep.paymentMethod || "Cash"}</td>
                <td>${getStatusBadge(dep.status)}</td>
                <td>${formatDate(dep.createdAt)}</td>
                <td>${confirmedBy}</td>
                <td style="text-align: right;">
                    <button class="btn btn-outline btn-sm view-deposit-details-btn" data-id="${dep.docId}">
                        View Details
                    </button>
                </td>
            </tr>
        `;
    });

    setSafeHTML(tbody, rowsHTML);

    // Attach Row & View Details Click Handlers
    document.querySelectorAll(".view-deposit-details-btn").forEach((btn) => {
        btn.addEventListener("click", (e) => {
            e.stopPropagation();
            const id = btn.getAttribute("data-id");
            showDepositDetailsModal(id);
        });
    });

    document.querySelectorAll(".deposit-row").forEach((row) => {
        row.addEventListener("click", () => {
            const id = row.getAttribute("data-id");
            showDepositDetailsModal(id);
        });
    });
}

// Show Read-Only Deposit Details Modal
function showDepositDetailsModal(depositId) {
    const deposit = allDepositsList.find((d) => d.docId === depositId);
    if (!deposit) return;

    const modalContainer = document.getElementById("deposit-details-modal");
    if (!modalContainer) return;

    const memberName = memberMap[deposit.memberEmail] || deposit.memberEmail || "Unknown";
    const confirmedBy = deposit.confirmedByAdminEmail
        ? `${memberMap[deposit.confirmedByAdminEmail] || deposit.confirmedByAdminEmail} (${deposit.confirmedByAdminEmail})`
        : "N/A (Pending Review)";

    setSafeHTML(modalContainer, `
        <div class="modal-box">
            <div class="modal-header">
                <h3>Deposit Request Details</h3>
                <button class="close-btn" id="close-deposit-modal-btn">&times;</button>
            </div>
            <div class="modal-body">
                <div class="detail-row">
                    <span class="detail-label">Deposit Document ID</span>
                    <span class="detail-val"><code>${deposit.docId}</code></span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Member Name</span>
                    <span class="detail-val">${memberName}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Member Email</span>
                    <span class="detail-val">${deposit.memberEmail || "N/A"}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Month ID</span>
                    <span class="detail-val">${deposit.monthId || "N/A"}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Amount in Taka</span>
                    <span class="detail-val" style="font-size:18px; color:var(--primary-dark);">${formatTaka(deposit.amountInPaisa)}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Original Amount (Paisa)</span>
                    <span class="detail-val">${deposit.amountInPaisa} Paisa</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Payment Method</span>
                    <span class="detail-val">${deposit.paymentMethod || "Cash"}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Deposit Status</span>
                    <span class="detail-val">${getStatusBadge(deposit.status)}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Deposit Created Date</span>
                    <span class="detail-val">${formatDate(deposit.createdAt)}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Confirmed By Admin</span>
                    <span class="detail-val">${confirmedBy}</span>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline btn-sm" id="modal-close-deposit-btn">Close</button>
            </div>
        </div>
    `);

    modalContainer.style.display = "flex";

    // Bind Close Handlers
    const closeX = document.getElementById("close-deposit-modal-btn");
    const closeBtn = document.getElementById("modal-close-deposit-btn");

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
