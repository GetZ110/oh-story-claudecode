import { mkdir, rm, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { expect, test } from "@playwright/test";

test("browse teardown-lib, search projects, and edit-save with the real demo", async ({ page, request }) => {
  const consoleErrors = [];
  page.on("console", (message) => {
    if (message.type() === "error") consoleErrors.push(message.text());
  });
  page.on("pageerror", (error) => consoleErrors.push(error.message));

  await page.goto("/");
  await expect(page).toHaveTitle(/OH STORY/);
  await expect(page.getByText("OH STORY", { exact: true })).toBeVisible();
  await expect(page.locator("#connectionStatus")).toContainText("Local only");
  await expect(page.locator("#libraryCount")).toHaveText("2");
  await expect(page.locator("#projectCount")).toHaveText("1");
  await expect(page.locator("#fileCount")).not.toHaveText("—");

  await page.locator("#librariesTab").focus();
  await page.locator("#librariesTab").press("ArrowRight");
  await expect(page.locator("#projectsTab")).toHaveAttribute("aria-selected", "true");
  await page.locator("#projectsTab").press("ArrowLeft");
  await expect(page.locator("#librariesTab")).toHaveAttribute("aria-selected", "true");

  await expect(page.locator("#fileTree")).toContainText("The-Last-Knight");
  await expect(page.locator("#fileTree")).toContainText("The-Secret-Keeper");
  await page.locator(".file-row[data-path='teardown-lib/The-Last-Knight/teardown-report.md']").click();
  await expect(page.locator("#editorTitle")).toHaveText("teardown-report.md");
  await expect(page.locator("#editorInput")).toHaveValue(/The Last Knight/);

  const marker = `\n\n<!-- dashboard-e2e-${Date.now()} -->`;
  await page.locator("#editorInput").fill(
    `${await page.locator("#editorInput").inputValue()}${marker}`,
  );
  await expect(page.locator("#dirtyStatus")).toContainText("Unsaved");
  await expect(page.locator("#saveButton")).toBeEnabled();

  const shortcut = process.platform === "darwin" ? "Meta+s" : "Control+s";
  await page.locator("#editorInput").press(shortcut);
  await expect(page.locator("#dirtyStatus")).toContainText("Saved");
  await expect(page.locator("#toastRegion")).toContainText("Saved");

  const activePath = await page.locator(".file-row[data-active='true']").getAttribute("data-path");
  const persisted = await request.get(`/api/file?path=${encodeURIComponent(activePath)}`);
  expect(persisted.ok()).toBeTruthy();
  expect((await persisted.json()).content).toContain(marker.trim());

  await page.locator("#editorInput").fill("<img src=x onerror=alert('unsafe')>\n\n# Safe Preview");
  await page.getByRole("button", { name: "Preview", exact: true }).click();
  await expect(page.locator("#previewPane")).toContainText("<img src=x onerror=alert('unsafe')>");
  await expect(page.locator("#previewPane img")).toHaveCount(0);
  await expect(page.locator("#previewPane h1")).toHaveText("Safe Preview");

  await page.getByRole("tab", { name: /Writing projects/ }).click();
  await expect(page.locator("#treeTruncationNotice")).toHaveCount(0);
  await expect(page.locator("#fileTree")).not.toContainText("relationships.md");
  await page.locator("summary").filter({ hasText: "setting" }).click();
  await expect(page.locator("#fileTree")).toContainText("relationships.md");
  const unfilteredRows = await page.locator("#fileTree .file-row").count();
  expect(unfilteredRows).toBeGreaterThan(1);

  // Search scans server-side on demand; the characters directory has never been
  // expanded, yet corin.md must be found.
  await page.locator("#treeSearch").fill("corin");
  await expect(page.locator("#fileTree")).toContainText("corin.md");
  await expect(page.locator("#fileTree")).not.toContainText("relationships.md");
  await expect(page.locator("#fileTree")).not.toContainText("outline_chapter_003.md");
  await expect(page.locator("#fileTree")).not.toContainText("The-Last-Knight");
  expect(await page.locator("#fileTree .file-row").count()).toBeLessThan(unfilteredRows);
  await page.locator("#refreshButton").click();
  await expect(page.locator("#toastRegion")).toContainText("Workspace refreshed");
  await expect(page.locator("#fileTree")).toContainText("corin.md");

  // Clearing the search returns to the loaded directory; the author's expanded
  // setting directory must not be collapsed.
  await page.locator("#treeSearch").press("Escape");
  await expect(page.locator("#treeSearch")).toHaveValue("");
  await expect(page.locator("#fileTree")).toContainText("relationships.md");
  expect(await page.locator("#fileTree .file-row").count()).toBe(unfilteredRows);

  expect(consoleErrors).toEqual([]);
});

test("confirms before deleting a manuscript from the real demo and refreshes the tree", async ({ page, request }, testInfo) => {
  const retryFiles = [
    "teardown-lib/The-Last-Knight/_progress.md",
    "teardown-lib/The-Last-Knight/quick-preview.md",
    "teardown-lib/The-Last-Knight/overview.md",
  ];
  const filePath = retryFiles[testInfo.retry];
  await page.goto("/");
  await expect(page.locator("#fileCount")).toContainText("+");
  const initialFileCount = Number(
    (await page.locator("#fileCount").textContent()).replace(/[,+]/g, ""),
  );
  expect(Number.isFinite(initialFileCount)).toBeTruthy();

  const fileName = filePath.split("/").at(-1);
  await page.locator(`.file-row[data-path='${filePath}']`).click();
  await expect(page.locator("#editorTitle")).toHaveText(fileName);

  // Asserting inside the dialog callback would assert nothing: the callback does
  // not run when the dialog never opens. Record outside the callback, assert
  // after the click, and test the cancel path first.
  let dismissed = null;
  page.once("dialog", async (dialog) => {
    dismissed = { type: dialog.type(), message: dialog.message() };
    await dialog.dismiss();
  });
  await page.locator("#deleteButton").click();
  await expect.poll(() => dismissed).not.toBeNull();
  expect(dismissed.type).toBe("confirm");
  expect(dismissed.message).toContain(fileName);
  expect(dismissed.message).toContain("cannot be undone");

  await expect(page.locator(`.file-row[data-path='${filePath}']`)).toHaveCount(1);
  await expect(page.locator("#fileCount")).toHaveText(`${initialFileCount}+`);
  await expect(page.locator("#editorTitle")).toHaveText(fileName);
  const survived = await request.get(`/api/file?path=${encodeURIComponent(filePath)}`);
  expect(survived.status()).toBe(200);

  let accepted = null;
  page.once("dialog", async (dialog) => {
    accepted = { type: dialog.type(), message: dialog.message() };
    await dialog.accept();
  });
  await page.locator("#deleteButton").click();
  await expect.poll(() => accepted).not.toBeNull();
  expect(accepted.type).toBe("confirm");
  expect(accepted.message).toContain(fileName);
  expect(accepted.message).toContain("cannot be undone");

  await expect(page.locator("#toastRegion")).toContainText("Deleted");
  await expect(page.locator("#editorEmpty")).toBeVisible();
  await expect(page.locator(`.file-row[data-path='${filePath}']`)).toHaveCount(0);
  await expect(page.locator("#fileCount")).toHaveText(`${initialFileCount - 1}+`);

  const deleted = await request.get(`/api/file?path=${encodeURIComponent(filePath)}`);
  expect(deleted.status()).toBe(404);
});

test("a save finishing after switching files never lands on the newly opened one", async ({ page, request }) => {
  const fileA = "teardown-lib/The-Last-Knight/style.md";
  const fileB = "teardown-lib/The-Last-Knight/teardown-report.md";
  await page.goto("/");
  await expect(page.locator("#fileCount")).not.toHaveText("—");

  // Slow the PUT down to simulate a sync-folder or antivirus-induced slow save
  await page.route("**/api/file", async (route) => {
    if (route.request().method() === "PUT") {
      await new Promise((accept) => setTimeout(accept, 1500));
    }
    await route.continue();
  });

  await page.locator(`.file-row[data-path='${fileA}']`).click();
  await expect(page.locator("#editorTitle")).toHaveText("style.md");
  const markerA = `\n<!-- dashboard-race-a-${Date.now()} -->`;
  await page.locator("#editorInput").fill(
    `${await page.locator("#editorInput").inputValue()}${markerA}`,
  );
  await page.locator("#saveButton").click();
  await expect(page.locator("#dirtyStatus")).toContainText("Saving");

  // Switch to another manuscript and keep typing while the save is in flight
  page.once("dialog", (dialog) => dialog.accept());
  await page.locator(`.file-row[data-path='${fileB}']`).click();
  await expect(page.locator("#editorTitle")).toHaveText("teardown-report.md");
  const markerB = `\n<!-- dashboard-race-b-${Date.now()} -->`;
  await page.locator("#editorInput").fill(
    `${await page.locator("#editorInput").inputValue()}${markerB}`,
  );
  await expect(page.locator("#dirtyStatus")).toContainText("Unsaved");

  // A's save landing may only toast A; B must still be unsaved, never counted as saved
  await expect(page.locator("#toastRegion")).toContainText('Saved "style.md"');
  await expect(page.locator("#dirtyStatus")).toContainText("Unsaved");
  await expect(page.locator("#saveButton")).toBeEnabled();

  const persistedA = await request.get(`/api/file?path=${encodeURIComponent(fileA)}`);
  expect((await persistedA.json()).content).toContain(markerA.trim());
  const staleB = await request.get(`/api/file?path=${encodeURIComponent(fileB)}`);
  expect((await staleB.json()).content).not.toContain(markerB.trim());

  // B's own save must carry B's version, not be poisoned into a false conflict by A's
  await page.locator("#saveButton").click();
  await expect(page.locator("#toastRegion")).toContainText('Saved "teardown-report.md"');
  await expect(page.locator("#dirtyStatus")).toContainText("Saved");
  await expect(page.locator("#conflictDialog")).toBeHidden();
  const savedB = await request.get(`/api/file?path=${encodeURIComponent(fileB)}`);
  expect((await savedB.json()).content).toContain(markerB.trim());
});

test("keystrokes typed while a save is in flight still count as unsaved", async ({ page, request }) => {
  const filePath = "teardown-lib/The-Last-Knight/style.md";
  await page.goto("/");
  await expect(page.locator("#fileCount")).not.toHaveText("—");
  await page.route("**/api/file", async (route) => {
    if (route.request().method() === "PUT") {
      await new Promise((accept) => setTimeout(accept, 1500));
    }
    await route.continue();
  });

  await page.locator(`.file-row[data-path='${filePath}']`).click();
  await expect(page.locator("#editorTitle")).toHaveText("style.md");
  const saveMarker = `\n<!-- dashboard-inflight-saved-${Date.now()} -->`;
  await page.locator("#editorInput").fill(
    `${await page.locator("#editorInput").inputValue()}${saveMarker}`,
  );

  const shortcut = process.platform === "darwin" ? "Meta+s" : "Control+s";
  await page.locator("#editorInput").press(shortcut);
  await expect(page.locator("#dirtyStatus")).toContainText("Saving");
  const lateMarker = "\n<!-- dashboard-inflight-late -->";
  await page.locator("#editorInput").fill(
    `${await page.locator("#editorInput").inputValue()}${lateMarker}`,
  );

  await expect(page.locator("#toastRegion")).toContainText('Saved "style.md"');
  await expect(page.locator("#dirtyStatus")).toContainText("Unsaved");
  await expect(page.locator("#saveButton")).toBeEnabled();

  const persisted = await request.get(`/api/file?path=${encodeURIComponent(filePath)}`);
  const content = (await persisted.json()).content;
  expect(content).toContain(saveMarker.trim());
  expect(content).not.toContain(lateMarker.trim());
});

test("a CRLF manuscript keeps its line endings after one edit, and the dirty flag clears", async ({ page, request }) => {
  const filePath = "long-form/The-Shattered-Throne/setting/style.md";
  const loaded = await request
    .get(`/api/file?path=${encodeURIComponent(filePath)}`)
    .then((response) => response.json());
  const crlfContent = loaded.content.replaceAll("\r\n", "\n").replaceAll("\n", "\r\n");
  const converted = await request.put("/api/file", {
    data: { path: filePath, content: crlfContent, expectedVersion: loaded.version },
  });
  expect(converted.ok()).toBeTruthy();
  expect(crlfContent).toContain("\r\n");

  await page.goto("/");
  await page.getByRole("tab", { name: /Writing projects/ }).click();
  await page.locator("#treeSearch").fill("style.md");
  await page.locator(`.file-row[data-path='${filePath}']`).click();
  await expect(page.locator("#editorTitle")).toHaveText("style.md");
  await expect(page.locator("#dirtyStatus")).toContainText("Saved");

  // Type one character and delete it again: the flag must return to Saved; with
  // a CRLF baseline this would otherwise stick on Unsaved forever.
  await page.locator("#editorInput").press("End");
  await page.locator("#editorInput").pressSequentially("x");
  await expect(page.locator("#dirtyStatus")).toContainText("Unsaved");
  await page.locator("#editorInput").press("Backspace");
  await expect(page.locator("#dirtyStatus")).toContainText("Saved");

  await page.locator("#editorInput").pressSequentially("x");
  await page.locator("#saveButton").click();
  await expect(page.locator("#dirtyStatus")).toContainText("Saved");

  const saved = await request
    .get(`/api/file?path=${encodeURIComponent(filePath)}`)
    .then((response) => response.json());
  expect(saved.content).toContain("\r\n");
  expect(saved.content.replaceAll("\r\n", "")).not.toContain("\n");
  expect(saved.size).toBe(Buffer.byteLength(crlfContent) + Buffer.byteLength("x"));
});

test("a stray CR in an LF manuscript does not turn the whole save CR-only", async ({ page, request }) => {
  const filePath = "long-form/The-Shattered-Throne/setting/style.md";
  const loaded = await request
    .get(`/api/file?path=${encodeURIComponent(filePath)}`)
    .then((response) => response.json());
  const mixedContent = "# Style\nFirst line.\nSecond\rThird.\nFourth line.\n";
  const converted = await request.put("/api/file", {
    data: { path: filePath, content: mixedContent, expectedVersion: loaded.version },
  });
  expect(converted.ok()).toBeTruthy();

  await page.goto("/");
  await page.getByRole("tab", { name: /Writing projects/ }).click();
  await page.locator("#treeSearch").fill("style.md");
  await page.locator(`.file-row[data-path='${filePath}']`).click();
  await expect(page.locator("#editorTitle")).toHaveText("style.md");

  await page.locator("#editorInput").press("End");
  await page.locator("#editorInput").pressSequentially("x");
  await page.locator("#saveButton").click();
  await expect(page.locator("#dirtyStatus")).toContainText("Saved");

  const saved = await request
    .get(`/api/file?path=${encodeURIComponent(filePath)}`)
    .then((response) => response.json());
  expect(saved.content).toContain("\n");
  expect(saved.content).not.toContain("\r");
  expect(saved.content.split("\n")).toHaveLength(6);
});

test("a stray CR in a CRLF manuscript does not trigger a whole-file LF rewrite", async ({ page, request }) => {
  const filePath = "long-form/The-Shattered-Throne/setting/style.md";
  const loaded = await request
    .get(`/api/file?path=${encodeURIComponent(filePath)}`)
    .then((response) => response.json());
  const converted = await request.put("/api/file", {
    data: {
      path: filePath,
      content: "# Style\r\nFirst line.\r\nSecond\rThird.\r\nFourth line.",
      expectedVersion: loaded.version,
    },
  });
  expect(converted.ok()).toBeTruthy();

  await page.goto("/");
  await page.getByRole("tab", { name: /Writing projects/ }).click();
  await page.locator("#treeSearch").fill("style.md");
  await page.locator(`.file-row[data-path='${filePath}']`).click();
  const editor = page.locator("#editorInput");
  await editor.press("End");
  await editor.pressSequentially("\nx");
  await page.locator("#saveButton").click();
  await expect(page.locator("#dirtyStatus")).toContainText("Saved");

  const saved = await request
    .get(`/api/file?path=${encodeURIComponent(filePath)}`)
    .then((response) => response.json());
  expect(saved.content).toContain("\r\n");
  expect(saved.content.replaceAll("\r\n", "")).not.toContain("\r");
  expect(saved.content.split("\r\n")).toHaveLength(6);
});

test("opening a file does not collapse the directory being browsed", async ({ page }) => {
  const rowPath = "long-form/The-Shattered-Throne/outline/outline_chapter_002.md";
  await page.goto("/");
  await page.getByRole("tab", { name: /Writing projects/ }).click();
  await expect(page.locator("#fileTree")).toContainText("The-Shattered-Throne");

  await page.locator("summary").filter({ hasText: "outline" }).click();
  const row = page.locator(`.file-row[data-path='${rowPath}']`);
  await expect(row).toBeVisible();

  await row.click();
  await expect(page.locator("#editorTitle")).toHaveText("outline_chapter_002.md");
  await expect(row).toBeVisible();
  await expect(row).toHaveAttribute("data-active", "true");

  await page.locator("#refreshButton").click();
  await expect(page.locator("#toastRegion")).toContainText("Workspace refreshed");
  await expect(row).toBeVisible();
  await expect(row).toHaveAttribute("data-active", "true");

  await page.locator("#treeSearch").fill("outline_chapter_002");
  await expect(page.locator("#fileTree")).not.toContainText("outline_chapter_003");
  await page.locator("#treeSearch").fill("");
  await expect(row).toBeVisible();
});

test("deep directories are no longer cut by the first-screen scan depth and still resolve on demand", async ({ page, request }) => {
  const workspace = await request.get("/api/workspace").then((response) => response.json());
  const projectPath = workspace.projects[0].path;
  const nestedRoot = resolve(workspace.workspace.path, projectPath, "prose", "Deep Volume");
  const nestedLeaf = resolve(
    nestedRoot,
    ...Array.from({ length: 11 }, (_, index) => `arc-${index + 1}`),
  );

  try {
    await mkdir(nestedLeaf, { recursive: true });
    await writeFile(resolve(nestedLeaf, "buried-chapter.md"), "Deep draft", "utf8");

    await page.goto("/");
    await page.getByRole("tab", { name: /Writing projects/ }).click();
    await page.locator("#treeSearch").fill("buried");
    await expect(page.locator("#fileTree")).toContainText("buried-chapter.md");
    await expect(page.locator("#treeTruncationNotice")).toHaveCount(0);
  } finally {
    await rm(nestedRoot, { recursive: true, force: true });
  }
});

test("an unreadable directory shows permission or mount hints instead of faking an empty library", async ({ page }) => {
  await page.route("**/api/workspace", async (route) => {
    const response = await route.fetch();
    const payload = await response.json();
    payload.libraries = [];
    payload.scanErrors = [
      { path: "teardown-lib", code: "EACCES", message: "Cannot read directory" },
    ];
    payload.limits = {
      ...payload.limits,
      truncated: true,
      truncatedByReadError: true,
    };
    await route.fulfill({ response, json: payload });
  });

  await page.goto("/");
  await expect(page.locator("#treeTruncationNotice")).toContainText("teardown-lib could not be read");
  await expect(page.locator("#treeTruncationNotice")).toContainText("Check directory permissions and external-drive mount state");
  await expect(page.locator("#fileCount")).toHaveAttribute(
    "title",
    "Manuscripts load on demand as directories expand; the whole workspace is not pre-walked",
  );
});

test("a top-level directory that fails to auto-load stops refetching; retry only happens on user click", async ({ page }) => {
  let treeRequests = 0;
  await page.route("**/api/workspace", async (route) => {
    const response = await route.fetch();
    const payload = await response.json();
    payload.libraries = [
      {
        name: "Broken Archive",
        path: "teardown-lib/Broken Archive",
        type: "directory",
        children: [],
        loaded: false,
      },
    ];
    payload.stats.libraries = 1;
    await route.fulfill({ response, json: payload });
  });
  await page.route("**/api/tree?*", async (route) => {
    const url = new URL(route.request().url());
    if (url.searchParams.get("path") !== "teardown-lib/Broken Archive") {
      await route.continue();
      return;
    }
    treeRequests += 1;
    await route.fulfill({
      status: 403,
      contentType: "application/json",
      body: JSON.stringify({
        error: {
          code: "directory_unreadable",
          message: "Cannot read directory, check permissions or mount state: teardown-lib/Broken Archive",
        },
      }),
    });
  });

  await page.goto("/");
  const retry = page.getByRole("button", { name: "Failed to load directory, click to retry" });
  await expect(retry).toBeVisible();
  await page.waitForTimeout(500);
  expect(treeRequests).toBe(1);
  await expect(page.locator("#toastRegion .toast")).toHaveCount(1);

  await retry.click();
  await expect.poll(() => treeRequests).toBe(2);
  await page.waitForTimeout(300);
  expect(treeRequests).toBe(2);
  await expect(retry).toBeVisible();
});

test("a zero-hit search still shows the truncation warning with its specific cause", async ({ page }) => {
  await page.route("**/api/search?*", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        query: "nonexistent-file",
        scope: "projects",
        results: [],
        truncated: true,
        truncation: {
          byResults: false,
          byNodes: true,
          byDepth: false,
          byReadError: false,
        },
        scanErrors: [],
        limits: {
          maxResults: 100,
          maxNodes: 5000,
          maxDepth: 20,
        },
      }),
    });
  });

  await page.goto("/");
  await page.getByRole("tab", { name: /Writing projects/ }).click();
  await page.locator("#treeSearch").fill("nonexistent-file");
  await expect(page.locator("#fileTree")).toContainText(
    "Search incomplete — cannot confirm whether the query exists",
  );
  await expect(page.locator("#fileTree")).toContainText(
    "Search hit the 5,000-node scan limit; deeper directories were not checked — expand the target directory directly",
  );
});

