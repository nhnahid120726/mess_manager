// Phase 8: Monthly Meals Management Module (Read-Only Dynamic Email Field Processor)
import { db, setSafeHTML } from "./firebase.js";
import { collection, getDocs } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";

// DOM Reference
const contentArea = document.getElementById("content-area");

// Module Cache & State
let monthlyMealsDocMap = {}; // docId -> raw data map
let availableMonthsList = []; // sorted month IDs (YYYY-MM)
let selectedMonthId = "";
let memberMap = {}; // email -> member profile object

let currentMonthMealsList = [];
let filteredMealsList = [];

// Filter States
let searchQuery = "";
let sortFilter = "highest_to_lowest";
let memberFilter = "all";

// Pagination State
let currentPage = 1;
const pageSize = 10;

// Helper: Calculate Previous Month ID (e.g., '2026-10' -> '2026-09')
function getPreviousMonthId(monthId) {
    if (!monthId || !monthId.includes("-")) return "";
    const parts = monthId.split("-");
    let year = parseInt(parts[0], 10);
    let month = parseInt(parts[1], 10);

    if (isNaN(year) || isNaN(month)) return "";

    month--;
    if (month < 1) {
        month = 12;
        year--;
    }

    return `${year}-${String(month).padStart(2, '0')}`;
}

// Load and Process Monthly Meals Module
export async function loadMealsModule() {
    if (!contentArea) return;

    setSafeHTML(contentArea, `
        <div class="loading-box">
            <div class="spinner"></div>
            <p>Fetching monthly meals directory from Firestore...</p>
        </div>
    `);

    try {
        // 1. Load Members for Email -> Profile Mapping if not cached yet
        if (Object.keys(memberMap).length === 0) {
            const membersSnap = await getDocs(collection(db, "members"));
            membersSnap.forEach((docSnap) => {
                const data = docSnap.data();
                const email = docSnap.id || data.email;
                if (email) {
                    memberMap[email] = {
                        name: data.name || email,
                        email: email,
                        role: data.role || "member",
                        isAuthorized: data.isAuthorized === true
                    };
                }
            });
        }

        // 2. Fetch 'monthly_meals' Collection
        const mealsSnap = await getDocs(collection(db, "monthly_meals"));
        monthlyMealsDocMap = {};
        availableMonthsList = [];

        mealsSnap.forEach((docSnap) => {
            const monthId = docSnap.id;
            monthlyMealsDocMap[monthId] = docSnap.data() || {};
            availableMonthsList.push(monthId);
        });

        // Sort Month IDs in descending order (Newest first)
        availableMonthsList.sort().reverse();

        // Default to latest available month
        if (availableMonthsList.length > 0) {
            if (!selectedMonthId || !availableMonthsList.includes(selectedMonthId)) {
                selectedMonthId = availableMonthsList[0];
            }
        } else {
            selectedMonthId = "";
        }

        // Process Selected Month Data
        processSelectedMonthData();

    } catch (error) {
        console.error("Error loading monthly_meals collection:", error);
        setSafeHTML(contentArea, `
            <div class="error-msg visible" style="margin-top: 0;">
                <strong>Error Loading Monthly Meals:</strong> ${error.message || "Failed to fetch 'monthly_meals' collection from Firestore."}
            </div>
        `);
    }
}

// Extract and Process Member Meals for Selected Month
function processSelectedMonthData() {
    currentMonthMealsList = [];
    const monthData = monthlyMealsDocMap[selectedMonthId] || {};

    // Process Dynamic Email Fields
    Object.keys(monthData).forEach((key) => {
        const val = monthData[key];

        // Validate Key is an Email and Value is a Valid Numeric Meal Count
        if (typeof key === "string" && key.includes("@") && typeof val === "number" && val >= 0) {
            const memberObj = memberMap[key];
            currentMonthMealsList.push({
                email: key,
                name: memberObj ? memberObj.name : key,
                count: Math.round(val),
                existsInMembers: !!memberObj,
                role: memberObj ? memberObj.role : "unknown",
                isAuthorized: memberObj ? memberObj.isAuthorized : null
            });
        }
    });

    // Default Sorting: Highest to Lowest
    currentMonthMealsList.sort((a, b) => b.count - a.count);

    renderMealsUI();
}

