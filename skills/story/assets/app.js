const state = {
  workspace: null,
  activeView: "libraries",
  activeFile: null,
  originalContent: "",
  dirty: false,
  mode: "edit",
  filter: "",
  loadingFile: false,
  saving: false,
  deleting: false,
  searching: false,
  searchResults: [],
  searchTruncation: null,
  searchSequence: 0,
  searchTimer: null,
  // Remember directories the author manually expanded/collapsed; don't close the
  // chapter folders they are browsing when the tree redraws
  expandedDirs: new Set(),
  collapsedDirs: new Set(),
};

const elements = {
  workspaceName: document.querySelector("#workspaceName"),
  workspacePath: document.querySelector("#workspacePath"),
  connectionStatus: document.querySelector("#connectionStatus"),
  treeSearch: document.querySelector("#treeSearch"),
  libraryCount: document.querySelector("#libraryCount"),
  projectCount: document.querySelector("#projectCount"),
  fileCount: document.querySelector("#fileCount"),
  librariesBadge: document.querySelector("#librariesBadge"),
  projectsBadge: document.querySelector("#projectsBadge"),
  archiveTabs: [...document.querySelectorAll(".archive-tabs [role='tab']")],
  treePanel: document.querySelector("#treePanel"),
  treeLoading: document.querySelector("#treeLoading"),
  fileTree: document.querySelector("#fileTree"),
  refreshButton: document.querySelector("#refreshButton"),
  mobileBackButton: document.querySelector("#mobileBackButton"),
  editorEmpty: document.querySelector("#editorEmpty"),
  editorWorkspace: document.querySelector("#editorWorkspace"),
  editorTitle: document.querySelector("#editorTitle"),
  breadcrumbs: document.querySelector("#breadcrumbs"),
  dirtyStatus: document.querySelector("#dirtyStatus"),
  documentMeta: document.querySelector("#documentMeta"),
  editorInput: document.querySelector("#editorInput"),
  previewPane: document.querySelector("#previewPane"),
  modeButtons: [...document.querySelectorAll(".mode-switch button")],
  deleteButton: document.querySelector("#deleteButton"),
  saveButton: document.querySelector("#saveButton"),
  cursorPosition: document.querySelector("#cursorPosition"),
  encodingLabel: document.querySelector("#encodingLabel"),
  toastRegion: document.querySelector("#toastRegion"),
  conflictDialog: document.querySelector("#conflictDialog"),
  reloadConflictButton: document.querySelector("#reloadConflictButton"),
  truncationNotice: null,
};

class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
  }
}

async function requestJson(url, options) {
  let response;
  try {
    response = await fetch(url, options);
  } catch {
    setConnection("offline", "Connection lost");
    throw new ApiError(0, "network_error", "Cannot reach the local Dashboard service");
  }

  let payload;
  try {
    payload = await response.json();
  } catch {
    payload = null;
  }

  if (!response.ok) {
    throw new ApiError(
      response.status,
      payload?.error?.code || "request_failed",
      payload?.error?.message || `Request failed (${response.status})`,
    );
  }
  setConnection("online", "Local only");
  return payload;
}

function setConnection(status, label) {
  elements.connectionStatus.dataset.state = status;
  elements.connectionStatus.querySelector("span:last-child").textContent = label;
}

function showToast(message, kind = "success") {
  const toast = document.createElement("div");
  toast.className = "toast";
  toast.dataset.kind = kind;
  const text = document.createElement("p");
  text.textContent = message;
  toast.append(text);
  elements.toastRegion.append(toast);
  window.setTimeout(() => toast.remove(), 4200);
}

function formatNumber(value) {
  return new Intl.NumberFormat("zh-CN").format(value || 0);
}

