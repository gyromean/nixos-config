import assert from "node:assert/strict";
import { mkdtemp, mkdir, readFile, writeFile, rm } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { test } from "node:test";

// Load the dependency-free ES module even on Node versions that treat .js as CJS.
const source = await readFile(new URL("../plugins/preserve-patch-eol/index.js", import.meta.url), "utf8");
const { default: plugin } = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`);

async function fixture(t) {
  const root = await mkdtemp(path.join(os.tmpdir(), "opencode-eol-"));
  const directory = path.join(root, "subdir");
  await mkdir(directory);
  t.after(() => rm(root, { recursive: true, force: true }));
  const hooks = {};
  const cleanup = await plugin.setup({
    location: { directory: root },
    session: { get: async () => ({ location: { directory } }) },
    tool: { hook: async (name, callback) => { hooks[name] = callback; } },
  });
  return {
    directory,
    cleanup,
    before: (patchText, id = "call", sessionID = "session") => hooks["execute.before"]({
      tool: "patch", id, sessionID, input: { patchText },
    }),
    after: (status = "completed", id = "call", sessionID = "session") => hooks["execute.after"]({
      tool: "patch", id, sessionID, status,
    }),
  };
}

const patch = (name, move) => `*** Begin Patch\n*** Update File: ${name}\n${move ? `*** Move to: ${move}\n` : ""}@@\n-old\n+new\n*** End Patch`;

for (const [label, original, written, expected] of [
  ["CRLF", "old\r\nkeep\r\n", "new\nkeep\r\n", "new\r\nkeep\r\n"],
  ["LF", "old\nkeep\n", "new\nkeep\n", "new\nkeep\n"],
  ["CRLF without final newline", "old\r\nkeep", "new\nkeep\n", "new\r\nkeep"],
  ["single line without final newline", "old", "new\n", "new"],
  ["empty file", "", "new\n", "new"],
]) {
  test(`restores ${label} using the session directory`, async (t) => {
    const f = await fixture(t);
    const file = path.join(f.directory, "file.txt");
    await writeFile(file, original);
    await f.before(patch("file.txt"));
    // Simulate the bytes written by the upstream patch executor.
    await writeFile(file, written);
    await f.after();
    assert.deepEqual(await readFile(file), Buffer.from(expected));
  });
}

test("restores multiple files and a moved file after partial failure; clears state", async (t) => {
  const f = await fixture(t);
  const old = path.join(f.directory, "old.txt");
  const moved = path.join(f.directory, "moved.txt");
  const second = path.join(f.directory, "second.txt");
  await writeFile(old, "old\r\n");
  await writeFile(second, "old");
  await f.before(patch("old.txt", "moved.txt").replace("*** End Patch", "*** Update File: second.txt\n@@\n-old\n+new\n*** End Patch"));
  await rm(old);
  await writeFile(moved, "new\n");
  await writeFile(second, "new\n");
  await f.after("error");
  assert.deepEqual(await readFile(moved), Buffer.from("new\r\n"));
  assert.deepEqual(await readFile(second), Buffer.from("new"));
  await writeFile(moved, "later\n");
  await f.after("error");
  assert.equal(await readFile(moved, "utf8"), "later\n");
});

test("failed validation leaves untouched mixed-EOL files alone", async (t) => {
  const f = await fixture(t);
  const file = path.join(f.directory, "file.txt");
  const original = "old\r\nkeep\n";
  await writeFile(file, original);
  await f.before(patch("file.txt"));
  await f.after("error");
  assert.equal(await readFile(file, "utf8"), original);
});

test("a rejected move does not rewrite an existing destination", async (t) => {
  const f = await fixture(t);
  const destination = path.join(f.directory, "destination.txt");
  const original = "unrelated\ntext\r\n";
  await writeFile(path.join(f.directory, "source.txt"), "old\r\n");
  await writeFile(destination, original);
  await f.before(patch("source.txt", "destination.txt"));
  await f.after("error");
  assert.equal(await readFile(destination, "utf8"), original);
});

test("same call IDs in different sessions stay isolated; cleanup drops pending state", async (t) => {
  const f = await fixture(t);
  const first = path.join(f.directory, "first.txt");
  const second = path.join(f.directory, "second.txt");
  await writeFile(first, "old\r\n");
  await writeFile(second, "old");
  await f.before(patch("first.txt"), "same", "one");
  await f.before(patch("second.txt"), "same", "two");
  await writeFile(first, "new\n");
  await writeFile(second, "new\n");
  await f.after("completed", "same", "one");
  assert.equal(await readFile(first, "utf8"), "new\r\n");
  await f.after("completed", "same", "two");
  assert.equal(await readFile(second, "utf8"), "new");
  await f.before(patch("first.txt"));
  f.cleanup();
  await writeFile(first, "later\n");
  await f.after();
  assert.equal(await readFile(first, "utf8"), "later\n");
});
