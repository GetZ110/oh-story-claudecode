import assert from "node:assert/strict";
import { chmod, mkdtemp, mkdir, readFile, rm, stat, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { resolve } from "node:path";
import { afterEach, describe, test } from "node:test";
import {
  DashboardError,
  browserLaunchCommand,
  createDashboardServer,
  listWorkspaceDirectory,
  pathsReferToSameFile,
  resolveWorkspaceDirectory,
  resolveWorkspacePath,
  scanWorkspace,
  searchWorkspace,
} from "../skills/story/scripts/dashboard-server.mjs";

const temporaryDirectories = [];
const runningServers = [];

afterEach(async () => {
  await Promise.all(
    runningServers.splice(0).map(
      (server) => new Promise((accept) => server.close(accept)),
    ),
  );
  await Promise.all(
    temporaryDirectories.splice(0).map((directory) =>
      rm(directory, { recursive: true, force: true }),
    ),
  );
});

async function createWorkspace() {
  const root = await mkdtemp(resolve(tmpdir(), "oh-story-dashboard-test-"));
  temporaryDirectories.push(root);
  await mkdir(resolve(root, "teardown-lib", "The-Last-Knight", "chapters"), { recursive: true });
  await mkdir(resolve(root, "long-form", "Sample-Book", "outline"), { recursive: true });
  await mkdir(resolve(root, "long-form", "Sample-Book", "prose"), { recursive: true });
  // Infrastructure directories must sit inside a scanned library/project: placed
  // at the workspace root they would never enter the tree, and the assertion
  // would be testing nothing.
  await mkdir(resolve(root, "long-form", "Sample-Book", ".git", "objects"), { recursive: true });
  await mkdir(resolve(root, "long-form", "Sample-Book", "prose", "node_modules", "fake-package"), {
    recursive: true,
  });
  await mkdir(resolve(root, "teardown-lib", "The-Last-Knight", ".omc", "state"), { recursive: true });
  await writeFile(
    resolve(root, "teardown-lib", "The-Last-Knight", "teardown-report.md"),
    "# The Last Knight\n",
    "utf8",
  );
  await writeFile(resolve(root, "teardown-lib", "The-Last-Knight", "chapters", "chapter_1.md"), "Chapter one", "utf8");
  await writeFile(resolve(root, "long-form", "Sample-Book", "outline", "outline.md"), "# Master Outline\n", "utf8");
  await writeFile(resolve(root, "long-form", "Sample-Book", "prose", "chapter_001.md"), "Draft", "utf8");
  await writeFile(resolve(root, "long-form", "Sample-Book", ".git", "config"), "secret", "utf8");
  await writeFile(
    resolve(root, "long-form", "Sample-Book", "prose", "node_modules", "fake-package", "index.js"),
    "x",
    "utf8",
  );
  await writeFile(resolve(root, "teardown-lib", "The-Last-Knight", ".omc", "state", "secrets.json"), "{}", "utf8");
  await writeFile(resolve(root, "long-form", "Sample-Book", "cover.png"), "not-an-image", "utf8");
  return root;
}

async function createProjectDiscoveryWorkspace() {
  const root = await mkdtemp(resolve(tmpdir(), "oh-story-dashboard-projects-"));
  temporaryDirectories.push(root);

  await mkdir(resolve(root, "long-form", "Standard-Long", "prose"), { recursive: true });
  await mkdir(resolve(root, "short-form", "Standard-Short"), { recursive: true });
  await writeFile(resolve(root, "short-form", "Standard-Short", "prose.md"), "Draft", "utf8");
  await writeFile(resolve(root, "short-form", "Standard-Short", "section-outline.md"), "Outline", "utf8");
  await writeFile(resolve(root, "short-form", "Standard-Short", "setting.md"), "Setting", "utf8");

  await mkdir(resolve(root, "Misc-Files"), { recursive: true });
  await writeFile(resolve(root, "Misc-Files", "prose.md"), "Not a short project", "utf8");

  await mkdir(resolve(root, "teardown-lib", "Fake-Project"), { recursive: true });
  await writeFile(resolve(root, "teardown-lib", "Fake-Project", "prose.md"), "Source text", "utf8");
  await writeFile(resolve(root, "teardown-lib", "Fake-Project", "setting.md"), "Source material", "utf8");

  return root;
}

// A directory with more than the 200-entry page size proves pagination; no need
// to create thousands of files to test the full-tree budget.
async function createOversizedWorkspace(fileCount = 205) {
  const root = await mkdtemp(resolve(tmpdir(), "oh-story-dashboard-oversized-"));
  temporaryDirectories.push(root);
  const body = resolve(root, "long-form", "Mega-Book", "prose");
  const library = resolve(root, "teardown-lib", "The-Last-Knight");
  await mkdir(resolve(root, "long-form", "Mega-Book", "outline"), { recursive: true });
  await mkdir(body, { recursive: true });
  await mkdir(resolve(library, "chapters"), { recursive: true });
  await writeFile(resolve(library, "teardown-report.md"), "# The Last Knight\n", "utf8");
  for (let start = 0; start < fileCount; start += 200) {
    await Promise.all(
      Array.from({ length: Math.min(200, fileCount - start) }, (_, offset) =>
        writeFile(
          resolve(body, `chapter_${String(start + offset + 1).padStart(5, "0")}.md`),
          "Draft",
          "utf8",
        ),
      ),
    );
  }
  return root;
}

async function createDeepSearchWorkspace() {
  const root = await mkdtemp(resolve(tmpdir(), "oh-story-dashboard-deep-search-"));
  temporaryDirectories.push(root);
  const deepRoot = resolve(root, "A-Deep-Project", "prose");
  const targetRoot = resolve(root, "B-Target-Project", "prose");
  await mkdir(
    resolve(deepRoot, ...Array.from({ length: 25 }, (_, index) => `level-${index + 1}`)),
    { recursive: true },
  );
  await mkdir(targetRoot, { recursive: true });
  await writeFile(resolve(targetRoot, "chapter_001.md"), "Target draft", "utf8");
  return root;
}

async function createSearchBudgetWorkspace(fileCount = 5005) {
  const root = await mkdtemp(resolve(tmpdir(), "oh-story-dashboard-search-budget-"));
  temporaryDirectories.push(root);
  const body = resolve(root, "Budget-Project", "prose");
  await mkdir(body, { recursive: true });
  for (let start = 0; start < fileCount; start += 250) {
    await Promise.all(
      Array.from({ length: Math.min(250, fileCount - start) }, (_, offset) =>
        writeFile(
          resolve(body, `note_${String(start + offset + 1).padStart(5, "0")}.md`),
          "Draft",
          "utf8",
        ),
      ),
    );
  }
  return root;
}

async function startServer(root) {
  const server = createDashboardServer({ root });
  await new Promise((accept, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", accept);
  });
  runningServers.push(server);
  const { port } = server.address();
  return `http://127.0.0.1:${port}`;
}

describe("workspace scanning", () => {
  test("recognizes standard long and short projects without treating loose files or libraries as projects", async () => {
    const root = await createProjectDiscoveryWorkspace();
    const workspace = await scanWorkspace(root);

    assert.deepEqual(
      workspace.projects.map((entry) => entry.path),
      ["long-form/Standard-Long", "short-form/Standard-Short"],
    );
    assert.deepEqual(workspace.libraries.map((entry) => entry.path), ["teardown-lib/Fake-Project"]);
    assert.ok(!workspace.projects.some((entry) => entry.path === "Misc-Files"));
    assert.ok(!workspace.projects.some((entry) => entry.path.startsWith("teardown-lib/")));
  });

  test("does not use symlinked short-story marker files", async (context) => {
    const root = await createProjectDiscoveryWorkspace();
    const candidate = resolve(root, "short-form", "Symlink-Marker");
    await mkdir(candidate, { recursive: true });
    await writeFile(resolve(candidate, "setting.md"), "Setting", "utf8");
    try {
      await symlink(resolve(root, "short-form", "Standard-Short", "prose.md"), resolve(candidate, "prose.md"));
    } catch (error) {
      if (error?.code === "EPERM") {
        context.skip("this platform does not allow creating test symlinks");
        return;
      }
      throw error;
    }

    const workspace = await scanWorkspace(root);
    assert.ok(!workspace.projects.some((entry) => entry.path === "short-form/Symlink-Marker"));
  });

  test("uses a stable dot path when the workspace itself is a short-story project", async () => {
    const root = await mkdtemp(resolve(tmpdir(), "oh-story-dashboard-root-project-"));
    temporaryDirectories.push(root);
    await writeFile(resolve(root, "prose.md"), "Draft", "utf8");
    await writeFile(resolve(root, "section-outline.md"), "Outline", "utf8");
    await writeFile(resolve(root, "setting.md"), "Setting", "utf8");

    const workspace = await scanWorkspace(root);
    assert.deepEqual(workspace.projects.map((entry) => entry.path), ["."]);
    const page = await listWorkspaceDirectory(root, ".");
    assert.equal(page.path, ".");
    assert.deepEqual(
      page.entries.map((entry) => entry.name),
      ["prose.md", "section-outline.md", "setting.md"],
    );
  });

  test("discovers roots without recursively serializing every manuscript", async () => {
    const workspace = await scanWorkspace(resolve("demo"));
    assert.deepEqual(
      workspace.libraries.map((entry) => entry.path),
      ["teardown-lib/The-Last-Knight", "teardown-lib/The-Secret-Keeper"],
    );
    assert.deepEqual(
      workspace.projects.map((entry) => entry.path),
      ["long-form/The-Shattered-Throne"],
    );
    assert.equal(workspace.stats.libraries, 2);
    assert.equal(workspace.stats.projects, 1);
    assert.equal(workspace.stats.editableFiles, null);
    assert.equal(workspace.stats.onDemand, true);
    assert.ok(workspace.libraries.every((entry) => entry.loaded === false));
    assert.ok(workspace.projects.every((entry) => entry.children.length === 0));
    assert.doesNotMatch(JSON.stringify(workspace), /A-Last-Candle/);
    assert.equal(workspace.limits.truncated, false);
    assert.equal(workspace.limits.directoryPageSize, 200);
  });

  test("loads only one directory level and keeps infrastructure folders hidden", async () => {
    const root = await createWorkspace();
    const page = await listWorkspaceDirectory(root, "long-form/Sample-Book");
    assert.doesNotMatch(JSON.stringify(page), /\.git/);
    assert.doesNotMatch(JSON.stringify(page), /chapter_001\.md/);
    assert.deepEqual(
      page.entries.filter((entry) => entry.type === "directory").map((entry) => entry.name),
      ["outline", "prose"],
    );
    const cover = page.entries.find((entry) => entry.name === "cover.png");
    assert.equal(cover.editable, false);
    assert.equal(page.nextCursor, null);

    const bodyPage = await listWorkspaceDirectory(root, "long-form/Sample-Book/prose");
    assert.deepEqual(bodyPage.entries.map((entry) => entry.name), ["chapter_001.md"]);
    assert.doesNotMatch(JSON.stringify(bodyPage), /node_modules|fake-package/);

    const libraryPage = await listWorkspaceDirectory(root, "teardown-lib/The-Last-Knight");
    assert.deepEqual(
      libraryPage.entries.map((entry) => entry.name),
      ["chapters", "teardown-report.md"],
    );
    assert.doesNotMatch(JSON.stringify(libraryPage), /\.omc|secrets\.json/);
  });

  test("paginates a wide directory without dropping or duplicating files", async () => {
    const root = await createOversizedWorkspace();
    const path = "long-form/Mega-Book/prose";
    const first = await listWorkspaceDirectory(root, path);
    const second = await listWorkspaceDirectory(root, path, first.nextCursor);
    assert.equal(first.entries.length, 200);
    assert.equal(first.nextCursor, "200");
    assert.equal(second.entries.length, 5);
    assert.equal(second.nextCursor, null);
    assert.equal(new Set([...first.entries, ...second.entries].map((entry) => entry.path)).size, 205);
  });

  test("searches unloaded descendants on demand and respects the active collection", async () => {
    const root = await createWorkspace();
    const projects = await searchWorkspace(root, "chapter_001", "projects");
    assert.deepEqual(projects.results.map((entry) => entry.path), [
      "long-form/Sample-Book/prose/chapter_001.md",
    ]);
    const libraries = await searchWorkspace(root, "chapter_1", "libraries");
    assert.deepEqual(libraries.results.map((entry) => entry.path), [
      "teardown-lib/The-Last-Knight/chapters/chapter_1.md",
    ]);
    assert.equal(projects.truncated, false);
    const pathOnly = await searchWorkspace(root, "Sample-Book", "projects");
    assert.deepEqual(pathOnly.results, []);
  });

  test("continues searching later projects after one subtree exceeds the depth limit", async () => {
    const root = await createDeepSearchWorkspace();
    const result = await searchWorkspace(root, "chapter_001", "projects");
    assert.deepEqual(result.results.map((entry) => entry.path), [
      "B-Target-Project/prose/chapter_001.md",
    ]);
    assert.equal(result.truncated, true);
    assert.deepEqual(result.truncation, {
      byResults: false,
      byNodes: false,
      byDepth: true,
      byReadError: false,
    });
  });

  test("reports result-limit and node-budget truncation independently", async () => {
    const resultRoot = await createOversizedWorkspace(205);
    const byResults = await searchWorkspace(resultRoot, "chapter", "projects");
    assert.equal(byResults.results.length, 100);
    assert.deepEqual(byResults.truncation, {
      byResults: true,
      byNodes: false,
      byDepth: false,
      byReadError: false,
    });

    const budgetRoot = await createSearchBudgetWorkspace();
    const byNodes = await searchWorkspace(budgetRoot, "nonexistent-file-name", "projects");
    assert.deepEqual(byNodes.results, []);
    assert.deepEqual(byNodes.truncation, {
      byResults: false,
      byNodes: true,
      byDepth: false,
      byReadError: false,
    });
  });

  test("marks search results incomplete when an unloaded descendant is unreadable", async (context) => {
    if (process.platform === "win32" || process.getuid?.() === 0) {
      context.skip("this platform or user cannot create an unreadable directory");
      return;
    }
    const root = await createWorkspace();
    const restricted = resolve(root, "long-form", "Sample-Book", "prose", "Restricted-Volume");
    await mkdir(restricted, { recursive: true });
    await writeFile(resolve(restricted, "target-chapter.md"), "Unreadable draft", "utf8");
    await chmod(restricted, 0o000);
    try {
      const baseUrl = await startServer(root);
      const response = await fetch(
        `${baseUrl}/api/search?q=${encodeURIComponent("target-chapter")}&scope=projects`,
      );
      assert.equal(response.status, 200);
      const result = await response.json();
      assert.deepEqual(result.results, []);
      assert.equal(result.truncated, true);
      assert.deepEqual(result.truncation, {
        byResults: false,
        byNodes: false,
        byDepth: false,
        byReadError: true,
      });
      assert.deepEqual(
        result.scanErrors.map(({ path, code }) => ({ path, code })),
        [{ path: "long-form/Sample-Book/prose/Restricted-Volume", code: "EACCES" }],
      );
    } finally {
      await chmod(restricted, 0o755);
    }
  });
});

describe("path boundary", () => {
  test("rejects traversal and absolute paths", async () => {
    const root = await createWorkspace();
    await assert.rejects(
      resolveWorkspacePath(root, "../outside.md"),
      (error) => error instanceof DashboardError && error.code === "path_outside_workspace",
    );
    await assert.rejects(
      resolveWorkspacePath(root, "/etc/hosts"),
      (error) => error instanceof DashboardError && error.code === "path_outside_workspace",
    );
    await assert.rejects(
      resolveWorkspaceDirectory(root, "../outside"),
      (error) => error instanceof DashboardError && error.code === "path_outside_workspace",
    );
  });

  test("does not follow file symlinks", async (context) => {
    const root = await createWorkspace();
    const outside = resolve(root, "..", `outside-${Date.now()}.md`);
    await writeFile(outside, "outside", "utf8");
    temporaryDirectories.push(outside);
    try {
      await symlink(outside, resolve(root, "escape.md"));
    } catch (error) {
      if (error?.code === "EPERM") {
        context.skip("this platform does not allow creating test symlinks");
        return;
      }
      throw error;
    }
    await assert.rejects(
      resolveWorkspacePath(root, "escape.md", { editableOnly: true }),
      (error) => error instanceof DashboardError && error.code === "symlink_not_editable",
    );
  });
});

describe("CLI portability", () => {
  test("uses each operating system's default-browser command", () => {
    const url = "http://127.0.0.1:43110";
    assert.deepEqual(browserLaunchCommand(url, "darwin"), {
      command: "open",
      args: [url],
    });
    assert.deepEqual(browserLaunchCommand(url, "linux"), {
      command: "xdg-open",
      args: [url],
    });
    assert.deepEqual(browserLaunchCommand(url, "win32"), {
      command: "cmd",
      args: ["/c", "start", "", url],
    });
  });

  test("recognizes the CLI entrypoint through a symlinked install path", async (context) => {
    const root = await createWorkspace();
    const alias = `${root}-alias`;
    temporaryDirectories.push(alias);
    try {
      await symlink(root, alias, process.platform === "win32" ? "junction" : "dir");
    } catch (error) {
      if (error?.code === "EPERM") {
        context.skip("this platform does not allow creating test directory links");
        return;
      }
      throw error;
    }

    assert.equal(
      pathsReferToSameFile(
        resolve(root, "long-form", "Sample-Book", "prose", "chapter_001.md"),
        resolve(alias, "long-form", "Sample-Book", "prose", "chapter_001.md"),
      ),
      true,
    );
  });
});

describe("HTTP API", () => {
  test("serves lazy roots, directory pages, and on-demand search", async () => {
    const root = await createWorkspace();
    const baseUrl = await startServer(root);

    const workspace = await fetch(`${baseUrl}/api/workspace`).then((response) => response.json());
    assert.deepEqual(workspace.projects[0].children, []);
    assert.doesNotMatch(JSON.stringify(workspace), /chapter_001\.md/);

    const tree = await fetch(
      `${baseUrl}/api/tree?path=${encodeURIComponent("long-form/Sample-Book")}`,
    ).then((response) => response.json());
    assert.deepEqual(
      tree.entries.filter((entry) => entry.type === "directory").map((entry) => entry.name),
      ["outline", "prose"],
    );

    const search = await fetch(
      `${baseUrl}/api/search?q=${encodeURIComponent("chapter_001")}&scope=projects`,
    ).then((response) => response.json());
    assert.deepEqual(search.results.map((entry) => entry.path), [
      "long-form/Sample-Book/prose/chapter_001.md",
    ]);

    const traversal = await fetch(
      `${baseUrl}/api/tree?path=${encodeURIComponent("../outside")}`,
    );
    assert.equal(traversal.status, 403);
    const invalidCursor = await fetch(
      `${baseUrl}/api/tree?path=${encodeURIComponent("long-form/Sample-Book")}&cursor=next`,
    );
    assert.equal(invalidCursor.status, 400);
    const hiddenDirectory = await fetch(
      `${baseUrl}/api/tree?path=${encodeURIComponent("long-form/Sample-Book/.git")}`,
    );
    assert.equal(hiddenDirectory.status, 403);
  });

  test("loads and atomically saves an editable file", async () => {
    const root = await createWorkspace();
    const baseUrl = await startServer(root);
    const filePath = "long-form/Sample-Book/prose/chapter_001.md";

    const loadedResponse = await fetch(
      `${baseUrl}/api/file?path=${encodeURIComponent(filePath)}`,
    );
    assert.equal(loadedResponse.status, 200);
    assert.match(loadedResponse.headers.get("content-security-policy"), /default-src 'self'/);
    const loaded = await loadedResponse.json();
    assert.equal(loaded.content, "Draft");

    const savedResponse = await fetch(`${baseUrl}/api/file`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        path: filePath,
        content: "Edited draft",
        expectedVersion: loaded.version,
      }),
    });
    assert.equal(savedResponse.status, 200);
    const saved = await savedResponse.json();
    assert.equal(saved.ok, true);
    assert.equal(await readFile(resolve(root, filePath), "utf8"), "Edited draft");
  });

  test("returns 409 instead of overwriting an externally changed file", async () => {
    const root = await createWorkspace();
    const baseUrl = await startServer(root);
    const filePath = "long-form/Sample-Book/prose/chapter_001.md";
    const loaded = await fetch(
      `${baseUrl}/api/file?path=${encodeURIComponent(filePath)}`,
    ).then((response) => response.json());

    await new Promise((accept) => setTimeout(accept, 20));
    await writeFile(resolve(root, filePath), "External program's new content", "utf8");

    const response = await fetch(`${baseUrl}/api/file`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        path: filePath,
        content: "Dashboard stale content",
        expectedVersion: loaded.version,
      }),
    });
    assert.equal(response.status, 409);
    const payload = await response.json();
    assert.equal(payload.error.code, "file_changed");
    assert.equal(await readFile(resolve(root, filePath), "utf8"), "External program's new content");
  });

  test("deletes an unchanged editable file but rejects cross-origin deletion", async () => {
    const root = await createWorkspace();
    const baseUrl = await startServer(root);
    const filePath = "long-form/Sample-Book/prose/chapter_001.md";
    const loaded = await fetch(
      `${baseUrl}/api/file?path=${encodeURIComponent(filePath)}`,
    ).then((response) => response.json());

    const rejected = await fetch(`${baseUrl}/api/file`, {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        Origin: "https://example.com",
      },
      body: JSON.stringify({
        path: filePath,
        expectedVersion: loaded.version,
      }),
    });
    assert.equal(rejected.status, 403);
    assert.equal((await rejected.json()).error.code, "invalid_origin");
    assert.equal(await readFile(resolve(root, filePath), "utf8"), "Draft");

    const deletedResponse = await fetch(`${baseUrl}/api/file`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        path: filePath,
        expectedVersion: loaded.version,
      }),
    });
    assert.equal(deletedResponse.status, 200);
    const deleted = await deletedResponse.json();
    assert.deepEqual(deleted, { ok: true, path: filePath });
    await assert.rejects(
      readFile(resolve(root, filePath), "utf8"),
      (error) => error?.code === "ENOENT",
    );
  });

  test("does not delete a file changed after it was opened", async () => {
    const root = await createWorkspace();
    const baseUrl = await startServer(root);
    const filePath = "long-form/Sample-Book/prose/chapter_001.md";
    const loaded = await fetch(
      `${baseUrl}/api/file?path=${encodeURIComponent(filePath)}`,
    ).then((response) => response.json());

    await new Promise((accept) => setTimeout(accept, 20));
    await writeFile(resolve(root, filePath), "External program's new content", "utf8");

    const response = await fetch(`${baseUrl}/api/file`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        path: filePath,
        expectedVersion: loaded.version,
      }),
    });
    assert.equal(response.status, 409);
    assert.equal((await response.json()).error.code, "file_changed");
    assert.equal(await readFile(resolve(root, filePath), "utf8"), "External program's new content");
  });

  test("accepts only one of several simultaneous saves based on the same version", async () => {
    const root = await createWorkspace();
    const baseUrl = await startServer(root);
    const filePath = "long-form/Sample-Book/prose/chapter_001.md";
    const loaded = await fetch(
      `${baseUrl}/api/file?path=${encodeURIComponent(filePath)}`,
    ).then((response) => response.json());

    const responses = await Promise.all(
      Array.from({ length: 8 }, (_, index) =>
        fetch(`${baseUrl}/api/file`, {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            path: filePath,
            content: `concurrent-write-${index}`,
            expectedVersion: loaded.version,
          }),
        }),
      ),
    );
    const statuses = responses.map((response) => response.status);
    assert.equal(statuses.filter((status) => status === 200).length, 1, statuses);
    assert.equal(statuses.filter((status) => status === 409).length, 7, statuses);
    assert.match(await readFile(resolve(root, filePath), "utf8"), /^concurrent-write-[0-7]$/);
  });

  test("serializes simultaneous save and delete operations on the same version", async () => {
    const root = await createWorkspace();
    const baseUrl = await startServer(root);
    const filePath = "long-form/Sample-Book/prose/chapter_001.md";
    const loaded = await fetch(
      `${baseUrl}/api/file?path=${encodeURIComponent(filePath)}`,
    ).then((response) => response.json());
    const versionedPath = { path: filePath, expectedVersion: loaded.version };

    const [saved, deleted] = await Promise.all([
      fetch(`${baseUrl}/api/file`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...versionedPath, content: "Content when save wins" }),
      }),
      fetch(`${baseUrl}/api/file`, {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(versionedPath),
      }),
    ]);
    assert.deepEqual([saved.status, deleted.status].sort(), [200, 409]);
    if (saved.status === 200) {
      assert.equal(await readFile(resolve(root, filePath), "utf8"), "Content when save wins");
    } else {
      await assert.rejects(
        readFile(resolve(root, filePath), "utf8"),
        (error) => error?.code === "ENOENT",
      );
    }
  });

  test("rejects unsupported files, traversal, and malformed JSON", async () => {
    const root = await createWorkspace();
    const baseUrl = await startServer(root);

    const unsupported = await fetch(
      `${baseUrl}/api/file?path=${encodeURIComponent("long-form/Sample-Book/cover.png")}`,
    );
    assert.equal(unsupported.status, 415);

    const traversal = await fetch(
      `${baseUrl}/api/file?path=${encodeURIComponent("../outside.md")}`,
    );
    assert.equal(traversal.status, 403);

    const malformed = await fetch(`${baseUrl}/api/file`, {
      method: "PUT",
      body: "{bad",
    });
    assert.equal(malformed.status, 400);
    assert.equal((await malformed.json()).error.code, "invalid_json");

    const versionless = await fetch(`${baseUrl}/api/file`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        path: "long-form/Sample-Book/prose/chapter_001.md",
        content: "no-version-overwrite",
      }),
    });
    assert.equal(versionless.status, 400);
    assert.equal((await versionless.json()).error.code, "missing_file_version");

    // Deletes must also carry a version: the 409 comparison cannot catch a
    // missing one (NaN > 0.5 is always false), and without this assertion the
    // guard could be removed and chapters deleted without any version check.
    const chapterPath = "long-form/Sample-Book/prose/chapter_001.md";
    const versionlessDelete = await fetch(`${baseUrl}/api/file`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ path: chapterPath }),
    });
    assert.equal(versionlessDelete.status, 400);
    assert.equal((await versionlessDelete.json()).error.code, "missing_file_version");
    assert.equal(await readFile(resolve(root, chapterPath), "utf8"), "Draft");
  });

  test("keeps the saved file's permission bits instead of letting umask narrow them", async (context) => {
    if (process.platform === "win32") {
      context.skip("Windows does not use POSIX permission bits");
      return;
    }
    const root = await createWorkspace();
    const baseUrl = await startServer(root);
    const filePath = "long-form/Sample-Book/prose/chapter_001.md";
    const absolutePath = resolve(root, filePath);
    await chmod(absolutePath, 0o664);

    const previousUmask = process.umask(0o022);
    try {
      const loaded = await fetch(
        `${baseUrl}/api/file?path=${encodeURIComponent(filePath)}`,
      ).then((response) => response.json());
      const saved = await fetch(`${baseUrl}/api/file`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          path: filePath,
          content: "Edited content",
          expectedVersion: loaded.version,
        }),
      });
      assert.equal(saved.status, 200);
      assert.equal((await stat(absolutePath)).mode & 0o777, 0o664);
    } finally {
      process.umask(previousUmask);
    }
  });

  test("still serves the rest of the workspace when one library directory is unreadable", async (context) => {
    if (process.platform === "win32" || process.getuid?.() === 0) {
      context.skip("this platform or user cannot create an unreadable directory");
      return;
    }
    const root = await createWorkspace();
    const baseUrl = await startServer(root);
    const libraryRoot = resolve(root, "teardown-lib");
    await chmod(libraryRoot, 0o000);
    try {
      const response = await fetch(`${baseUrl}/api/workspace`);
      assert.equal(response.status, 200);
      const payload = await response.json();
      assert.deepEqual(payload.libraries, []);
      assert.equal(payload.limits.truncated, true);
      assert.equal(payload.limits.truncatedByReadError, true);
      assert.deepEqual(
        payload.scanErrors.map(({ path, code }) => ({ path, code })),
        [{ path: "teardown-lib", code: "EACCES" }],
      );
      assert.deepEqual(
        payload.projects.map((entry) => entry.path),
        ["long-form/Sample-Book"],
      );
    } finally {
      await chmod(libraryRoot, 0o755);
    }
  });

  test("reports an actionable error when the workspace root itself is unreadable", async (context) => {
    if (process.platform === "win32" || process.getuid?.() === 0) {
      context.skip("this platform or user cannot create an unreadable directory");
      return;
    }
    const root = await createWorkspace();
    const baseUrl = await startServer(root);
    await chmod(root, 0o000);
    try {
      const response = await fetch(`${baseUrl}/api/workspace`);
      assert.equal(response.status, 403);
      const payload = await response.json();
      assert.equal(payload.error.code, "workspace_unreadable");
      assert.match(payload.error.message, /Cannot read the workspace directory/);
    } finally {
      await chmod(root, 0o755);
    }
  });
});