function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KiB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MiB`;
}

function countCharacters(content) {
  return [...content.replace(/\s/g, "")].length;
}

// The textarea value is always LF: normalize on read, restore the original file's
// line endings on write — otherwise one edit would rewrite the whole CRLF
// manuscript and the dirty flag would never match or clear.
function detectEol(content) {
  let crlf = 0;
  let lf = 0;
  let cr = 0;
  for (let index = 0; index < content.length; index += 1) {
    if (content[index] === "\r") {
      if (content[index + 1] === "\n") {
        crlf += 1;
        index += 1;
      } else {
        cr += 1;
      }
    } else if (content[index] === "\n") {
      lf += 1;
    }
  }
  // Write back in the dominant style (LF or CRLF); only pure-CR files keep CR. A
  // stray pasted CR must not spread CR across every LF, nor may a CRLF manuscript
  // silently become all-LF.
  if (crlf > lf) return "\r\n";
  if (lf > 0) return "\n";
  if (cr > 0) return "\r";
  return "\n";
}

function normalizeEol(content) {
  return content.replaceAll("\r\n", "\n").replaceAll("\r", "\n");
}

function applyEol(content, eol) {
  return !eol || eol === "\n" ? content : content.replaceAll("\n", eol);
}

function activeEol() {
  return state.activeFile?.eol || "\n";
}

function currentByteSize() {
  return new TextEncoder().encode(applyEol(elements.editorInput.value, activeEol())).length;
}

function fileExtension(name) {
  const index = name.lastIndexOf(".");
  return index >= 0 ? name.slice(index + 1) : "";
}

function iconSvg(kind) {
  if (kind === "folder") {
    return `<svg class="tree-icon folder-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M3.5 6.5h6l2 2h9v10h-17z"></path></svg>`;
  }
  return `<svg class="tree-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M6 3.5h8l4 4v13H6z"></path><path d="M14 3.5v4h4M9 12h6M9 16h5"></path></svg>`;
}

function createTreeEntry(node, depth = 0) {
  const item = document.createElement("li");
  if (node.type === "directory") {
    const details = document.createElement("details");
    details.dataset.path = node.path;
    const shouldOpen =
      state.expandedDirs.has(node.path) ||
      (depth === 0 && !state.collapsedDirs.has(node.path));
    details.open = shouldOpen;
    // Record only the author's own expand/collapse; programmatic first-level
    // expansion is not a preference.
    let recorded = shouldOpen;
    details.addEventListener("toggle", () => {
      if (details.open === recorded) return;
      recorded = details.open;
      if (details.open) {
        state.expandedDirs.add(node.path);
        state.collapsedDirs.delete(node.path);
        if (!node.loaded && !node.loading) loadDirectory(node);
      } else {
        state.expandedDirs.delete(node.path);
        state.collapsedDirs.add(node.path);
      }
    });
    const summary = document.createElement("summary");
    summary.innerHTML = iconSvg("folder");
    const label = document.createElement("span");
    label.className = "tree-label";
    label.textContent = node.name;
    summary.append(label);
    details.append(summary);

    const list = document.createElement("ul");
    node.children.forEach((child) => {
      const childItem = createTreeEntry(child, depth + 1);
      if (childItem) list.append(childItem);
    });
    if (node.loading) {
      const loading = document.createElement("li");
      loading.className = "tree-inline-status";
      loading.textContent = "Reading directory…";
      list.append(loading);
    } else if (node.loadError) {
      const retry = document.createElement("li");
      retry.className = "tree-inline-status";
      const button = document.createElement("button");
      button.type = "button";
      button.textContent = "Failed to load directory, click to retry";
      button.addEventListener("click", () => loadDirectory(node));
      retry.append(button);
      list.append(retry);
    } else if (node.loaded && node.children.length === 0) {
      const empty = document.createElement("li");
      empty.className = "tree-inline-status";
      empty.textContent = "Empty directory";
      list.append(empty);
    }
    if (node.nextCursor && !node.loading) {
      const more = document.createElement("li");
      more.className = "tree-inline-status";
      const button = document.createElement("button");
      button.type = "button";
      button.textContent = "Load more";
      button.addEventListener("click", () => loadDirectory(node, { append: true }));
      more.append(button);
      list.append(more);
    }
    details.append(list);
    item.append(details);
    if (shouldOpen && !node.loaded && !node.loading && !node.loadError && !node.loadQueued) {
      node.loadQueued = true;
      window.queueMicrotask(() => {
        node.loadQueued = false;
        if (!node.loaded && !node.loading && !node.loadError) loadDirectory(node);
      });
    }
    return item;
  }

  const button = document.createElement("button");
  button.type = "button";
  button.className = "file-row";
  button.dataset.path = node.path;
  button.dataset.active = String(state.activeFile?.path === node.path);
  button.disabled = !node.editable;
  button.title = node.editable ? node.path : `${node.path} (this file type is display-only, not editable)`;
  button.innerHTML = iconSvg("file");

  const label = document.createElement("span");
  label.className = "tree-label";
  label.textContent = node.name;
  button.append(label);

  const extension = document.createElement("span");
  extension.className = "file-ext";
  extension.textContent = fileExtension(node.name);
  button.append(extension);
  if (node.editable) {
    button.addEventListener("click", () => openFile(node.path));
  }
  item.append(button);
  return item;
}

function mergeDirectoryEntries(node, entries, append) {
  if (!append) {
    node.children = entries;
    return;
  }
  const existingPaths = new Set(node.children.map((entry) => entry.path));
  node.children.push(...entries.filter((entry) => !existingPaths.has(entry.path)));
}

async function loadDirectory(node, { append = false } = {}) {
  if (node.loading) return;
  node.loading = true;
  node.loadError = "";
  renderTree();
  try {
    const cursor = append && node.nextCursor ? `&cursor=${encodeURIComponent(node.nextCursor)}` : "";
    const page = await requestJson(`/api/tree?path=${encodeURIComponent(node.path)}${cursor}`);
    mergeDirectoryEntries(node, page.entries, append);
    node.nextCursor = page.nextCursor;
    node.loaded = true;
  } catch (error) {
    node.loadError = error.message;
    showToast(error.message, "error");
  } finally {
    node.loading = false;
    renderLoadedFileCount();
    renderTree();
  }
}

function loadedFileCount() {
  const paths = new Set();
  function visit(node) {
    if (node.type === "file") {
      paths.add(node.path);
      return;
    }
    node.children.forEach(visit);
  }
  state.workspace?.libraries.forEach(visit);
  state.workspace?.projects.forEach(visit);
  return paths.size;
}

function renderLoadedFileCount() {
  if (!state.workspace) return;
  const count = loadedFileCount();
  elements.fileCount.textContent = count ? `${formatNumber(count)}+` : "on demand";
  elements.fileCount.title = "Manuscripts load on demand as directories expand; the whole workspace is not pre-walked";
}

// Update only the highlighted row, not the whole tree — rebuilding would collapse
// every directory the author is browsing
function syncActiveRow() {
  const activePath = state.activeFile?.path;
  elements.fileTree.querySelectorAll(".file-row").forEach((row) => {
    row.dataset.active = String(row.dataset.path === activePath);
  });
}

function searchTruncationMessage() {
  const status = state.searchTruncation;
  if (!status) return "";
  const messages = [];
  if (status.byResults) {
    messages.push(
      `More than ${formatNumber(status.limits.maxResults)} matches found; showing the first ones — enter a more specific file name`,
    );
  }
  if (status.byNodes) {
    messages.push(
      `Search hit the ${formatNumber(status.limits.maxNodes)}-node scan limit; deeper directories were not checked — expand the target directory directly`,
    );
  }
  if (status.byDepth) {
    messages.push(
      `Some directories exceed ${formatNumber(status.limits.maxDepth)} levels; deeper content was not searched; other projects continued`,
    );
  }
  if (status.byReadError) {
    const paths = status.scanErrors.map((entry) => entry.path).filter(Boolean);
    const shown = paths.slice(0, 3).join(", ") || "some directories";
    const more = paths.length > 3 ? `and ${formatNumber(paths.length)} more` : "";
    messages.push(
      `${shown}${more} could not be read; search results may be incomplete. Check directory permissions or external-drive mount state`,
    );
  }
  return messages.join("；");
}

function renderTree() {
  elements.fileTree.replaceChildren();
  elements.treeLoading.hidden = true;
  const query = state.filter.trim();
  const collection = query
    ? state.searchResults
    : state.workspace?.[state.activeView] || [];

  if (query && state.searching) {
    const message = document.createElement("div");
    message.className = "tree-message";
    const text = document.createElement("p");
    text.textContent = `Searching for "${query}"…`;
    message.append(text);
    elements.fileTree.append(message);
    return;
  }

  if (!collection.length) {
    const message = document.createElement("div");
    message.className = "tree-message";
    const text = document.createElement("p");
    text.textContent = query
      ? state.searchTruncation
        ? `Search incomplete — cannot confirm whether the query exists`
        : `No results for the query`
      : state.activeView === "libraries"
        ? "No teardowns in this workspace yet. Run a teardown skill and the archives will appear here."
        : "No writing projects recognized yet. Long-form needs a prose, outline, setting, or tracking directory; short-form needs prose.md plus section-outline.md or setting.md.";
    message.append(text);
    elements.fileTree.append(message);
    const truncation = searchTruncationMessage();
    if (query && truncation) {
      const status = document.createElement("div");
      status.className = "tree-message";
      status.setAttribute("role", "status");
      const statusText = document.createElement("p");
      statusText.textContent = truncation;
      status.append(statusText);
      elements.fileTree.append(status);
    }
    return;
  }

  const list = document.createElement("ul");
  collection.forEach((node) => {
    const item = createTreeEntry(node);
    if (item) list.append(item);
  });
  const truncation = searchTruncationMessage();
  if (query && truncation) {
    const status = document.createElement("li");
    status.className = "tree-inline-status";
    status.setAttribute("role", "status");
    status.textContent = truncation;
    list.append(status);
  }
  elements.fileTree.append(list);
}

function truncationMessage(scanErrors = []) {
  const paths = scanErrors.map((entry) => entry.path).filter(Boolean);
  const shown = paths.slice(0, 3).join(", ") || "some directories";
  const more = paths.length > 3 ? `and ${formatNumber(paths.length)} more` : "";
  return `${shown}${more} could not be read; their manuscripts are not listed. Check directory permissions and external-drive mount state, then refresh after restoring.`;
}

function renderTruncationNotice(limits, scanErrors) {
  if (!limits?.truncated) {
    elements.truncationNotice?.remove();
    elements.truncationNotice = null;
    return;
  }
  if (!elements.truncationNotice) {
    const notice = document.createElement("div");
    notice.id = "treeTruncationNotice";
    notice.className = "tree-message";
    notice.setAttribute("role", "status");
    notice.append(document.createElement("p"));
    elements.treePanel.insertBefore(notice, elements.fileTree);
    elements.truncationNotice = notice;
  }
  elements.truncationNotice.querySelector("p").textContent = truncationMessage(scanErrors);
}

function renderWorkspace() {
  const { workspace, stats, libraries, projects, limits, scanErrors } = state.workspace;
  elements.workspaceName.textContent = workspace.name;
  elements.workspacePath.textContent = workspace.path;
  elements.workspacePath.title = workspace.path;
  elements.libraryCount.textContent = formatNumber(stats.libraries);
  elements.projectCount.textContent = formatNumber(stats.projects);
  renderLoadedFileCount();
  elements.librariesBadge.textContent = formatNumber(libraries.length);
  elements.projectsBadge.textContent = formatNumber(projects.length);
  renderTruncationNotice(limits, scanErrors);
  renderTree();
}

async function loadWorkspace({ announce = false } = {}) {
  window.clearTimeout(state.searchTimer);
  state.searchSequence += 1;
  elements.treeLoading.hidden = false;
  elements.fileTree.replaceChildren();
  setConnection("", "Connecting");
  try {
    state.workspace = await requestJson("/api/workspace");
    state.searchResults = [];
    state.searchTruncation = null;
    state.searching = Boolean(state.filter.trim());
    renderWorkspace();
    if (state.filter.trim()) scheduleSearch();
    if (announce) showToast("Workspace refreshed");
  } catch (error) {
    elements.treeLoading.hidden = true;
    const message = document.createElement("div");
    message.className = "tree-message";
    const text = document.createElement("p");
    text.textContent = error.message;
    message.append(text);
    elements.fileTree.replaceChildren(message);
    showToast(error.message, "error");
  }
}

function confirmDiscard() {
  return !state.dirty || window.confirm("This manuscript has unsaved changes. Discard them and open another file?");
}

function setDirty(dirty) {
  state.dirty = dirty;
  elements.dirtyStatus.dataset.state = dirty ? "dirty" : "saved";
  elements.dirtyStatus.querySelector("span:last-child").textContent = dirty ? "Unsaved" : "Saved";
  syncActionAvailability();
}

function syncActionAvailability() {
  const busy = state.loadingFile || state.saving || state.deleting;
  elements.saveButton.disabled = busy || !state.dirty;
  elements.deleteButton.disabled = busy || !state.activeFile;
}

function setSaving(saving) {
  state.saving = saving;
  elements.dirtyStatus.dataset.state = saving ? "saving" : state.dirty ? "dirty" : "saved";
  elements.dirtyStatus.querySelector("span:last-child").textContent = saving
    ? "Saving…"
    : state.dirty
      ? "Unsaved"
      : "Saved";
  syncActionAvailability();
}

function renderBreadcrumbs(path) {
  elements.breadcrumbs.replaceChildren();
  path.split("/").forEach((part, index, parts) => {
    const label = document.createElement("span");
    label.textContent = part;
    elements.breadcrumbs.append(label);
    if (index < parts.length - 1) {
      const divider = document.createElement("i");
      divider.textContent = "／";
      elements.breadcrumbs.append(divider);
    }
  });
}

function updateDocumentMeta() {
  if (!state.activeFile) return;
  const content = elements.editorInput.value;
  elements.documentMeta.textContent = [
    formatBytes(currentByteSize()),
    `${formatNumber(countCharacters(content))} characters`,
    fileExtension(state.activeFile.name).toUpperCase(),
  ].join("  ·  ");
}

function updateCursorPosition() {
  const content = elements.editorInput.value;
  const caret = elements.editorInput.selectionStart;
  const before = content.slice(0, caret);
  const lines = before.split("\n");
  elements.cursorPosition.textContent = `Line ${lines.length}, column ${[...lines.at(-1)].length + 1}`;
}

async function openFile(path, { force = false } = {}) {
  if (state.loadingFile || (!force && !confirmDiscard())) return;
  state.loadingFile = true;
  syncActionAvailability();
  elements.fileTree.setAttribute("aria-busy", "true");
  try {
    const file = await requestJson(`/api/file?path=${encodeURIComponent(path)}`);
    const normalized = normalizeEol(file.content);
    file.eol = detectEol(file.content);
    file.content = normalized;
    state.activeFile = file;
    state.originalContent = normalized;
    elements.editorInput.value = normalized;
    elements.editorTitle.textContent = file.name;
    renderBreadcrumbs(file.path);
    setDirty(false);
    setMode("edit");
    updateDocumentMeta();
    updateCursorPosition();
    elements.editorEmpty.hidden = true;
    elements.editorWorkspace.hidden = false;
    document.body.classList.add("document-open");
    syncActiveRow();
    window.requestAnimationFrame(() => elements.editorInput.focus());
  } catch (error) {
    showToast(error.message, "error");
  } finally {
    state.loadingFile = false;
    syncActionAvailability();
    elements.fileTree.removeAttribute("aria-busy");
  }
}

function escapeHtml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function inlineMarkdown(value) {
  return value
    .replace(/`([^`]+)`/g, "<code>$1</code>")
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(/__([^_]+)__/g, "<strong>$1</strong>")
    .replace(/(?<!\*)\*([^*\n]+)\*(?!\*)/g, "<em>$1</em>");
}

