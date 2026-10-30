// Phase 10: Professional Reports & Analytics Module (Read-Only Analytics Engine & Chart.js Integration)
import { db, setSafeHTML } from "./firebase.js";
import { collection, getDocs } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";

// DOM Reference
const contentArea = document.getElementById("content-area");

// Module Cache & State
let membersList = [];
let memberMap = {}; // email -> name
let expensesList = [];
let depositsList = [];
let mealsMap = {}; // monthId -> { email -> mealCount }

let availableYearsList = [];
let availableMonthsList = [];

// Filter States
let filterYear = "all";
let filterMonth = "all";
let filterSource = "all";
let filterMember = "all";

// Active Chart.js Instances (For clean re-renders)
const chartInstances = {};

// Format Money Helper (1 Taka = 100 Paisa)
function formatTaka(paisa) {
    const taka = (paisa || 0) / 100;
    return `৳ ${taka.toLocaleString('en-IN', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;
}

// Format Timestamp Helper
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

// Safely Destroy Existing Chart Instance
function destroyChart(canvasId) {
    if (chartInstances[canvasId]) {
        chartInstances[canvasId].destroy();
        delete chartInstances[canvasId];
    }
}

// Load and Initialize Reports & Analytics Module
export async function loadReportsModule() {
    if (!contentArea) return;

    setSafeHTML(contentArea, `
        <div class="loading-box">
            <div class="spinner"></div>
            <p>Gathering analytics and computing financial reports from Firestore...</p>
        </div>
    `);

    try {
        // Fetch all required collections in parallel
        const [membersSnap, expensesSnap, depositsSnap, mealsSnap] = await Promise.all([
            getDocs(collection(db, "members")),
            getDocs(collection(db, "expenses")),
            getDocs(collection(db, "deposits")),
            getDocs(collection(db, "monthly_meals"))
        ]);

        // 1. Process Members
        membersList = [];
        memberMap = {};
        membersSnap.forEach((docSnap) => {
            const data = docSnap.data();
            const email = docSnap.id || data.email;
            if (email) {
                const name = data.name || email;
                memberMap[email] = name;
                membersList.push({
                    docId: docSnap.id,
                    email: email,
                    name: name,
                    role: (data.role || "member").toLowerCase(),
                    isAuthorized: data.isAuthorized === true
                });
            }
        });

        // 2. Process Expenses
        expensesList = [];
        const monthSet = new Set();
        const yearSet = new Set();

        expensesSnap.forEach((docSnap) => {
            const data = docSnap.data();
            const monthId = data.monthId || "";
            if (monthId) {
                monthSet.add(monthId);
                const yr = monthId.split("-")[0];
                if (yr) yearSet.add(yr);
            }

            expensesList.push({
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

        // 3. Process Deposits
        depositsList = [];
        depositsSnap.forEach((docSnap) => {
            const data = docSnap.data();
            const monthId = data.monthId || "";
            if (monthId) {
                monthSet.add(monthId);
                const yr = monthId.split("-")[0];
                if (yr) yearSet.add(yr);
            }

            depositsList.push({
                docId: docSnap.id,
                monthId: monthId,
                memberEmail: data.memberEmail || "",
                amountInPaisa: typeof data.amountInPaisa === "number" ? data.amountInPaisa : 0,
                paymentMethod: data.paymentMethod || "Cash",
                status: (data.status || "pending").toLowerCase(),
                confirmedByAdminEmail: data.confirmedByAdminEmail || "",
                createdAt: data.createdAt
            });
        });

        // 4. Process Monthly Meals
        mealsMap = {};
        mealsSnap.forEach((docSnap) => {
            const monthId = docSnap.id;
            mealsMap[monthId] = docSnap.data() || {};
            if (monthId) {
                monthSet.add(monthId);
                const yr = monthId.split("-")[0];
                if (yr) yearSet.add(yr);
            }
        });

        availableMonthsList = Array.from(monthSet).sort().reverse();
        availableYearsList = Array.from(yearSet).sort().reverse();

        // Render Analytics UI
        renderReportsUI();

    } catch (error) {
        console.error("Error generating reports & analytics:", error);
        setSafeHTML(contentArea, `
            <div class="error-msg visible" style="margin-top: 0;">
                <strong>Error Generating Reports:</strong> ${error.message || "Failed to fetch data from Firestore."}
            </div>
        `);
    }
}

// Render Main Analytics Page UI
function renderReportsUI() {
    if (!contentArea) return;

    // Filter Options HTML
    let yearOptionsHTML = `<option value="all">All Years</option>`;
    availableYearsList.forEach((y) => {
        yearOptionsHTML += `<option value="${y}" ${filterYear === y ? "selected" : ""}>${y}</option>`;
    });

    let monthOptionsHTML = `<option value="all">All Months</option>`;
    availableMonthsList.forEach((m) => {
        monthOptionsHTML += `<option value="${m}" ${filterMonth === m ? "selected" : ""}>${m}</option>`;
    });

    let memberOptionsHTML = `<option value="all">All Members</option>`;
    membersList.forEach((m) => {
        memberOptionsHTML += `<option value="${m.email}" ${filterMember === m.email ? "selected" : ""}>${m.name}</option>`;
    });

    setSafeHTML(contentArea, `
        <!-- Export & Print Action Bar -->
        <div class="export-toolbar">
            <div>
                <h3 style="font-size: 18px; font-weight: 700; color: var(--primary-dark);">Mess Financial & Analytics Reports</h3>
                <p style="font-size: 13px; color: var(--text-muted); margin-top: 2px;">Comprehensive read-only analytics, charts, and downloadable reports</p>
            </div>
            <div class="export-actions">
                <button class="btn btn-success btn-sm" id="export-csv-btn">
                    📥 Export CSV
                </button>
                <button class="btn btn-secondary btn-sm" id="print-report-btn">
                    🖨️ Print Report
                </button>
            </div>
        </div>

        <!-- Filter Controls Bar -->
        <div class="filter-bar">
            <select id="report-year-filter" class="select-filter">
                ${yearOptionsHTML}
            </select>

            <select id="report-month-filter" class="select-filter">
                ${monthOptionsHTML}
            </select>

            <select id="report-source-filter" class="select-filter">
                <option value="all" ${filterSource === "all" ? "selected" : ""}>All Payment Sources</option>
                <option value="mess_fund" ${filterSource === "mess_fund" ? "selected" : ""}>Mess Fund</option>
                <option value="personal" ${filterSource === "personal" ? "selected" : ""}>Personal Paid</option>
            </select>

            <select id="report-member-filter" class="select-filter">
                ${memberOptionsHTML}
            </select>
        </div>

        <!-- Dynamic Report Content Area -->
        <div id="analytics-content-body">
            <!-- Summary Cards, Charts & Tables injected via updateAnalyticsBody() -->
        </div>
    `);

    // Bind Filter Listeners
    const yearSelect = document.getElementById("report-year-filter");
    const monthSelect = document.getElementById("report-month-filter");
    const sourceSelect = document.getElementById("report-source-filter");
    const memberSelect = document.getElementById("report-member-filter");

    if (yearSelect) yearSelect.addEventListener("change", e => { filterYear = e.target.value; updateAnalyticsBody(); });
    if (monthSelect) monthSelect.addEventListener("change", e => { filterMonth = e.target.value; updateAnalyticsBody(); });
    if (sourceSelect) sourceSelect.addEventListener("change", e => { filterSource = e.target.value; updateAnalyticsBody(); });
    if (memberSelect) memberSelect.addEventListener("change", e => { filterMember = e.target.value; updateAnalyticsBody(); });

    // Bind Export & Print Listeners
    const csvBtn = document.getElementById("export-csv-btn");
    const printBtn = document.getElementById("print-report-btn");

    if (csvBtn) csvBtn.addEventListener("click", exportReportToCSV);
    if (printBtn) printBtn.addEventListener("click", () => window.print());

    // Compute and Render Initial Analytics
    updateAnalyticsBody();
}

// Compute Analytics & Render Dynamic Dashboard Cards, Charts and Tables
function updateAnalyticsBody() {
    const container = document.getElementById("analytics-content-body");
    if (!container) return;

    // Filter Deposits Dataset
    const filteredDeposits = depositsList.filter((dep) => {
        let matches = true;
        if (filterYear !== "all" && !dep.monthId.startsWith(filterYear)) matches = false;
        if (filterMonth !== "all" && dep.monthId !== filterMonth) matches = false;
        if (filterMember !== "all" && dep.memberEmail !== filterMember) matches = false;
        return matches;
    });

    // Filter Expenses Dataset
    const filteredExpenses = expensesList.filter((exp) => {
        let matches = true;
        if (filterYear !== "all" && !exp.monthId.startsWith(filterYear)) matches = false;
        if (filterMonth !== "all" && exp.monthId !== filterMonth) matches = false;
        if (filterSource !== "all" && exp.paymentSource !== filterSource) matches = false;
        if (filterMember !== "all" && exp.purchasedByEmail !== filterMember && exp.paidByEmail !== filterMember) matches = false;
        return matches;
    });

    // 1. Calculate Summary Metrics
    let totalDepositsPaisa = 0;
    let confirmedDepositsPaisa = 0;
    let confirmedDepositsCount = 0;

    filteredDeposits.forEach((dep) => {
        const amt = dep.amountInPaisa || 0;
        if (dep.status === "confirmed") {
            confirmedDepositsPaisa += amt;
            confirmedDepositsCount++;
        }
        totalDepositsPaisa += amt;
    });

    let totalExpensesPaisa = 0;
    let messFundExpensesPaisa = 0;
    let personalExpensesPaisa = 0;

    filteredExpenses.forEach((exp) => {
        const amt = exp.totalAmountInPaisa || 0;
        totalExpensesPaisa += amt;
        if (exp.paymentSource === "mess_fund") {
            messFundExpensesPaisa += amt;
        } else {
            personalExpensesPaisa += amt;
        }
    });

    const messCashBalancePaisa = confirmedDepositsPaisa - messFundExpensesPaisa;

    // Calculate Total Meals for filtered scope
    let totalMealsCount = 0;
    Object.keys(mealsMap).forEach((mId) => {
        if (filterYear !== "all" && !mId.startsWith(filterYear)) return;
        if (filterMonth !== "all" && mId !== filterMonth) return;

        const mData = mealsMap[mId] || {};
        Object.keys(mData).forEach((email) => {
            if (filterMember !== "all" && email !== filterMember) return;
            const val = mData[email];
            if (typeof email === "string" && email.includes("@") && typeof val === "number" && val >= 0) {
                totalMealsCount += Math.round(val);
            }
        });
    });

    const totalMessMembers = membersList.filter(m => m.role !== "wallet_only").length;

    // Render Metrics & Content Layout
    setSafeHTML(container, `
        <!-- Summary Cards (6 Cards) -->
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Confirmed Deposits</span>
                    <div class="card-icon icon-green">💳</div>
                </div>
                <div class="card-value">${formatTaka(confirmedDepositsPaisa)}</div>
                <div class="card-subtext">${confirmedDepositsCount} confirmed deposit records</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Market Expenses</span>
                    <div class="card-icon icon-red">🛒</div>
                </div>
                <div class="card-value">${formatTaka(totalExpensesPaisa)}</div>
                <div class="card-subtext">${filteredExpenses.length} shopping records</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Mess Cash Balance</span>
                    <div class="card-icon icon-indigo">💰</div>
                </div>
                <div class="card-value">${formatTaka(messCashBalancePaisa)}</div>
                <div class="card-subtext">Confirmed Deposits - Mess Fund Expenses</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Mess Members</span>
                    <div class="card-icon icon-blue">👥</div>
                </div>
                <div class="card-value">${totalMessMembers}</div>
                <div class="card-subtext">Mess active members (Max 8)</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Mess Fund Paid</span>
                    <div class="card-icon icon-cyan">🏦</div>
                </div>
                <div class="card-value">${formatTaka(messFundExpensesPaisa)}</div>
                <div class="card-subtext">Paid from mess cash pool</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Meals Count</span>
                    <div class="card-icon icon-purple">🍽️</div>
                </div>
                <div class="card-value">${totalMealsCount}</div>
                <div class="card-subtext">Sum of meals in selected scope</div>
            </div>
        </div>

        <!-- Interactive Charts Grid (4 Charts) -->
        <div class="charts-grid">
            <div class="chart-card">
                <h4>Monthly Financial Trend (Deposits vs Expenses)</h4>
                <div class="chart-canvas-container">
                    <canvas id="chart-financial-trend"></canvas>
                </div>
            </div>

            <div class="chart-card">
                <h4>Expense Payment Source Distribution</h4>
                <div class="chart-canvas-container">
                    <canvas id="chart-payment-source"></canvas>
                </div>
            </div>

            <div class="chart-card">
                <h4>Deposit Status Distribution</h4>
                <div class="chart-canvas-container">
                    <canvas id="chart-deposit-status"></canvas>
                </div>
            </div>

            <div class="chart-card">
                <h4>Member Meals Distribution</h4>
                <div class="chart-canvas-container">
                    <canvas id="chart-member-meals"></canvas>
                </div>
            </div>
        </div>

        <!-- Month-wise Summary Table -->
        <div class="table-card" style="margin-bottom: 32px;">
            <h4>Month-wise Financial & Meals Analytics Summary Report</h4>
            <div class="table-responsive">
                <table class="data-table" id="report-summary-table">
                    <thead>
                        <tr>
                            <th>Month ID</th>
                            <th>Confirmed Deposits (৳)</th>
                            <th>Total Expenses (৳)</th>
                            <th>Mess Fund Expenses (৳)</th>
                            <th>Total Meals</th>
                            <th>Net Cash Flow (৳)</th>
                        </tr>
                    </thead>
                    <tbody id="report-summary-table-body">
                        <!-- Injected via renderMonthlySummaryTable() -->
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Analytics Row: Product Frequency & Member Breakdown -->
        <div class="tables-row">
            <div class="table-card">
                <h4>Top Purchased Market Products Frequency Analysis</h4>
                <div class="table-responsive">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Product Item Name</th>
                                <th>Purchase Frequency</th>
                            </tr>
                        </thead>
                        <tbody id="product-freq-table-body">
                            <!-- Injected via renderProductFrequencyTable() -->
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="table-card">
                <h4>Member Financial & Meal Contribution Breakdown</h4>
                <div class="table-responsive">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Member Name</th>
                                <th>Confirmed Deposits</th>
                                <th>Purchases Made</th>
                                <th>Meals Count</th>
                            </tr>
                        </thead>
                        <tbody id="member-breakdown-table-body">
                            <!-- Injected via renderMemberBreakdownTable() -->
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    `);

    // Render Charts and Tables
    setTimeout(() => {
        renderCharts(filteredDeposits, filteredExpenses);
        renderMonthlySummaryTable(filteredDeposits, filteredExpenses);
        renderProductFrequencyTable(filteredExpenses);
        renderMemberBreakdownTable(filteredDeposits, filteredExpenses);
    }, 50);
}

// Render Chart.js Visualizations
function renderCharts(filteredDeposits, filteredExpenses) {
    if (typeof Chart === "undefined") {
        console.warn("Chart.js library not available.");
        return;
    }

    // 1. Chart 1: Monthly Financial Trend (Bar Chart)
    const monthSet = new Set([...availableMonthsList]);
    const monthsSorted = Array.from(monthSet).sort();

    const monthlyDepData = {};
    const monthlyExpData = {};

    monthsSorted.forEach(m => { monthlyDepData[m] = 0; monthlyExpData[m] = 0; });

    filteredDeposits.forEach((dep) => {
        if (dep.status === "confirmed" && monthlyDepData[dep.monthId] !== undefined) {
            monthlyDepData[dep.monthId] += (dep.amountInPaisa || 0) / 100;
        }
    });

    filteredExpenses.forEach((exp) => {
        if (monthlyExpData[exp.monthId] !== undefined) {
            monthlyExpData[exp.monthId] += (exp.totalAmountInPaisa || 0) / 100;
        }
    });

    destroyChart("chart-financial-trend");
    const ctx1 = document.getElementById("chart-financial-trend")?.getContext("2d");
    if (ctx1) {
        chartInstances["chart-financial-trend"] = new Chart(ctx1, {
            type: 'bar',
            data: {
                labels: monthsSorted.length > 0 ? monthsSorted : ["No Data"],
                datasets: [
                    {
                        label: 'Confirmed Deposits (৳)',
                        data: monthsSorted.map(m => monthlyDepData[m] || 0),
                        backgroundColor: '#10B981',
                        borderRadius: 6
                    },
                    {
                        label: 'Total Expenses (৳)',
                        data: monthsSorted.map(m => monthlyExpData[m] || 0),
                        backgroundColor: '#EF4444',
                        borderRadius: 6
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { position: 'bottom' } }
            }
        });
    }

    // 2. Chart 2: Expense Payment Source Distribution (Doughnut Chart)
    let messFundPaisa = 0;
    let personalPaidPaisa = 0;

    filteredExpenses.forEach((exp) => {
        if (exp.paymentSource === "mess_fund") {
            messFundPaisa += (exp.totalAmountInPaisa || 0);
        } else {
            personalPaidPaisa += (exp.totalAmountInPaisa || 0);
        }
    });

    destroyChart("chart-payment-source");
    const ctx2 = document.getElementById("chart-payment-source")?.getContext("2d");
    if (ctx2) {
        chartInstances["chart-payment-source"] = new Chart(ctx2, {
            type: 'doughnut',
            data: {
                labels: ['Mess Fund Paid', 'Personal Paid'],
                datasets: [{
                    data: [messFundPaisa / 100, personalPaidPaisa / 100],
                    backgroundColor: ['#0EA5E9', '#F59E0B']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { position: 'bottom' } }
            }
        });
    }

    // 3. Chart 3: Deposit Status Distribution (Pie Chart)
    let confirmedCount = 0;
    let pendingCount = 0;
    let rejectedCount = 0;

    filteredDeposits.forEach((dep) => {
        if (dep.status === "confirmed") confirmedCount++;
        else if (dep.status === "pending") pendingCount++;
        else if (dep.status === "rejected") rejectedCount++;
    });

    destroyChart("chart-deposit-status");
    const ctx3 = document.getElementById("chart-deposit-status")?.getContext("2d");
    if (ctx3) {
        chartInstances["chart-deposit-status"] = new Chart(ctx3, {
            type: 'pie',
            data: {
                labels: ['Confirmed', 'Pending', 'Rejected'],
                datasets: [{
                    data: [confirmedCount, pendingCount, rejectedCount],
                    backgroundColor: ['#10B981', '#F59E0B', '#EF4444']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { position: 'bottom' } }
            }
        });
    }

    // 4. Chart 4: Member Meal Comparison (Bar Chart)
    const scopedMonths = availableMonthsList.filter((monthId) =>
        (filterYear === "all" || monthId.startsWith(filterYear)) &&
        (filterMonth === "all" || monthId === filterMonth)
    );
    const activeMonthId = scopedMonths[0] || "";
    const monthMealData = mealsMap[activeMonthId] || {};
    const memberMealLabels = [];
    const memberMealValues = [];

    membersList.forEach((m) => {
        if (m.role !== "wallet_only" && (filterMember === "all" || m.email === filterMember)) {
            const count = monthMealData[m.email] || 0;
            memberMealLabels.push(m.name);
            memberMealValues.push(count);
        }
    });

    destroyChart("chart-member-meals");
    const ctx4 = document.getElementById("chart-member-meals")?.getContext("2d");
    if (ctx4) {
        chartInstances["chart-member-meals"] = new Chart(ctx4, {
            type: 'bar',
            data: {
                labels: memberMealLabels.length > 0 ? memberMealLabels : ["No Members"],
                datasets: [{
                    label: `Meals Count (${activeMonthId || 'Current Month'})`,
                    data: memberMealValues.length > 0 ? memberMealValues : [0],
                    backgroundColor: '#6366F1',
                    borderRadius: 6
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { position: 'bottom' } }
            }
        });
    }
}

// Render Month-wise Analytics Summary Table
function renderMonthlySummaryTable(filteredDeposits, filteredExpenses) {
    const tbody = document.getElementById("report-summary-table-body");
    if (!tbody) return;

    const monthMap = {};
    availableMonthsList.forEach((m) => {
        if (filterYear !== "all" && !m.startsWith(filterYear)) return;
        if (filterMonth !== "all" && m !== filterMonth) return;
        monthMap[m] = { confirmedDepPaisa: 0, totalExpPaisa: 0, messExpPaisa: 0, mealsCount: 0 };
    });

    filteredDeposits.forEach((dep) => {
        if (dep.status === "confirmed" && monthMap[dep.monthId]) {
            monthMap[dep.monthId].confirmedDepPaisa += (dep.amountInPaisa || 0);
        }
    });

    filteredExpenses.forEach((exp) => {
        if (monthMap[exp.monthId]) {
            const amt = exp.totalAmountInPaisa || 0;
            monthMap[exp.monthId].totalExpPaisa += amt;
            if (exp.paymentSource === "mess_fund") {
                monthMap[exp.monthId].messExpPaisa += amt;
            }
        }
    });

    Object.keys(monthMap).forEach((m) => {
        const mData = mealsMap[m] || {};
        let mCount = 0;
        Object.entries(mData).forEach(([email, val]) => {
            if ((filterMember === "all" || email === filterMember) && typeof val === "number" && val >= 0) {
                mCount += Math.round(val);
            }
        });
        monthMap[m].mealsCount = mCount;
    });

    const monthKeys = Object.keys(monthMap).sort().reverse();

    if (monthKeys.length === 0) {
        setSafeHTML(tbody, `<tr><td colspan="6" class="empty-state">No monthly records found for selected filter scope.</td></tr>`);
        return;
    }

    let rowsHTML = "";
    monthKeys.forEach((m) => {
        const d = monthMap[m];
        const netCashPaisa = d.confirmedDepPaisa - d.messExpPaisa;

        rowsHTML += `
            <tr>
                <td><strong>${m}</strong></td>
                <td><strong>${formatTaka(d.confirmedDepPaisa)}</strong></td>
                <td>${formatTaka(d.totalExpPaisa)}</td>
                <td>${formatTaka(d.messExpPaisa)}</td>
                <td><span class="meal-badge">${d.mealsCount} Meals</span></td>
                <td><strong style="color:${netCashPaisa >= 0 ? 'var(--success-color)' : 'var(--danger-color)'};">${formatTaka(netCashPaisa)}</strong></td>
            </tr>
        `;
    });

    setSafeHTML(tbody, rowsHTML);
}

// Render Top Purchased Market Products Frequency Table
function renderProductFrequencyTable(filteredExpenses) {
    const tbody = document.getElementById("product-freq-table-body");
    if (!tbody) return;

    const freqMap = {};
    filteredExpenses.forEach((exp) => {
        if (Array.isArray(exp.products)) {
            exp.products.forEach((p) => {
                const clean = (p || "").trim();
                if (clean) {
                    freqMap[clean] = (freqMap[clean] || 0) + 1;
                }
            });
        }
    });

    const sortedProducts = Object.keys(freqMap).map(k => ({ name: k, count: freqMap[k] })).sort((a, b) => b.count - a.count);

    if (sortedProducts.length === 0) {
        setSafeHTML(tbody, `<tr><td colspan="3" class="empty-state">No product records found.</td></tr>`);
        return;
    }

    const topList = sortedProducts.slice(0, 10);
    let rowsHTML = "";
    topList.forEach((item, index) => {
        rowsHTML += `
            <tr>
                <td><strong>${index + 1}</strong></td>
                <td><strong>${item.name}</strong></td>
                <td><span class="badge" style="background:#EEF2FF; color:#4338CA;">${item.count} Times Purchased</span></td>
            </tr>
        `;
    });

    setSafeHTML(tbody, rowsHTML);
}

// Render Member Financial & Meal Contribution Breakdown Table
function renderMemberBreakdownTable(filteredDeposits, filteredExpenses) {
    const tbody = document.getElementById("member-breakdown-table-body");
    if (!tbody) return;

    const memberStats = {};
    membersList.forEach((m) => {
        if (m.role !== "wallet_only") {
            memberStats[m.email] = { name: m.name, email: m.email, confirmedDepPaisa: 0, purchasedPaisa: 0, meals: 0 };
        }
    });

    filteredDeposits.forEach((dep) => {
        if (dep.status === "confirmed" && memberStats[dep.memberEmail]) {
            memberStats[dep.memberEmail].confirmedDepPaisa += (dep.amountInPaisa || 0);
        }
    });

    filteredExpenses.forEach((exp) => {
        if (memberStats[exp.purchasedByEmail]) {
            memberStats[exp.purchasedByEmail].purchasedPaisa += (exp.totalAmountInPaisa || 0);
        }
    });

    const activeMonthId = filterMonth !== "all" ? filterMonth : (availableMonthsList[0] || "");
    const monthData = mealsMap[activeMonthId] || {};
    Object.keys(memberStats).forEach((email) => {
        const val = monthData[email];
        if (typeof val === "number" && val >= 0) {
            memberStats[email].meals = Math.round(val);
        }
    });

    const memberList = Object.values(memberStats).sort((a, b) => a.name.localeCompare(b.name));

    if (memberList.length === 0) {
        setSafeHTML(tbody, `<tr><td colspan="4" class="empty-state">No mess members found.</td></tr>`);
        return;
    }

    let rowsHTML = "";
    memberList.forEach((m) => {
        rowsHTML += `
            <tr>
                <td><strong>${m.name}</strong><br><small style="color:var(--text-muted);">${m.email}</small></td>
                <td><strong>${formatTaka(m.confirmedDepPaisa)}</strong></td>
                <td>${formatTaka(m.purchasedPaisa)}</td>
                <td><span class="meal-badge">${m.meals} Meals</span></td>
            </tr>
        `;
    });

    setSafeHTML(tbody, rowsHTML);
}

// Export Filtered Monthly Summary Table Data to Downloadable CSV File
function exportReportToCSV() {
    const table = document.getElementById("report-summary-table");
    if (!table) return;

    let csvContent = "\uFEFF"; // UTF-8 BOM for Microsoft Excel compatibility
    const rows = table.querySelectorAll("tr");

    rows.forEach((row) => {
        const cols = row.querySelectorAll("th, td");
        const rowData = [];
        cols.forEach((col) => {
            let text = col.innerText.replace(/\n/g, ' ').replace(/"/g, '""').trim();
            rowData.push(`"${text}"`);
        });
        csvContent += rowData.join(",") + "\n";
    });

    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `mess_analytics_report_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}
