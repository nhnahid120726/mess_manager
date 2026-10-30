// Phase 4, 5, 6, 7, 8, 9 & 10: Complete Admin Web Dashboard Navigation Handler
import { db, setSafeHTML } from "./firebase.js";
import { adminAccessReady } from "./auth.js";
import { collection, getDocs, doc, getDoc } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";
import { loadMembersModule } from "./members.js";
import { loadExpensesModule } from "./expenses.js";
import { loadDepositsModule } from "./deposits.js";
import { loadMealsModule } from "./meals.js";
import { loadWalletModule } from "./wallet.js";
import { loadReportsModule } from "./reports.js";

// DOM Elements
const contentArea = document.getElementById("content-area");
const pageTitleEl = document.getElementById("page-title");
const navItems = document.querySelectorAll(".nav-item");

// Active Tab State
let currentTab = "overview";
let dashboardAuthorized = false;

// Format Money Helper (1 Taka = 100 Paisa)
function formatTaka(paisa) {
    const taka = (paisa || 0) / 100;
    return `৳ ${taka.toLocaleString('en-IN', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;
}

// Format Timestamp Helper
function formatDate(timestamp, fallbackDateString = "N/A") {
    if (!timestamp) return fallbackDateString;
    try {
        const dateObj = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
        return dateObj.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    } catch (e) {
        return fallbackDateString;
    }
}

// Current Month Helper (YYYY-MM)
function getCurrentMonthId() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    return `${year}-${month}`;
}

// Render Dashboard Overview Template
function renderOverviewSkeleton() {
    if (!contentArea) return;
    setSafeHTML(contentArea, `
        <div class="loading-box">
            <div class="spinner"></div>
            <p>Fetching real-time data from Firestore...</p>
        </div>
    `);
}

// Load and Process Dashboard Data from Firestore
async function loadDashboardOverview() {
    if (currentTab !== "overview") return;
    renderOverviewSkeleton();

    try {
        const currentMonthId = getCurrentMonthId();

        // 1. Fetch 'members' Collection
        const membersSnap = await getDocs(collection(db, "members"));
        const memberMap = {}; // email -> name lookup map
        let totalMembers = 0;
        let authorizedMembers = 0;

        membersSnap.forEach((docSnap) => {
            const data = docSnap.data();
            const email = docSnap.id || data.email;
            if (data.name) memberMap[email] = data.name;

            // Only count Mess Members (exclude wallet_only users)
            if (data.role !== "wallet_only") {
                totalMembers++;
                if (data.isAuthorized === true) {
                    authorizedMembers++;
                }
            }
        });

        // 2. Fetch 'deposits' Collection
        const depositsSnap = await getDocs(collection(db, "deposits"));
        let totalDepositsPaisa = 0;
        let monthlyDepositsPaisa = 0;
        const allDeposits = [];

        depositsSnap.forEach((docSnap) => {
            const data = docSnap.data();
            const deposit = { id: docSnap.id, ...data };
            allDeposits.push(deposit);

            // Only count Confirmed Deposits for finances
            if (data.status === "confirmed") {
                const amountPaisa = data.amountInPaisa || 0;
                totalDepositsPaisa += amountPaisa;

                if (data.monthId === currentMonthId) {
                    monthlyDepositsPaisa += amountPaisa;
                }
            }
        });

        // 3. Fetch 'expenses' Collection
        const expensesSnap = await getDocs(collection(db, "expenses"));
        let totalExpensesPaisa = 0;
        let monthlyExpensesPaisa = 0;
        let expensesFromMessFundPaisa = 0;
        let monthlyExpenseCount = 0;
        const allExpenses = [];

        expensesSnap.forEach((docSnap) => {
            const data = docSnap.data();
            const expense = { id: docSnap.id, ...data };
            allExpenses.push(expense);

            const amountPaisa = data.totalAmountInPaisa || 0;
            totalExpensesPaisa += amountPaisa;

            if (data.paymentSource === "mess_fund") {
                expensesFromMessFundPaisa += amountPaisa;
            }

            if (data.monthId === currentMonthId) {
                monthlyExpensesPaisa += amountPaisa;
                monthlyExpenseCount++;
            }
        });

        // 4. Mess Fund Balance Formula (Verified from Flutter financial_service.dart)
        // Mess Cash Balance = Total Confirmed Deposits - Total Expenses Paid from Mess Fund
        const messFundBalancePaisa = totalDepositsPaisa - expensesFromMessFundPaisa;

        // 5. Fetch 'monthly_meals' Collection for Current Month
        let totalMonthlyMeals = 0;
        try {
            const mealDocRef = doc(db, "monthly_meals", currentMonthId);
            const mealDocSnap = await getDoc(mealDocRef);

            if (mealDocSnap.exists()) {
                const mealData = mealDocSnap.data();
                Object.values(mealData).forEach((val) => {
                    if (typeof val === "number") {
                        totalMonthlyMeals += val;
                    }
                });
            }
        } catch (err) {
            console.warn("Monthly meals fetch note:", err.message);
        }

        // Sort Recent Expenses (Newest first)
        allExpenses.sort((a, b) => {
            const dateA = a.createdAt?.toDate ? a.createdAt.toDate() : new Date(a.date || 0);
            const dateB = b.createdAt?.toDate ? b.createdAt.toDate() : new Date(b.date || 0);
            return dateB - dateA;
        });
        const recentExpenses = allExpenses.slice(0, 5);

        // Sort Recent Deposits (Newest first)
        allDeposits.sort((a, b) => {
            const dateA = a.createdAt?.toDate ? a.createdAt.toDate() : new Date(0);
            const dateB = b.createdAt?.toDate ? b.createdAt.toDate() : new Date(0);
            return dateB - dateA;
        });
        const recentDeposits = allDeposits.slice(0, 5);

        // Render Overview UI
        renderOverviewDashboard({
            totalMembers,
            authorizedMembers,
            totalDepositsPaisa,
            totalExpensesPaisa,
            messFundBalancePaisa,
            totalMonthlyMeals,
            currentMonthId,
            monthlyDepositsPaisa,
            monthlyExpensesPaisa,
            monthlyExpenseCount,
            recentExpenses,
            recentDeposits,
            memberMap
        });

    } catch (error) {
        console.error("Error loading dashboard overview:", error);
        if (contentArea) {
            setSafeHTML(contentArea, `
                <div class="error-msg visible" style="margin-top: 0;">
                    <strong>Error Loading Overview:</strong> ${error.message || "Failed to fetch data from Firestore."}
                </div>
            `);
        }
    }
}

// Build Final Overview Dashboard HTML
function renderOverviewDashboard(data) {
    if (!contentArea) return;

    // Build Recent Expenses Rows
    let expensesRowsHTML = "";
    if (data.recentExpenses.length === 0) {
        expensesRowsHTML = `<tr><td colspan="5" class="empty-state">No market expenses recorded yet.</td></tr>`;
    } else {
        data.recentExpenses.forEach((exp) => {
            const purchaser = data.memberMap[exp.purchasedByEmail] || exp.purchasedByEmail || "N/A";
            const payer = data.memberMap[exp.paidByEmail] || exp.paidByEmail || "N/A";
            const sourceBadge = exp.paymentSource === "mess_fund"
                ? `<span class="badge" style="background:#E0F2FE; color:#0369A1;">Mess Fund</span>`
                : `<span class="badge" style="background:#FEF3C7; color:#92400E;">Personal</span>`;

            expensesRowsHTML += `
                <tr>
                    <td><strong>${exp.date || formatDate(exp.createdAt)}</strong></td>
                    <td>${purchaser}</td>
                    <td>${payer}</td>
                    <td>${sourceBadge}</td>
                    <td><strong>${formatTaka(exp.totalAmountInPaisa)}</strong></td>
                </tr>
            `;
        });
    }

    // Build Recent Deposits Rows
    let depositsRowsHTML = "";
    if (data.recentDeposits.length === 0) {
        depositsRowsHTML = `<tr><td colspan="5" class="empty-state">No deposits recorded yet.</td></tr>`;
    } else {
        data.recentDeposits.forEach((dep) => {
            const memberName = data.memberMap[dep.memberEmail] || dep.memberEmail || "N/A";
            const statusClass = dep.status === "confirmed" ? "status-confirmed" : (dep.status === "pending" ? "status-pending" : "status-rejected");

            depositsRowsHTML += `
                <tr>
                    <td><strong>${memberName}</strong></td>
                    <td><strong>${formatTaka(dep.amountInPaisa)}</strong></td>
                    <td>${dep.paymentMethod || "Cash"}</td>
                    <td><span class="status-pill ${statusClass}">${dep.status}</span></td>
                    <td>${formatDate(dep.createdAt)}</td>
                </tr>
            `;
        });
    }

    setSafeHTML(contentArea, `
        <!-- Top Summary Cards (6 Cards) -->
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Members</span>
                    <div class="card-icon icon-blue">👥</div>
                </div>
                <div class="card-value">${data.totalMembers}</div>
                <div class="card-subtext">Mess members count (Max 8)</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Authorized Members</span>
                    <div class="card-icon icon-cyan">🛡️</div>
                </div>
                <div class="card-value">${data.authorizedMembers}</div>
                <div class="card-subtext">Active authorized members</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Deposits</span>
                    <div class="card-icon icon-green">💳</div>
                </div>
                <div class="card-value">${formatTaka(data.totalDepositsPaisa)}</div>
                <div class="card-subtext">Confirmed deposits all-time</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Expenses</span>
                    <div class="card-icon icon-red">🛒</div>
                </div>
                <div class="card-value">${formatTaka(data.totalExpensesPaisa)}</div>
                <div class="card-subtext">Market expenses all-time</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Mess Cash Balance</span>
                    <div class="card-icon icon-indigo">💰</div>
                </div>
                <div class="card-value">${formatTaka(data.messFundBalancePaisa)}</div>
                <div class="card-subtext">Deposits - Mess Fund Expenses</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Monthly Meals</span>
                    <div class="card-icon icon-purple">🍽️</div>
                </div>
                <div class="card-value">${data.totalMonthlyMeals}</div>
                <div class="card-subtext">Current month meal count</div>
            </div>
        </div>

        <!-- Monthly Overview Banner -->
        <div class="monthly-card">
            <h3>Current Month Overview (${data.currentMonthId})</h3>
            <div class="monthly-grid">
                <div class="monthly-stat">
                    <div class="label">Monthly Deposits</div>
                    <div class="val">${formatTaka(data.monthlyDepositsPaisa)}</div>
                </div>
                <div class="monthly-stat">
                    <div class="label">Monthly Expenses</div>
                    <div class="val">${formatTaka(data.monthlyExpensesPaisa)}</div>
                </div>
                <div class="monthly-stat">
                    <div class="label">Total Monthly Meals</div>
                    <div class="val">${data.totalMonthlyMeals} Meals</div>
                </div>
                <div class="monthly-stat">
                    <div class="label">Expense Transactions</div>
                    <div class="val">${data.monthlyExpenseCount} Records</div>
                </div>
            </div>
        </div>

        <!-- Recent Tables Section -->
        <div class="tables-row">
            <div class="table-card">
                <h4>Recent Market Expenses (Top 5)</h4>
                <div class="table-responsive">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Date</th>
                                <th>Purchased By</th>
                                <th>Paid By</th>
                                <th>Source</th>
                                <th>Total</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${expensesRowsHTML}
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="table-card">
                <h4>Recent Deposits (Top 5)</h4>
                <div class="table-responsive">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Member</th>
                                <th>Amount</th>
                                <th>Method</th>
                                <th>Status</th>
                                <th>Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${depositsRowsHTML}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    `);
}

// Handle Sidebar Navigation Click Events
navItems.forEach((item) => {
    item.addEventListener("click", (e) => {
        e.preventDefault();
        if (!dashboardAuthorized) return;

        navItems.forEach((nav) => nav.classList.remove("active"));
        item.classList.add("active");

        const tab = item.getAttribute("data-tab");
        currentTab = tab;

        if (pageTitleEl) {
            pageTitleEl.textContent = item.getAttribute("data-title") || item.textContent.trim();
        }

        if (tab === "overview") {
            loadDashboardOverview();
        } else if (tab === "members") {
            loadMembersModule();
        } else if (tab === "expenses") {
            loadExpensesModule();
        } else if (tab === "deposits") {
            loadDepositsModule();
        } else if (tab === "meals") {
            loadMealsModule();
        } else if (tab === "wallet") {
            loadWalletModule();
        } else if (tab === "reports") {
            loadReportsModule();
        }
    });
});

// Load data only after the authenticated admin check succeeds.
adminAccessReady.then((isAdmin) => {
    if (!isAdmin) return;
    dashboardAuthorized = true;
    loadDashboardOverview();
});