function markdownToSafeHtml(markdown) {
  const lines = escapeHtml(markdown).replaceAll("\r\n", "\n").split("\n");
  const output = [];
  let inCode = false;
  let codeLines = [];
  let listType = null;

  const closeList = () => {
    if (listType) output.push(`</${listType}>`);
    listType = null;
  };

  for (const line of lines) {
    if (line.trim().startsWith("```")) {
      closeList();
      if (inCode) {
        output.push(`<pre><code>${codeLines.join("\n")}</code></pre>`);
        codeLines = [];
      }
      inCode = !inCode;
      continue;
    }
    if (inCode) {
      codeLines.push(line);
      continue;
    }

    const heading = line.match(/^(#{1,4})\s+(.+)$/);
    const unordered = line.match(/^\s*[-*+]\s+(.+)$/);
    const ordered = line.match(/^\s*\d+[.)]\s+(.+)$/);
    if (heading) {
      closeList();
      const level = heading[1].length;
      output.push(`<h${level}>${inlineMarkdown(heading[2])}</h${level}>`);
    } else if (unordered || ordered) {
      const nextType = unordered ? "ul" : "ol";
      if (listType !== nextType) {
        closeList();
        listType = nextType;
        output.push(`<${listType}>`);
      }
      output.push(`<li>${inlineMarkdown((unordered || ordered)[1])}</li>`);
    } else if (/^\s*([-*_])(?:\s*\1){2,}\s*$/.test(line)) {
      closeList();
      output.push("<hr>");
    } else if (line.startsWith("&gt; ")) {
      closeList();
      output.push(`<blockquote>${inlineMarkdown(line.slice(5))}</blockquote>`);
    } else if (line.trim()) {
      closeList();
      output.push(`<p>${inlineMarkdown(line)}</p>`);
    } else {
      closeList();
    }
  }
  if (inCode) output.push(`<pre><code>${codeLines.join("\n")}</code></pre>`);
  closeList();
  return output.join("");
}

function setMode(mode) {
  state.mode = mode;
  elements.modeButtons.forEach((button) => {
    button.setAttribute("aria-pressed", String(button.dataset.mode === mode));
  });
  const previewing = mode === "preview";
  elements.editorInput.hidden = previewing;
  elements.previewPane.hidden = !previewing;
  if (previewing) {
    elements.previewPane.innerHTML = markdownToSafeHtml(elements.editorInput.value);
  } else {
    window.requestAnimationFrame(() => elements.editorInput.focus());
  }
}

async function saveFile() {
  if (!state.activeFile || !state.dirty || state.saving || state.deleting) return;
  // Snapshot the identity and content before sending: the author may switch files
  // or keep typing during the save; the completion must only write back to the
  // file this request actually sent — never another manuscript.
  const file = state.activeFile;
  const sent = elements.editorInput.value;
  setSaving(true);
  try {
    const saved = await requestJson("/api/file", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        path: file.path,
        content: applyEol(sent, file.eol),
        expectedVersion: file.version,
      }),
    });
    file.mtimeMs = saved.mtimeMs;
    file.version = saved.version;
    file.size = saved.size;
    showToast(`Saved "${file.name}"`);
    if (state.activeFile !== file) return;
    state.originalContent = sent;
    // Keystrokes during the save are still unsaved changes; this result must not
    // flatten them into "Saved".
    setDirty(elements.editorInput.value !== sent);
    updateDocumentMeta();
  } catch (error) {
    if (state.activeFile !== file) {
      showToast(`Failed to save "${file.name}": ${error.message}`, "error");
      return;
    }
    setDirty(true);
    if (error instanceof ApiError && error.status === 409) {
      elements.conflictDialog.showModal();
    } else {
      showToast(error.message, "error");
    }
  } finally {
    setSaving(false);
  }
}

