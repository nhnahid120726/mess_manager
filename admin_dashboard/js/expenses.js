// Phase 6: Market Expenses Management Module (Read-Only Directory & Financial Analytics)
import { db, setSafeHTML } from "./firebase.js";
import { collection, getDocs } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";

// DOM Reference
const contentArea = document.getElementById("content-area");

// Local Module State
let allExpensesList = [];
let filteredExpensesList = [];
let memberMap = {}; // email -> name lookup map

// Filter States
let searchQuery = "";
let sourceFilter = "all";
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
function formatDate(timestamp, dateString = "") {
    if (dateString && dateString.trim() !== "") return dateString;
    if (!timestamp) return "N/A";
    try {
        const d = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
        return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    } catch (e) {
        return dateString || "N/A";
    }
}

// Current Month Helper (YYYY-MM)
function getCurrentMonthId() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    return `${year}-${month}`;
}

// Payment Source Display Badge Mapping
function getSourceBadge(source) {
    const s = (source || "").toLowerCase();
    if (s === "mess_fund") {
        return `<span class="badge" style="background:#E0F2FE; color:#0369A1;">Mess Fund</span>`;
    } else {
        return `<span class="badge" style="background:#FEF3C7; color:#92400E;">Personal</span>`;
    }
}

// Load and Process Expenses Module
export async function loadExpensesModule() {
    if (!contentArea) return;

    setSafeHTML(contentArea, `
        <div class="loading-box">
            <div class="spinner"></div>
            <p>Fetching market expenses from Firestore...</p>
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

        // 2. Fetch 'expenses' Collection
        const expensesSnap = await getDocs(collection(db, "expenses"));
        allExpensesList = [];
        const monthSet = new Set();

        expensesSnap.forEach((docSnap) => {
            const data = docSnap.data();
            const monthId = data.monthId || "";
            if (monthId) monthSet.add(monthId);

            allExpensesList.push({
                docId: docSnap.id,
                date: data.date || "",
                monthId: monthId,
                products: Array.isArray(data.products) ? data.products : [],
                totalAmountInPaisa: data.totalAmountInPaisa || 0,
                purchasedByEmail: data.purchasedByEmail || "",
                paidByEmail: data.paidByEmail || "",
                paymentSource: data.paymentSource || "mess_fund",
                sharedBetweenEmails: Array.isArray(data.sharedBetweenEmails) ? data.sharedBetweenEmails : [],
                createdAt: data.createdAt
            });
        });

        // Sort Expenses (Newest date first)
        allExpensesList.sort((a, b) => {
            const dateA = a.createdAt?.toDate ? a.createdAt.toDate() : new Date(a.date || 0);
            const dateB = b.createdAt?.toDate ? b.createdAt.toDate() : new Date(b.date || 0);
            return dateB - dateA;
        });

        // Convert available months to sorted list
        const availableMonths = Array.from(monthSet).sort().reverse();

        // Render Page Structure
        renderExpensesUI(availableMonths);

    } catch (error) {
        console.error("Error loading expenses collection:", error);
        setSafeHTML(contentArea, `
            <div class="error-msg visible" style="margin-top: 0;">
                <strong>Error Loading Expenses:</strong> ${error.message || "Failed to fetch 'expenses' collection from Firestore."}
            </div>
        `);
    }
}

// Render Main Expenses Page UI
function renderExpensesUI(availableMonths) {
    const currentMonthId = getCurrentMonthId();

    // Calculate Summary Metrics
    let totalExpensesPaisa = 0;
    let currentMonthExpensesPaisa = 0;
    let messFundExpensesPaisa = 0;
    let personalExpensesPaisa = 0;
    const totalTransactions = allExpensesList.length;

    allExpensesList.forEach((exp) => {
        const amountPaisa = exp.totalAmountInPaisa || 0;
        totalExpensesPaisa += amountPaisa;

        if (exp.monthId === currentMonthId) {
            currentMonthExpensesPaisa += amountPaisa;
        }

        if (exp.paymentSource === "mess_fund") {
            messFundExpensesPaisa += amountPaisa;
        } else {
            personalExpensesPaisa += amountPaisa;
        }
    });

    const averageExpensePaisa = totalTransactions > 0 ? Math.round(totalExpensesPaisa / totalTransactions) : 0;

    // Build Month Filter Options HTML
    let monthOptionsHTML = `<option value="all">All Months</option>`;
    availableMonths.forEach((m) => {
        monthOptionsHTML += `<option value="${m}" ${monthFilter === m ? "selected" : ""}>${m}</option>`;
    });

    setSafeHTML(contentArea, `
        <!-- Summary Cards (6 Cards) -->
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Expenses</span>
                    <div class="card-icon icon-red">🛒</div>
                </div>
                <div class="card-value">${formatTaka(totalExpensesPaisa)}</div>
                <div class="card-subtext">All-time market expenditure</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Current Month (${currentMonthId})</span>
                    <div class="card-icon icon-cyan">📅</div>
                </div>
                <div class="card-value">${formatTaka(currentMonthExpensesPaisa)}</div>
                <div class="card-subtext">Expenses in current month</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Mess Fund Paid</span>
                    <div class="card-icon icon-blue">🏦</div>
                </div>
                <div class="card-value">${formatTaka(messFundExpensesPaisa)}</div>
                <div class="card-subtext">Paid from mess cash fund</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Personal Paid</span>
                    <div class="card-icon icon-amber">👤</div>
                </div>
                <div class="card-value">${formatTaka(personalExpensesPaisa)}</div>
                <div class="card-subtext">Paid from member pockets</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Transactions</span>
                    <div class="card-icon icon-indigo">🧾</div>
                </div>
                <div class="card-value">${totalTransactions}</div>
                <div class="card-subtext">Market trip records count</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Average Expense</span>
                    <div class="card-icon icon-green">📊</div>
                </div>
                <div class="card-value">${formatTaka(averageExpensePaisa)}</div>
                <div class="card-subtext">Average cost per market trip</div>
            </div>
        </div>

        <!-- Search & Filter Controls -->
        <div class="filter-bar">
            <input
                type="text"
                id="expense-search-input"
                class="search-input"
                placeholder="🔍 Search Product, Buyer, or Payer..."
                value="${searchQuery}"
            />

            <select id="expense-source-filter" class="select-filter">
                <option value="all" ${sourceFilter === "all" ? "selected" : ""}>All Payment Sources</option>
                <option value="mess_fund" ${sourceFilter === "mess_fund" ? "selected" : ""}>Mess Fund</option>
                <option value="personal" ${sourceFilter === "personal" ? "selected" : ""}>Personal</option>
            </select>

            <select id="expense-month-filter" class="select-filter">
                ${monthOptionsHTML}
            </select>

            <div class="date-group">
                <label>From:</label>
                <input type="date" id="expense-start-date" class="date-input" value="${startDateFilter}" />
                <label>To:</label>
                <input type="date" id="expense-end-date" class="date-input" value="${endDateFilter}" />
            </div>
        </div>

        <!-- Table Card -->
        <div class="table-card">
            <div class="card-header-row" style="margin-bottom: 16px;">
                <h4>Market Expenses Records (<span id="filtered-count">${totalTransactions}</span>)</h4>
            </div>

            <div class="table-responsive">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th style="width: 50px;">#</th>
                            <th>Date</th>
                            <th>Month</th>
                            <th>Purchased By</th>
                            <th>Paid By</th>
                            <th>Payment Source</th>
                            <th>Product Summary</th>
                            <th>Total Amount</th>
                            <th style="width: 110px; text-align: right;">Action</th>
                        </tr>
                    </thead>
                    <tbody id="expenses-table-body">
                        <!-- Rows injected via applyExpenseFilters() -->
                    </tbody>
                </table>
            </div>

            <!-- Pagination Bar -->
            <div class="pagination-bar">
                <div class="page-info" id="pagination-info">Showing 0-0 of 0</div>
                <div class="pagination-controls">
                    <button class="btn btn-outline btn-sm" id="prev-page-btn" disabled>Previous</button>
                    <span class="page-info" id="current-page-label">Page 1</span>
                    <button class="btn btn-outline btn-sm" id="next-page-btn" disabled>Next</button>
                </div>
            </div>
        </div>

        <!-- Details Modal Container -->
        <div id="expense-details-modal" class="modal-backdrop" style="display: none;"></div>
    `);

    // Bind Filter Listeners
    const searchInput = document.getElementById("expense-search-input");
    const sourceSelect = document.getElementById("expense-source-filter");
    const monthSelect = document.getElementById("expense-month-filter");
    const startDateInput = document.getElementById("expense-start-date");
    const endDateInput = document.getElementById("expense-end-date");

    if (searchInput) {
        searchInput.addEventListener("input", (e) => {
            searchQuery = e.target.value.trim().toLowerCase();
            currentPage = 1;
            applyExpenseFilters();
        });
    }

    if (sourceSelect) {
        sourceSelect.addEventListener("change", (e) => {
            sourceFilter = e.target.value;
            currentPage = 1;
            applyExpenseFilters();
        });
    }

    if (monthSelect) {
        monthSelect.addEventListener("change", (e) => {
            monthFilter = e.target.value;
            currentPage = 1;
            applyExpenseFilters();
        });
    }

    if (startDateInput) {
        startDateInput.addEventListener("change", (e) => {
            startDateFilter = e.target.value;
            currentPage = 1;
            applyExpenseFilters();
        });
    }

    if (endDateInput) {
        endDateInput.addEventListener("change", (e) => {
            endDateFilter = e.target.value;
            currentPage = 1;
            applyExpenseFilters();
        });
    }

    // Bind Pagination Listeners
    const prevBtn = document.getElementById("prev-page-btn");
    const nextBtn = document.getElementById("next-page-btn");

    if (prevBtn) {
        prevBtn.addEventListener("click", () => {
            if (currentPage > 1) {
                currentPage--;
                renderExpenseTableRows();
            }
        });
    }

    if (nextBtn) {
        nextBtn.addEventListener("click", () => {
            const maxPage = Math.ceil(filteredExpensesList.length / pageSize) || 1;
            if (currentPage < maxPage) {
                currentPage++;
                renderExpenseTableRows();
            }
        });
    }

    // Apply Initial Filters & Render Table
    applyExpenseFilters();
}

// Apply Search, Source, Month & Date Range Filters
function applyExpenseFilters() {
    filteredExpensesList = allExpensesList.filter((exp) => {
        const purchaserName = (memberMap[exp.purchasedByEmail] || exp.purchasedByEmail).toLowerCase();
        const payerName = (memberMap[exp.paidByEmail] || exp.paidByEmail).toLowerCase();
        const productsText = exp.products.join(" ").toLowerCase();

        // 1. Search Matching
        const matchesSearch =
            purchaserName.includes(searchQuery) ||
            payerName.includes(searchQuery) ||
            exp.purchasedByEmail.toLowerCase().includes(searchQuery) ||
            exp.paidByEmail.toLowerCase().includes(searchQuery) ||
            productsText.includes(searchQuery);

        // 2. Source Filter Matching
        let matchesSource = true;
        if (sourceFilter !== "all") {
            matchesSource = exp.paymentSource === sourceFilter;
        }

        // 3. Month Filter Matching
        let matchesMonth = true;
        if (monthFilter !== "all") {
            matchesMonth = exp.monthId === monthFilter;
        }

        // 4. Date Range Matching
        let matchesDate = true;
        let recordDateObj = null;

        if (exp.createdAt && exp.createdAt.toDate) {
            recordDateObj = exp.createdAt.toDate();
        } else if (exp.date) {
            recordDateObj = new Date(`${exp.date}T12:00:00Z`);
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

        return matchesSearch && matchesSource && matchesMonth && matchesDate;
    });

    currentPage = 1;
    renderExpenseTableRows();
}

// Render Table Rows with Pagination
function renderExpenseTableRows() {
    const tbody = document.getElementById("expenses-table-body");
    const filteredCountEl = document.getElementById("filtered-count");
    const paginationInfoEl = document.getElementById("pagination-info");
    const currentPageLabelEl = document.getElementById("current-page-label");
    const prevBtn = document.getElementById("prev-page-btn");
    const nextBtn = document.getElementById("next-page-btn");

    const totalFiltered = filteredExpensesList.length;

    if (filteredCountEl) {
        filteredCountEl.textContent = totalFiltered;
    }

    if (!tbody) return;

    if (totalFiltered === 0) {
        setSafeHTML(tbody, `
            <tr>
                <td colspan="9" class="empty-state">
                    No market expenses found matching the selected filters.
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
    const paginatedList = filteredExpensesList.slice(startIndex, endIndex);

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
    paginatedList.forEach((exp, index) => {
        const serialNo = startIndex + index + 1;
        const purchaser = memberMap[exp.purchasedByEmail] || exp.purchasedByEmail || "N/A";
        const payer = memberMap[exp.paidByEmail] || exp.paidByEmail || "N/A";

        // Product Tags Summary (Show max 3 items, then +X more)
        let productSummaryHTML = "";
        if (exp.products.length === 0) {
            productSummaryHTML = `<span class="card-subtext">No products listed</span>`;
        } else {
            const previewItems = exp.products.slice(0, 3);
            previewItems.forEach((p) => {
                productSummaryHTML += `<span class="product-tag">${p}</span>`;
            });
            if (exp.products.length > 3) {
                productSummaryHTML += `<span class="badge" style="background:#F1F5F9; color:#475569;">+${exp.products.length - 3} more</span>`;
            }
        }

        rowsHTML += `
            <tr style="cursor: pointer;" class="expense-row" data-id="${exp.docId}">
                <td><strong>${serialNo}</strong></td>
                <td><strong>${exp.date || formatDate(exp.createdAt)}</strong></td>
                <td><span class="badge" style="background:#F1F5F9; color:#334155;">${exp.monthId || "N/A"}</span></td>
                <td>${purchaser}</td>
                <td>${payer}</td>
                <td>${getSourceBadge(exp.paymentSource)}</td>
                <td><div class="product-tags-container">${productSummaryHTML}</div></td>
                <td><strong>${formatTaka(exp.totalAmountInPaisa)}</strong></td>
                <td style="text-align: right;">
                    <button class="btn btn-outline btn-sm view-expense-details-btn" data-id="${exp.docId}">
                        View Details
                    </button>
                </td>
            </tr>
        `;
    });

    setSafeHTML(tbody, rowsHTML);

    // Attach Row & View Details Click Handlers
    document.querySelectorAll(".view-expense-details-btn").forEach((btn) => {
        btn.addEventListener("click", (e) => {
            e.stopPropagation();
            const id = btn.getAttribute("data-id");
            showExpenseDetailsModal(id);
        });
    });

    document.querySelectorAll(".expense-row").forEach((row) => {
        row.addEventListener("click", () => {
            const id = row.getAttribute("data-id");
            showExpenseDetailsModal(id);
        });
    });
}

// Show Read-Only Expense Details Modal
function showExpenseDetailsModal(expenseId) {
    const expense = allExpensesList.find((e) => e.docId === expenseId);
    if (!expense) return;

    const modalContainer = document.getElementById("expense-details-modal");
    if (!modalContainer) return;

    const purchaserName = memberMap[expense.purchasedByEmail] || expense.purchasedByEmail;
    const payerName = memberMap[expense.paidByEmail] || expense.paidByEmail;

    // Render Products Tags
    let productsHTML = "";
    if (expense.products.length === 0) {
        productsHTML = `<span class="detail-val">None</span>`;
    } else {
        expense.products.forEach((p) => {
            productsHTML += `<span class="product-tag">${p}</span>`;
        });
    }

    // Render Shared Members
    let sharedHTML = "";
    if (expense.sharedBetweenEmails.length === 0) {
        sharedHTML = `<span class="detail-val">Shared between all mess members</span>`;
    } else {
        expense.sharedBetweenEmails.forEach((email) => {
            const name = memberMap[email] || email;
            sharedHTML += `<span class="product-tag" style="background:#E0F2FE; color:#0369A1;">${name}</span>`;
        });
    }

    setSafeHTML(modalContainer, `
        <div class="modal-box">
            <div class="modal-header">
                <h3>Market Expense Details</h3>
                <button class="close-btn" id="close-expense-modal-btn">&times;</button>
            </div>
            <div class="modal-body">
                <div class="detail-row">
                    <span class="detail-label">Expense Date</span>
                    <span class="detail-val">${expense.date || formatDate(expense.createdAt)}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Month ID</span>
                    <span class="detail-val">${expense.monthId || "N/A"}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Purchased By</span>
                    <span class="detail-val">${purchaserName} <br><small style="color:var(--text-muted); font-weight:normal;">(${expense.purchasedByEmail})</small></span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Paid By</span>
                    <span class="detail-val">${payerName} <br><small style="color:var(--text-muted); font-weight:normal;">(${expense.paidByEmail})</small></span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Payment Source</span>
                    <span class="detail-val">${getSourceBadge(expense.paymentSource)}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Total Amount</span>
                    <span class="detail-val" style="font-size:18px; color:var(--primary-dark);">${formatTaka(expense.totalAmountInPaisa)}</span>
                </div>

                <div class="detail-row-column">
                    <span class="detail-label">Products Purchased (${expense.products.length})</span>
                    <div style="display:flex; flex-wrap:wrap; gap:6px; margin-top:4px;">
                        ${productsHTML}
                    </div>
                </div>

                <div class="detail-row-column">
                    <span class="detail-label">Shared Between Members</span>
                    <div style="display:flex; flex-wrap:wrap; gap:6px; margin-top:4px;">
                        ${sharedHTML}
                    </div>
                </div>

                <div class="detail-row">
                    <span class="detail-label">Firestore Document ID</span>
                    <span class="detail-val"><code>${expense.docId}</code></span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Created At</span>
                    <span class="detail-val">${formatDate(expense.createdAt)}</span>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline btn-sm" id="modal-close-expense-btn">Close</button>
            </div>
        </div>
    `);

    modalContainer.style.display = "flex";

    // Bind Close Handlers
    const closeX = document.getElementById("close-expense-modal-btn");
    const closeBtn = document.getElementById("modal-close-expense-btn");

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