// Render Main Meals Page UI
function renderMealsUI() {
    if (!contentArea) return;

    if (availableMonthsList.length === 0) {
        setSafeHTML(contentArea, `
            <div class="placeholder-tab">
                <h2>Monthly Meals Directory</h2>
                <p>No monthly meals records found in the <code>monthly_meals</code> collection.</p>
            </div>
        `);
        return;
    }

    // 1. Calculate Selected Month Summary Stats
    const counts = currentMonthMealsList.map((m) => m.count);
    const totalMeals = counts.reduce((sum, c) => sum + c, 0);
    const totalMembersCount = currentMonthMealsList.length;
    const averageMeals = totalMembersCount > 0 ? (totalMeals / totalMembersCount).toFixed(1) : "0";
    const highestMeals = counts.length > 0 ? Math.max(...counts) : 0;
    const lowestMeals = counts.length > 0 ? Math.min(...counts) : 0;

    // 2. Calculate Monthly Comparison
    const prevMonthId = getPreviousMonthId(selectedMonthId);
    const prevMonthData = monthlyMealsDocMap[prevMonthId];
    let prevTotalMeals = null;
    let mealDiffText = "N/A";
    let percentChangeText = "N/A";
    let trendClass = "trend-neutral";
    let barPercent = 50;

    if (prevMonthData) {
        let pSum = 0;
        Object.keys(prevMonthData).forEach((k) => {
            const v = prevMonthData[k];
            if (typeof k === "string" && k.includes("@") && typeof v === "number" && v >= 0) {
                pSum += Math.round(v);
            }
        });
        prevTotalMeals = pSum;

        const diff = totalMeals - prevTotalMeals;
        if (diff > 0) {
            mealDiffText = `+${diff} Meals`;
            trendClass = "trend-up";
        } else if (diff < 0) {
            mealDiffText = `${diff} Meals`;
            trendClass = "trend-down";
        } else {
            mealDiffText = `0 Meals (No change)`;
            trendClass = "trend-neutral";
        }

        if (prevTotalMeals > 0) {
            const pct = ((diff / prevTotalMeals) * 100).toFixed(1);
            percentChangeText = pct > 0 ? `+${pct}%` : `${pct}%`;
        } else {
            percentChangeText = "N/A";
        }

        const maxM = Math.max(totalMeals, prevTotalMeals, 1);
        barPercent = Math.round((totalMeals / maxM) * 100);
    }

    // Build Month Select Options
    let monthSelectOptionsHTML = "";
    availableMonthsList.forEach((m) => {
        monthSelectOptionsHTML += `<option value="${m}" ${selectedMonthId === m ? "selected" : ""}>${m}</option>`;
    });

    setSafeHTML(contentArea, `
        <!-- Month Selector Header -->
        <div class="month-picker-container">
            <div>
                <h3 style="font-size: 18px; font-weight: 700; color: var(--primary-dark);">Monthly Meals Overview</h3>
                <p style="font-size: 13px; color: var(--text-muted); margin-top: 2px;">Select a month to inspect member meal counts & trends</p>
            </div>
            <div style="display: flex; align-items: center; gap: 10px;">
                <label style="font-size: 13.5px; font-weight: 700; color: var(--text-muted);">Selected Month:</label>
                <select id="meals-month-select" class="month-select">
                    ${monthSelectOptionsHTML}
                </select>
            </div>
        </div>

        <!-- Summary Cards (6 Cards) -->
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Meals</span>
                    <div class="card-icon icon-purple">🍽️</div>
                </div>
                <div class="card-value">${totalMeals}</div>
                <div class="card-subtext">Sum of meals in ${selectedMonthId}</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Total Members</span>
                    <div class="card-icon icon-blue">👥</div>
                </div>
                <div class="card-value">${totalMembersCount}</div>
                <div class="card-subtext">Members with meal records</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Average Meals</span>
                    <div class="card-icon icon-cyan">📊</div>
                </div>
                <div class="card-value">${averageMeals}</div>
                <div class="card-subtext">Average meals per member</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Highest Meals</span>
                    <div class="card-icon icon-green">🥇</div>
                </div>
                <div class="card-value">${highestMeals}</div>
                <div class="card-subtext">Maximum meal count</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Lowest Meals</span>
                    <div class="card-icon icon-amber">📉</div>
                </div>
                <div class="card-value">${lowestMeals}</div>
                <div class="card-subtext">Minimum meal count</div>
            </div>

            <div class="metric-card">
                <div class="card-header-row">
                    <span class="card-label">Active Month</span>
                    <div class="card-icon icon-indigo">📅</div>
                </div>
                <div class="card-value" style="font-size:22px;">${selectedMonthId}</div>
                <div class="card-subtext">Selected document ID</div>
            </div>
        </div>

        <!-- Monthly Comparison Section -->
        <div class="comparison-card">
            <h3>Monthly Meals Comparison (${selectedMonthId} vs ${prevMonthId || "Previous Month"})</h3>
            <div class="comparison-grid">
                <div class="comparison-stat">
                    <div class="label">Current Month Meals (${selectedMonthId})</div>
                    <div class="val">${totalMeals} Meals</div>
                </div>
                <div class="comparison-stat">
                    <div class="label">Previous Month Meals (${prevMonthId || "N/A"})</div>
                    <div class="val">${prevTotalMeals !== null ? prevTotalMeals + " Meals" : "N/A"}</div>
                </div>
                <div class="comparison-stat">
                    <div class="label">Difference</div>
                    <div class="val ${trendClass}">${mealDiffText}</div>
                </div>
                <div class="comparison-stat">
                    <div class="label">Percentage Change</div>
                    <div class="val ${trendClass}">${percentChangeText}</div>
                </div>
            </div>
            <div class="comparison-bar-bg">
                <div class="comparison-bar-fill" style="width: ${barPercent}%;"></div>
            </div>
        </div>

        <!-- Search & Filter Controls -->
        <div class="filter-bar">
            <input
                type="text"
                id="meal-search-input"
                class="search-input"
                placeholder="🔍 Search Member Name, Email, or Meal Count..."
                value="${searchQuery}"
            />

            <select id="meal-sort-filter" class="select-filter">
                <option value="highest_to_lowest" ${sortFilter === "highest_to_lowest" ? "selected" : ""}>Sort: Highest to Lowest</option>
                <option value="lowest_to_highest" ${sortFilter === "lowest_to_highest" ? "selected" : ""}>Sort: Lowest to Highest</option>
            </select>

            <select id="meal-member-filter" class="select-filter">
                <option value="all" ${memberFilter === "all" ? "selected" : ""}>All Members</option>
                <option value="existing" ${memberFilter === "existing" ? "selected" : ""}>Existing Members</option>
                <option value="unknown" ${memberFilter === "unknown" ? "selected" : ""}>Unknown Members</option>
            </select>
        </div>

        <!-- Table Card -->
        <div class="table-card">
            <div class="card-header-row" style="margin-bottom: 16px;">
                <h4>Member Meals Breakdown (${selectedMonthId}) — <span id="filtered-count">${totalMembersCount}</span> Entries</h4>
            </div>

            <div class="table-responsive">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th style="width: 50px;">#</th>
                            <th>Member Name</th>
                            <th>Member Email</th>
                            <th>Total Meals</th>
                            <th>Member Status</th>
                            <th style="width: 110px; text-align: right;">Action</th>
                        </tr>
                    </thead>
                    <tbody id="meals-table-body">
                        <!-- Rows injected via applyMealFilters() -->
                    </tbody>
                </table>
            </div>

            <!-- Pagination Bar -->
            <div class="pagination-bar">
                <div class="page-info" id="meal-pagination-info">Showing 0-0 of 0</div>
                <div class="pagination-controls">
                    <button class="btn btn-outline btn-sm" id="prev-meal-btn" disabled>Previous</button>
                    <span class="page-info" id="current-meal-page-label">Page 1</span>
                    <button class="btn btn-outline btn-sm" id="next-meal-btn" disabled>Next</button>
                </div>
            </div>
        </div>

        <!-- Details Modal Container -->
        <div id="meal-details-modal" class="modal-backdrop" style="display: none;"></div>
    `);

    // Bind Month Picker Listener
    const monthSelect = document.getElementById("meals-month-select");
    if (monthSelect) {
        monthSelect.addEventListener("change", (e) => {
            selectedMonthId = e.target.value;
            currentPage = 1;
            processSelectedMonthData();
        });
    }

    // Bind Filter Listeners
    const searchInput = document.getElementById("meal-search-input");
    const sortSelect = document.getElementById("meal-sort-filter");
    const memberSelect = document.getElementById("meal-member-filter");

    if (searchInput) {
        searchInput.addEventListener("input", (e) => {
            searchQuery = e.target.value.trim().toLowerCase();
            currentPage = 1;
            applyMealFilters();
        });
    }

    if (sortSelect) {
        sortSelect.addEventListener("change", (e) => {
            sortFilter = e.target.value;
            applyMealFilters();
        });
    }

    if (memberSelect) {
        memberSelect.addEventListener("change", (e) => {
            memberFilter = e.target.value;
            currentPage = 1;
            applyMealFilters();
        });
    }

    // Bind Pagination Listeners
    const prevBtn = document.getElementById("prev-meal-btn");
    const nextBtn = document.getElementById("next-meal-btn");

    if (prevBtn) {
        prevBtn.addEventListener("click", () => {
            if (currentPage > 1) {
                currentPage--;
                renderMealTableRows();
            }
        });
    }

    if (nextBtn) {
        nextBtn.addEventListener("click", () => {
            const maxPage = Math.ceil(filteredMealsList.length / pageSize) || 1;
            if (currentPage < maxPage) {
                currentPage++;
                renderMealTableRows();
            }
        });
    }

    // Apply Initial Filters & Render Table Body
    applyMealFilters();
}