async function deleteFile() {
  if (!state.activeFile || state.saving || state.deleting) return;
  const file = state.activeFile;
  const warning = state.dirty
    ? `"${file.name}" still has unsaved changes. Deleting permanently removes the file from disk and discards those changes — this cannot be undone. Delete anyway?`
    : `Permanently delete "${file.name}"? This cannot be undone.`;
  if (!window.confirm(warning)) return;

  state.deleting = true;
  syncActionAvailability();
  try {
    await requestJson("/api/file", {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        path: file.path,
        expectedVersion: file.version,
      }),
    });
    state.activeFile = null;
    state.originalContent = "";
    elements.editorInput.value = "";
    elements.editorWorkspace.hidden = true;
    elements.editorEmpty.hidden = false;
    document.body.classList.remove("document-open");
    setDirty(false);
    await loadWorkspace();
    showToast(`Deleted "${file.name}"`);
  } catch (error) {
    showToast(error.message, "error");
  } finally {
    state.deleting = false;
    syncActionAvailability();
  }
}

async function searchWorkspace(query, sequence) {
  state.searching = true;
  renderTree();
  try {
    const result = await requestJson(
      `/api/search?q=${encodeURIComponent(query)}&scope=${encodeURIComponent(state.activeView)}`,
    );
    if (sequence !== state.searchSequence) return;
    state.searchResults = result.results;
    state.searchTruncation = result.truncated
      ? {
          ...(result.truncation || {
            byResults: true,
            byNodes: false,
            byDepth: false,
            byReadError: false,
          }),
          scanErrors: result.scanErrors || [],
          limits: result.limits,
        }
      : null;
  } catch (error) {
    if (sequence !== state.searchSequence) return;
    state.searchResults = [];
    state.searchTruncation = null;
    showToast(error.message, "error");
  } finally {
    if (sequence === state.searchSequence) {
      state.searching = false;
      renderTree();
    }
  }
}

