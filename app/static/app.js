const state = {
  manuscriptId: Number(window.__INITIAL_MANUSCRIPT_ID__),
  tickets: [],
  selectedTicketId: null,
  manuscriptModalMode: "create",
  pendingDeleteTicketId: null,
  filters: {
    search: "",
    reviewer_id: "",
    comment_category: "",
    status: "",
  },
};

const manuscriptSelect = document.getElementById("manuscriptSelect");
const createManuscriptBtn = document.getElementById("createManuscriptBtn");
const renameManuscriptBtn = document.getElementById("renameManuscriptBtn");
const importFileInput = document.getElementById("importFile");
const importBtn = document.getElementById("importBtn");
const exportMdBtn = document.getElementById("exportMdBtn");
const addTicketBtn = document.getElementById("addTicketBtn");
const searchInput = document.getElementById("searchInput");
const reviewerFilter = document.getElementById("reviewerFilter");
const categoryFilter = document.getElementById("categoryFilter");
const statusFilter = document.getElementById("statusFilter");
const openColumn = document.getElementById("openColumn");
const completedColumn = document.getElementById("completedColumn");
const detailPane = document.getElementById("detailPane");
const statusMessage = document.getElementById("statusMessage");
const nextOpenBtn = document.getElementById("nextOpenBtn");
const prevOpenBtn = document.getElementById("prevOpenBtn");
const themeToggleBtn = document.getElementById("themeToggleBtn");
const newTicketModal = document.getElementById("newTicketModal");
const newTicketError = document.getElementById("newTicketError");
const newReviewerId = document.getElementById("newReviewerId");
const newLineNumber = document.getElementById("newLineNumber");
const newCategory = document.getElementById("newCategory");
const newVerbatim = document.getElementById("newVerbatim");
const newResponse = document.getElementById("newResponse");
const newCompleted = document.getElementById("newCompleted");
const saveNewTicketBtn = document.getElementById("saveNewTicketBtn");
const cancelNewTicketBtn = document.getElementById("cancelNewTicketBtn");
const manuscriptModal = document.getElementById("manuscriptModal");
const manuscriptModalTitle = document.getElementById("manuscriptModalTitle");
const manuscriptModalError = document.getElementById("manuscriptModalError");
const manuscriptNameInput = document.getElementById("manuscriptNameInput");
const saveManuscriptBtn = document.getElementById("saveManuscriptBtn");
const cancelManuscriptBtn = document.getElementById("cancelManuscriptBtn");
const importModal = document.getElementById("importModal");
const importModalError = document.getElementById("importModalError");
const importFileName = document.getElementById("importFileName");
const importManuscriptSelect = document.getElementById("importManuscriptSelect");
const importNewNameRow = document.getElementById("importNewNameRow");
const importNewName = document.getElementById("importNewName");
const confirmImportBtn = document.getElementById("confirmImportBtn");
const cancelImportBtn = document.getElementById("cancelImportBtn");
const deleteTicketModal = document.getElementById("deleteTicketModal");
const deleteTicketError = document.getElementById("deleteTicketError");
const deleteTicketMessage = document.getElementById("deleteTicketMessage");
const confirmDeleteTicketBtn = document.getElementById("confirmDeleteTicketBtn");
const cancelDeleteTicketBtn = document.getElementById("cancelDeleteTicketBtn");

const THEME_KEY = "reviewer_dashboard_theme";

function setStatus(message, isError = false) {
  statusMessage.textContent = message;
  statusMessage.style.color = isError ? "#d92d20" : "var(--status-text)";
}

function applyTheme(theme) {
  document.body.setAttribute("data-theme", theme);
  if (themeToggleBtn) {
    themeToggleBtn.textContent = theme === "dark" ? "Light Theme" : "Dark Theme";
  }
}

function initializeTheme() {
  const stored = localStorage.getItem(THEME_KEY);
  const prefersDark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
  const theme = stored === "dark" || stored === "light" ? stored : prefersDark ? "dark" : "light";
  applyTheme(theme);
}

function toggleTheme() {
  const current = document.body.getAttribute("data-theme") === "dark" ? "dark" : "light";
  const next = current === "dark" ? "light" : "dark";
  localStorage.setItem(THEME_KEY, next);
  applyTheme(next);
}