test("a zero-hit search with an unreadable directory shows permission or mount hints", async ({ page }) => {
  await page.route("**/api/search?*", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        query: "target-chapter",
        scope: "projects",
        results: [],
        truncated: true,
        truncation: {
          byResults: false,
          byNodes: false,
          byDepth: false,
          byReadError: true,
        },
        scanErrors: [{ path: "The-Shattered-Throne/prose/Restricted-Volume", code: "EACCES" }],
        limits: {
          maxResults: 100,
          maxNodes: 5000,
          maxDepth: 20,
        },
      }),
    });
  });

  await page.goto("/");
  await page.getByRole("tab", { name: /Writing projects/ }).click();
  await page.locator("#treeSearch").fill("target-chapter");
  await expect(page.locator("#fileTree")).toContainText(
    "Search incomplete — cannot confirm whether the query exists",
  );
  await expect(page.locator("#fileTree")).toContainText("The-Shattered-Throne/prose/Restricted-Volume could not be read");
  await expect(page.locator("#fileTree")).toContainText("Check directory permissions or external-drive mount state");
  await expect(page.locator("#fileTree")).not.toContainText("No results for the query");
});

test("wide directories load page by page; Load more appends without dropping the first page", async ({ page, request }) => {
  const workspace = await request.get("/api/workspace").then((response) => response.json());
  const project = resolve(workspace.workspace.path, workspace.projects[0].path);
  const volume = resolve(project, "Batch-Volume");

  try {
    await mkdir(volume, { recursive: true });
    for (let start = 0; start < 205; start += 100) {
      await Promise.all(
        Array.from({ length: Math.min(100, 205 - start) }, (_, offset) =>
          writeFile(
            resolve(volume, `chapter_${String(start + offset + 1).padStart(5, "0")}.md`),
            "filler",
            "utf8",
          ),
        ),
      );
    }

    await page.goto("/");
    await page.getByRole("tab", { name: /Writing projects/ }).click();
    await page.locator("summary").filter({ hasText: "Batch-Volume" }).click();
    const first = page.locator(
      `.file-row[data-path='${workspace.projects[0].path}/Batch-Volume/chapter_00001.md']`,
    );
    const last = page.locator(
      `.file-row[data-path='${workspace.projects[0].path}/Batch-Volume/chapter_00205.md']`,
    );
    await expect(first).toBeVisible();
    await expect(last).toHaveCount(0);
    await page.getByRole("button", { name: "Load more" }).click();
    await expect(first).toBeVisible();
    await expect(last).toBeVisible();
    await expect(page.getByRole("button", { name: "Load more" })).toHaveCount(0);
  } finally {
    await rm(volume, { recursive: true, force: true });
  }
});

test("@mobile viewport can still open an outline from the real long-form project", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByText("OH STORY", { exact: true })).toBeVisible();
  await expect(page.locator(".archive-panel")).toBeVisible();

  await page.getByRole("tab", { name: /Writing projects/ }).click();
  await expect(page.locator("#fileTree")).toContainText("The-Shattered-Throne");
  await page.locator("summary").filter({ hasText: "outline" }).click();
  await page
    .locator(".file-row[data-path='long-form/The-Shattered-Throne/outline/outline.md']")
    .click();

  await expect(page.locator("#editorTitle")).toHaveText("outline.md");
  await expect(page.locator("#editorWorkspace")).toBeVisible();
  await expect(page.locator("#saveButton")).toBeVisible();
  await expect(page.locator("#editorInput")).toBeVisible();

  if (page.viewportSize().width <= 720) {
    await expect(page.locator(".archive-panel")).toBeHidden();
    await page.locator("#mobileBackButton").click();
    await expect(page.locator(".archive-panel")).toBeVisible();
    await expect(page.locator(".editor-panel")).toBeHidden();
  }
});