function scheduleSearch() {
  window.clearTimeout(state.searchTimer);
  const query = state.filter.trim();
  state.searchSequence += 1;
  const sequence = state.searchSequence;
  if (!query) {
    state.searching = false;
    state.searchResults = [];
    state.searchTruncation = null;
    renderTree();
    return;
  }
  state.searching = true;
  renderTree();
  state.searchTimer = window.setTimeout(() => searchWorkspace(query, sequence), 180);
}

function setActiveView(view) {
  state.activeView = view;
  elements.archiveTabs.forEach((tab) => {
    const selected = tab.dataset.view === view;
    tab.setAttribute("aria-selected", String(selected));
    tab.tabIndex = selected ? 0 : -1;
  });
  elements.treePanel.setAttribute(
    "aria-labelledby",
    view === "libraries" ? "librariesTab" : "projectsTab",
  );
  if (state.filter.trim()) {
    scheduleSearch();
  } else {
    renderTree();
  }
}

elements.archiveTabs.forEach((tab) => {
  tab.addEventListener("click", () => setActiveView(tab.dataset.view));
  tab.addEventListener("keydown", (event) => {
    if (!["ArrowLeft", "ArrowRight"].includes(event.key)) return;
    event.preventDefault();
    const direction = event.key === "ArrowRight" ? 1 : -1;
    const current = elements.archiveTabs.indexOf(event.currentTarget);
    const next = elements.archiveTabs.at(
      (current + direction + elements.archiveTabs.length) % elements.archiveTabs.length,
    );
    setActiveView(next.dataset.view);
    next.focus();
  });
});