function resetNewTicketForm() {
  newTicketError.textContent = "";
  newReviewerId.value = "";
  newLineNumber.value = "";
  newCategory.value = "minor";
  newVerbatim.value = "";
  newResponse.value = "";
  newCompleted.checked = false;
}

function openNewTicketModal() {
  resetNewTicketForm();
  newTicketModal.classList.remove("hidden");
  newReviewerId.focus();
}

function closeNewTicketModal() {
  newTicketModal.classList.add("hidden");
}

async function createTicket() {
  const payload = {
    reviewer_id: newReviewerId.value.trim(),
    line_number: newLineNumber.value.trim(),
    comment_category: newCategory.value,
    verbatim_comment: newVerbatim.value.trim(),
    response_text: newResponse.value,
    status: newCompleted.checked ? "COMPLETED" : "OPEN",
  };

  if (payload.status === "COMPLETED" && !payload.response_text.trim()) {
    newTicketError.textContent = "response_text is required before completion.";
    return;
  }

  try {
    const created = await request(`/api/manuscripts/${state.manuscriptId}/tickets`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const createdId = created.ticket.id;
    closeNewTicketModal();
    await loadTickets(false);
    if (state.tickets.some((ticket) => ticket.id === createdId)) {
      selectTicket(createdId);
    }
    setStatus(`Created ticket #${createdId}`);
  } catch (err) {
    newTicketError.textContent = err.message;
    setStatus(err.message, true);
  }
}

async function request(url, options = {}) {
  const response = await fetch(url, options);
  let payload = {};
  try {
    payload = await response.json();
  } catch (_err) {
    payload = {};
  }
  if (!response.ok) {
    const detail = payload.detail || "Request failed";
    throw new Error(detail);
  }
  return payload;
}

function escapeHtml(input) {
  return String(input)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function ticketPreview(text) {
  const raw = text || "";
  if (raw.length <= 90) return raw;
  return `${raw.slice(0, 90)}...`;
}

function buildTicketCard(ticket) {
  const card = document.createElement("button");
  card.type = "button";
  card.className = `ticket-card ${ticket.comment_category}`;
  if (ticket.id === state.selectedTicketId) {
    card.classList.add("selected");
  }
  card.innerHTML = `
    <div class="ticket-meta">
      <span>${escapeHtml(ticket.reviewer_id)}</span>
      <span>Line ${escapeHtml(ticket.line_number_display)}</span>
      <span>${escapeHtml(ticket.comment_category)}</span>
    </div>
    <div class="ticket-preview">${escapeHtml(ticketPreview(ticket.verbatim_comment))}</div>
  `;
  card.addEventListener("click", () => {
    selectTicket(ticket.id);
  });
  return card;
}

function renderBoard() {
  openColumn.innerHTML = "";
  completedColumn.innerHTML = "";

  const openTickets = state.tickets.filter((t) => t.status === "OPEN");
  const completedTickets = state.tickets.filter((t) => t.status === "COMPLETED");

  if (openTickets.length === 0) {
    const empty = document.createElement("div");
    empty.className = "empty";
    empty.textContent = "No open tickets.";
    openColumn.appendChild(empty);
  } else {
    openTickets.forEach((ticket) => openColumn.appendChild(buildTicketCard(ticket)));
  }

  if (completedTickets.length === 0) {
    const empty = document.createElement("div");
    empty.className = "empty";
    empty.textContent = "No completed tickets.";
    completedColumn.appendChild(empty);
  } else {
    completedTickets.forEach((ticket) => completedColumn.appendChild(buildTicketCard(ticket)));
  }
}

function renderDetail(ticket) {
  if (!ticket) {
    detailPane.innerHTML = `
      <h2>Ticket Details</h2>
      <p class="muted">Select a ticket card to edit.</p>
    `;
    return;
  }

  const needsResponseHint = ticket.status === "OPEN" && !(ticket.response_text || "").trim();

  detailPane.innerHTML = `
    <h2>Ticket #${ticket.id}</h2>
    <div id="formMessage"></div>

    <div class="form-row">
      <label for="reviewerIdField">reviewer_id</label>
      <input id="reviewerIdField" value="${escapeHtml(ticket.reviewer_id)}" />
    </div>

    <div class="form-row">
      <label for="lineNumberField">line_number</label>
      <input id="lineNumberField" value="${escapeHtml(ticket.line_number_display)}" />
    </div>

    <div class="form-row">
      <label for="categoryField">comment_category</label>
      <select id="categoryField">
        <option value="editorial" ${ticket.comment_category === "editorial" ? "selected" : ""}>editorial</option>
        <option value="major" ${ticket.comment_category === "major" ? "selected" : ""}>major</option>
        <option value="minor" ${ticket.comment_category === "minor" ? "selected" : ""}>minor</option>
      </select>
    </div>

    <div class="form-row">
      <label for="verbatimField">verbatim_comment</label>
      <textarea id="verbatimField">${escapeHtml(ticket.verbatim_comment)}</textarea>
    </div>

    <div class="form-row">
      <label for="responseField">response_text (required before completion)</label>
      <textarea id="responseField">${escapeHtml(ticket.response_text || "")}</textarea>
      ${needsResponseHint ? '<div class="error">Add response_text before marking completed.</div>' : ""}
    </div>

    <div class="form-row">
      <label>
        <input id="completedField" type="checkbox" ${ticket.status === "COMPLETED" ? "checked" : ""} />
        Completed
      </label>
    </div>

    <div class="detail-actions">
      <button id="saveBtn" class="primary" type="button">Save</button>
      <button id="markCompleteBtn" type="button">Mark completed</button>
      <button id="reopenBtn" type="button">Reopen</button>
      <button id="deleteTicketBtn" class="danger" type="button">Delete Ticket</button>
    </div>
    <p class="muted">Tickets remain editable even after completion.</p>
  `;

  document.getElementById("saveBtn").addEventListener("click", () => saveTicket(ticket.id));
  document.getElementById("markCompleteBtn").addEventListener("click", () => saveTicket(ticket.id, "COMPLETED"));
  document.getElementById("reopenBtn").addEventListener("click", () => saveTicket(ticket.id, "OPEN"));
  document.getElementById("deleteTicketBtn").addEventListener("click", () => openDeleteTicketModal(ticket));
}

async function loadTickets(keepSelection = true) {
  const params = new URLSearchParams();
  if (state.filters.search) params.set("search", state.filters.search);
  if (state.filters.reviewer_id) params.set("reviewer_id", state.filters.reviewer_id);
  if (state.filters.comment_category) params.set("comment_category", state.filters.comment_category);
  if (state.filters.status) params.set("status", state.filters.status);

  const query = params.toString() ? `?${params.toString()}` : "";
  const payload = await request(`/api/manuscripts/${state.manuscriptId}/tickets${query}`);
  state.tickets = payload.tickets;

  const previous = state.selectedTicketId;
  if (!keepSelection || !state.tickets.some((ticket) => ticket.id === previous)) {
    state.selectedTicketId = null;
  }

  updateReviewerFilter(payload.filters.reviewer_ids);
  renderBoard();

  if (state.selectedTicketId) {
    const ticket = state.tickets.find((t) => t.id === state.selectedTicketId);
    renderDetail(ticket || null);
  } else {
    renderDetail(null);
  }
}

function updateReviewerFilter(reviewerIds) {
  const prev = state.filters.reviewer_id;
  reviewerFilter.innerHTML = '<option value="">All reviewers</option>';
  reviewerIds.forEach((id) => {
    const opt = document.createElement("option");
    opt.value = id;
    opt.textContent = id;
    reviewerFilter.appendChild(opt);
  });
  if (reviewerIds.includes(prev)) {
    reviewerFilter.value = prev;
  } else {
    reviewerFilter.value = "";
    state.filters.reviewer_id = "";
  }
}

function selectedTicket() {
  return state.tickets.find((ticket) => ticket.id === state.selectedTicketId) || null;
}

function selectTicket(ticketId) {
  state.selectedTicketId = ticketId;
  renderBoard();
  renderDetail(selectedTicket());
}

function currentFormValues() {
  const reviewerId = document.getElementById("reviewerIdField")?.value || "";
  const lineNumber = document.getElementById("lineNumberField")?.value || "";
  const category = document.getElementById("categoryField")?.value || "";
  const verbatim = document.getElementById("verbatimField")?.value || "";
  const response = document.getElementById("responseField")?.value || "";
  const completedChecked = Boolean(document.getElementById("completedField")?.checked);
  return {
    reviewer_id: reviewerId,
    line_number_display: lineNumber,
    comment_category: category,
    verbatim_comment: verbatim,
    response_text: response,
    status: completedChecked ? "COMPLETED" : "OPEN",
  };
}

async function saveTicket(ticketId, overrideStatus = null) {
  const formMessage = document.getElementById("formMessage");
  const payload = currentFormValues();
  if (overrideStatus) {
    payload.status = overrideStatus;
  }

  if (payload.status === "COMPLETED" && !payload.response_text.trim()) {
    formMessage.className = "error";
    formMessage.textContent = "response_text is required before completion.";
    return;
  }

  try {
    const saved = await request(`/api/tickets/${ticketId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    formMessage.className = "success";
    formMessage.textContent = "Saved";
    setStatus(`Saved ticket #${ticketId}`);

    await loadTickets(false);
    state.selectedTicketId = saved.ticket.id;
    renderBoard();
    renderDetail(saved.ticket);
  } catch (err) {
    formMessage.className = "error";
    formMessage.textContent = err.message;
    setStatus(err.message, true);
  }
}

function addManuscriptOption(manuscript) {
  const opt = document.createElement("option");
  opt.value = String(manuscript.id);
  opt.textContent = manuscript.name;
  manuscriptSelect.appendChild(opt);
  return opt;
}

async function createManuscriptRecord(name) {
  const payload = await request("/api/manuscripts", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name }),
  });
  addManuscriptOption(payload.manuscript);
  return payload.manuscript;
}