// Apply Search, Sort & Member Filters
function applyMealFilters() {
    filteredMealsList = currentMonthMealsList.filter((m) => {
        const matchesSearch =
            m.name.toLowerCase().includes(searchQuery) ||
            m.email.toLowerCase().includes(searchQuery) ||
            m.count.toString().includes(searchQuery);

        let matchesMemberType = true;
        if (memberFilter === "existing") {
            matchesMemberType = m.existsInMembers === true;
        } else if (memberFilter === "unknown") {
            matchesMemberType = m.existsInMembers === false;
        }

        return matchesSearch && matchesMemberType;
    });

    // Apply Sorting
    if (sortFilter === "lowest_to_highest") {
        filteredMealsList.sort((a, b) => a.count - b.count);
    } else {
        filteredMealsList.sort((a, b) => b.count - a.count);
    }

    currentPage = 1;
    renderMealTableRows();
}

// Render Table Rows with Pagination
function renderMealTableRows() {
    const tbody = document.getElementById("meals-table-body");
    const filteredCountEl = document.getElementById("filtered-count");
    const paginationInfoEl = document.getElementById("meal-pagination-info");
    const currentPageLabelEl = document.getElementById("current-meal-page-label");
    const prevBtn = document.getElementById("prev-meal-btn");
    const nextBtn = document.getElementById("next-meal-btn");

    const totalFiltered = filteredMealsList.length;

    if (filteredCountEl) {
        filteredCountEl.textContent = totalFiltered;
    }

    if (!tbody) return;

    if (totalFiltered === 0) {
        setSafeHTML(tbody, `
            <tr>
                <td colspan="6" class="empty-state">
                    No member meal records found matching the search criteria.
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
    const paginatedList = filteredMealsList.slice(startIndex, endIndex);

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
    paginatedList.forEach((m, index) => {
        const serialNo = startIndex + index + 1;

        // Member Status Badge
        let statusBadgeHTML = "";
        if (m.existsInMembers) {
            statusBadgeHTML = m.isAuthorized
                ? `<span class="status-pill status-confirmed">Authorized Member</span>`
                : `<span class="status-pill status-pending">Unauthorized Member</span>`;
        } else {
            statusBadgeHTML = `<span class="status-pill status-rejected">Unknown Member</span>`;
        }

        rowsHTML += `
            <tr style="cursor: pointer;" class="meal-row" data-email="${m.email}">
                <td><strong>${serialNo}</strong></td>
                <td><strong>${m.name}</strong></td>
                <td>${m.email}</td>
                <td><span class="meal-badge">${m.count} Meals</span></td>
                <td>${statusBadgeHTML}</td>
                <td style="text-align: right;">
                    <button class="btn btn-outline btn-sm view-meal-details-btn" data-email="${m.email}">
                        View Details
                    </button>
                </td>
            </tr>
        `;
    });

    setSafeHTML(tbody, rowsHTML);

    // Attach Click Event Handlers
    document.querySelectorAll(".view-meal-details-btn").forEach((btn) => {
        btn.addEventListener("click", (e) => {
            e.stopPropagation();
            const email = btn.getAttribute("data-email");
            showMealDetailsModal(email);
        });
    });

    document.querySelectorAll(".meal-row").forEach((row) => {
        row.addEventListener("click", () => {
            const email = row.getAttribute("data-email");
            showMealDetailsModal(email);
        });
    });
}

// Show Member Meal Details Modal
function showMealDetailsModal(email) {
    const mealObj = currentMonthMealsList.find((m) => m.email === email);
    if (!mealObj) return;

    const modalContainer = document.getElementById("meal-details-modal");
    if (!modalContainer) return;

    const memberProfile = memberMap[email];

    setSafeHTML(modalContainer, `
        <div class="modal-box">
            <div class="modal-header">
                <h3>Member Meal Details</h3>
                <button class="close-btn" id="close-meal-modal-btn">&times;</button>
            </div>
            <div class="modal-body">
                <div class="detail-row">
                    <span class="detail-label">Member Name</span>
                    <span class="detail-val">${mealObj.name}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Member Email</span>
                    <span class="detail-val">${mealObj.email}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Selected Month ID</span>
                    <span class="detail-val">${selectedMonthId}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Total Monthly Meals</span>
                    <span class="detail-val" style="font-size:18px; color:var(--primary-dark);">${mealObj.count} Meals</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">System Role</span>
                    <span class="detail-val">${memberProfile ? memberProfile.role.toUpperCase() : "N/A (Unknown Member)"}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Authorization Status</span>
                    <span class="detail-val">${memberProfile ? (memberProfile.isAuthorized ? "Authorized" : "Unauthorized") : "N/A"}</span>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline btn-sm" id="modal-close-meal-btn">Close</button>
            </div>
        </div>
    `);

    modalContainer.style.display = "flex";

    // Bind Close Handlers
    const closeX = document.getElementById("close-meal-modal-btn");
    const closeBtn = document.getElementById("modal-close-meal-btn");

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