elements.treeSearch.addEventListener("input", (event) => {
  state.filter = event.currentTarget.value;
  scheduleSearch();
});

elements.treeSearch.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    event.currentTarget.value = "";
    state.filter = "";
    scheduleSearch();
  }
});

elements.refreshButton.addEventListener("click", () => loadWorkspace({ announce: true }));
elements.mobileBackButton.addEventListener("click", () => {
  document.body.classList.remove("document-open");
  window.requestAnimationFrame(() => elements.treeSearch.focus());
});
elements.saveButton.addEventListener("click", saveFile);
elements.deleteButton.addEventListener("click", deleteFile);

elements.editorInput.addEventListener("input", () => {
  setDirty(elements.editorInput.value !== state.originalContent);
  updateDocumentMeta();
  updateCursorPosition();
});

["click", "keyup", "select"].forEach((eventName) => {
  elements.editorInput.addEventListener(eventName, updateCursorPosition);
});

elements.modeButtons.forEach((button) => {
  button.addEventListener("click", () => setMode(button.dataset.mode));
});

elements.conflictDialog.addEventListener("close", () => {
  if (elements.conflictDialog.returnValue === "reload" && state.activeFile) {
    openFile(state.activeFile.path, { force: true });
  }
});

document.addEventListener("keydown", (event) => {
  const modifier = event.metaKey || event.ctrlKey;
  if (modifier && event.key.toLocaleLowerCase() === "s") {
    event.preventDefault();
    saveFile();
  }
  if (modifier && event.key.toLocaleLowerCase() === "k") {
    event.preventDefault();
    elements.treeSearch.focus();
    elements.treeSearch.select();
  }
});

window.addEventListener("beforeunload", (event) => {
  if (state.dirty) {
    event.preventDefault();
    event.returnValue = "";
  }
});

loadWorkspace();