function openManuscriptModal(mode) {
  const currentOption = manuscriptSelect.selectedOptions[0];
  if (mode === "rename" && !currentOption) return;
  state.manuscriptModalMode = mode;
  manuscriptModalError.textContent = "";
  manuscriptModalTitle.textContent = mode === "create" ? "New Manuscript" : "Rename Manuscript";
  saveManuscriptBtn.textContent = mode === "create" ? "Create Manuscript" : "Save Name";
  manuscriptNameInput.value = mode === "create" ? "" : currentOption.textContent || "";
  manuscriptModal.classList.remove("hidden");
  manuscriptNameInput.focus();
  manuscriptNameInput.select();
}

function closeManuscriptModal() {
  manuscriptModal.classList.add("hidden");
  manuscriptModalError.textContent = "";
}

async function saveManuscript() {
  const name = manuscriptNameInput.value.trim();
  if (!name) {
    manuscriptModalError.textContent = "Manuscript name is required.";
    return;
  }

  try {
    if (state.manuscriptModalMode === "create") {
      const manuscript = await createManuscriptRecord(name);
      manuscriptSelect.value = String(manuscript.id);
      state.manuscriptId = manuscript.id;
      state.selectedTicketId = null;
      closeManuscriptModal();
      await loadTickets(false);
      setStatus(`Created manuscript \"${manuscript.name}\"`);
      return;
    }

    const payload = await request(`/api/manuscripts/${state.manuscriptId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name }),
    });
    manuscriptSelect.selectedOptions[0].textContent = payload.manuscript.name;
    closeManuscriptModal();
    setStatus(`Renamed manuscript to \"${payload.manuscript.name}\"`);
  } catch (err) {
    manuscriptModalError.textContent = err.message;
    setStatus(err.message, true);
  }
}

function populateImportDestinations() {
  importManuscriptSelect.innerHTML = "";
  Array.from(manuscriptSelect.options).forEach((manuscriptOption) => {
    const option = document.createElement("option");
    option.value = manuscriptOption.value;
    option.textContent = manuscriptOption.textContent;
    importManuscriptSelect.appendChild(option);
  });
  const newOption = document.createElement("option");
  newOption.value = "new";
  newOption.textContent = "Create a new manuscript...";
  importManuscriptSelect.appendChild(newOption);
  importManuscriptSelect.value = String(state.manuscriptId);
  importNewNameRow.classList.add("hidden");
  importNewName.value = "";
}

function openImportModal() {
  const file = importFileInput.files?.[0];
  if (!file) {
    setStatus("Choose a CSV or XLSX file first", true);
    return;
  }
  importModalError.textContent = "";
  importFileName.textContent = file.name;
  populateImportDestinations();
  importModal.classList.remove("hidden");
  importManuscriptSelect.focus();
}

function closeImportModal() {
  importModal.classList.add("hidden");
  importModalError.textContent = "";
}

function updateImportDestinationFields() {
  const creating = importManuscriptSelect.value === "new";
  importNewNameRow.classList.toggle("hidden", !creating);
  if (creating) importNewName.focus();
}

async function importTickets() {
  const file = importFileInput.files?.[0];
  if (!file) {
    importModalError.textContent = "Choose a CSV or XLSX file first.";
    return;
  }

  let targetId = Number(importManuscriptSelect.value);
  if (importManuscriptSelect.value === "new") {
    const name = importNewName.value.trim();
    if (!name) {
      importModalError.textContent = "New manuscript name is required.";
      return;
    }
    confirmImportBtn.disabled = true;
    try {
      const manuscript = await createManuscriptRecord(name);
      targetId = manuscript.id;
      manuscriptSelect.value = String(targetId);
      state.manuscriptId = targetId;
      state.selectedTicketId = null;
      populateImportDestinations();
      importManuscriptSelect.value = String(targetId);
      setStatus(`Created manuscript \"${manuscript.name}\"; ready to import`);
    } catch (err) {
      confirmImportBtn.disabled = false;
      importModalError.textContent = err.message;
      setStatus(err.message, true);
      return;
    }
  } else {
    confirmImportBtn.disabled = true;
  }

  const formData = new FormData();
  formData.append("file", file);

  try {
    const payload = await request(`/api/manuscripts/${targetId}/import`, {
      method: "POST",
      body: formData,
    });
    state.manuscriptId = targetId;
    manuscriptSelect.value = String(targetId);
    state.selectedTicketId = null;
    importFileInput.value = "";
    closeImportModal();
    setStatus(`Imported ${payload.imported} ticket(s)`);
    await loadTickets(false);
  } catch (err) {
    importModalError.textContent = err.message;
    setStatus(err.message, true);
  } finally {
    confirmImportBtn.disabled = false;
  }
}

function openDeleteTicketModal(ticket) {
  state.pendingDeleteTicketId = ticket.id;
  deleteTicketError.textContent = "";
  deleteTicketMessage.textContent = `Delete ticket #${ticket.id} (${ticket.reviewer_id})?`;
  deleteTicketModal.classList.remove("hidden");
  confirmDeleteTicketBtn.focus();
}

function closeDeleteTicketModal() {
  deleteTicketModal.classList.add("hidden");
  deleteTicketError.textContent = "";
  state.pendingDeleteTicketId = null;
}

async function deleteSelectedTicket() {
  const ticketId = state.pendingDeleteTicketId;
  if (!ticketId) return;
  confirmDeleteTicketBtn.disabled = true;
  try {
    await request(`/api/tickets/${ticketId}`, { method: "DELETE" });
    closeDeleteTicketModal();
    state.selectedTicketId = null;
    await loadTickets(false);
    setStatus(`Deleted ticket #${ticketId}`);
  } catch (err) {
    deleteTicketError.textContent = err.message;
    setStatus(err.message, true);
  } finally {
    confirmDeleteTicketBtn.disabled = false;
  }
}

function exportMarkdown() {
  const url = `/api/manuscripts/${state.manuscriptId}/export.md`;
  window.location.href = url;
  setStatus("Downloading markdown export...");
}

function updateFilterState() {
  state.filters.search = searchInput.value.trim();
  state.filters.reviewer_id = reviewerFilter.value;
  state.filters.comment_category = categoryFilter.value;
  state.filters.status = statusFilter.value;
}

async function navigateOpen(direction) {
  const params = new URLSearchParams();
  if (state.selectedTicketId) params.set("current_ticket_id", String(state.selectedTicketId));
  params.set("direction", direction);
  if (state.filters.search) params.set("search", state.filters.search);
  if (state.filters.reviewer_id) params.set("reviewer_id", state.filters.reviewer_id);
  if (state.filters.comment_category) params.set("comment_category", state.filters.comment_category);

  try {
    const payload = await request(`/api/manuscripts/${state.manuscriptId}/next-open?${params.toString()}`);
    if (!payload.ticket) {
      setStatus("No open tickets 🎉");
      return;
    }

    const ticketId = payload.ticket.id;
    const inCurrentList = state.tickets.some((t) => t.id === ticketId);
    if (!inCurrentList) {
      statusFilter.value = "";
      state.filters.status = "";
      await loadTickets(false);
    }
    selectTicket(ticketId);
  } catch (err) {
    setStatus(err.message, true);
  }
}

function keyboardTargetIsInput(target) {
  if (!target) return false;
  const tag = target.tagName.toLowerCase();
  return tag === "input" || tag === "textarea" || tag === "select" || target.isContentEditable;
}

function wireEvents() {
  manuscriptSelect.addEventListener("change", async () => {
    state.manuscriptId = Number(manuscriptSelect.value);
    state.selectedTicketId = null;
    await loadTickets(false);
    setStatus("Switched manuscript");
  });

  createManuscriptBtn.addEventListener("click", () => openManuscriptModal("create"));
  renameManuscriptBtn.addEventListener("click", () => openManuscriptModal("rename"));
  saveManuscriptBtn.addEventListener("click", saveManuscript);
  cancelManuscriptBtn.addEventListener("click", closeManuscriptModal);
  manuscriptNameInput.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      saveManuscript();
    }
  });
  importBtn.addEventListener("click", openImportModal);
  importManuscriptSelect.addEventListener("change", updateImportDestinationFields);
  confirmImportBtn.addEventListener("click", importTickets);
  cancelImportBtn.addEventListener("click", closeImportModal);
  confirmDeleteTicketBtn.addEventListener("click", deleteSelectedTicket);
  cancelDeleteTicketBtn.addEventListener("click", closeDeleteTicketModal);
  exportMdBtn.addEventListener("click", exportMarkdown);
  addTicketBtn.addEventListener("click", openNewTicketModal);
  saveNewTicketBtn.addEventListener("click", createTicket);
  cancelNewTicketBtn.addEventListener("click", closeNewTicketModal);
  newTicketModal.addEventListener("click", (event) => {
    if (event.target === newTicketModal) {
      closeNewTicketModal();
    }
  });
  manuscriptModal.addEventListener("click", (event) => {
    if (event.target === manuscriptModal) closeManuscriptModal();
  });
  importModal.addEventListener("click", (event) => {
    if (event.target === importModal) closeImportModal();
  });
  deleteTicketModal.addEventListener("click", (event) => {
    if (event.target === deleteTicketModal) closeDeleteTicketModal();
  });

  const filterHandler = async () => {
    updateFilterState();
    await loadTickets(true);
  };

  searchInput.addEventListener("input", filterHandler);
  reviewerFilter.addEventListener("change", filterHandler);
  categoryFilter.addEventListener("change", filterHandler);
  statusFilter.addEventListener("change", filterHandler);

  nextOpenBtn.addEventListener("click", () => navigateOpen("next"));
  prevOpenBtn.addEventListener("click", () => navigateOpen("prev"));
  themeToggleBtn.addEventListener("click", toggleTheme);

  window.addEventListener("keydown", async (event) => {
    if (event.key === "Escape") {
      const openModal = [deleteTicketModal, importModal, manuscriptModal, newTicketModal].find(
        (modal) => !modal.classList.contains("hidden"),
      );
      if (openModal) {
        event.preventDefault();
        if (openModal === deleteTicketModal) closeDeleteTicketModal();
        if (openModal === importModal) closeImportModal();
        if (openModal === manuscriptModal) closeManuscriptModal();
        if (openModal === newTicketModal) closeNewTicketModal();
        return;
      }
    }
    if (keyboardTargetIsInput(event.target)) return;
    if (event.key === "n" || event.key === "N") {
      event.preventDefault();
      if (event.shiftKey) {
        await navigateOpen("prev");
      } else {
        await navigateOpen("next");
      }
    }
    if (event.key === "p" || event.key === "P") {
      event.preventDefault();
      await navigateOpen("prev");
    }
  });
}

async function bootstrap() {
  initializeTheme();
  wireEvents();
  await loadTickets(false);
}

bootstrap().catch((err) => {
  setStatus(err.message, true);
});
