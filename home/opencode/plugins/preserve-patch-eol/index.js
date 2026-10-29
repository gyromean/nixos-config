import { promises as fs } from "node:fs";
import path from "node:path";

function parsePatchTargets(patchText) {
  const operations = [];
  let current = null;

  for (const line of patchText.split(/\r?\n/)) {
    if (line.startsWith("*** Update File: ")) {
      const file = line.slice("*** Update File: ".length).trim();
      current = { type: "update", source: file, target: file };
      operations.push(current);
      continue;
    }

    if (line.startsWith("*** Add File: ")) {
      const file = line.slice("*** Add File: ".length).trim();
      current = { type: "add", source: null, target: file };
      operations.push(current);
      continue;
    }

    if (line.startsWith("*** Delete File: ")) {
      const file = line.slice("*** Delete File: ".length).trim();
      current = { type: "delete", source: file, target: null };
      operations.push(current);
      continue;
    }

    if (line.startsWith("*** Move to: ") && current?.type === "update") {
      current.target = line.slice("*** Move to: ".length).trim();
    }
  }

  return operations;
}

function detectLineEnding(text) {
  const crlfMatches = text.match(/\r\n/g)?.length ?? 0;
  const lfMatches = text.replace(/\r\n/g, "").match(/\n/g)?.length ?? 0;

  if (crlfMatches === 0 && lfMatches === 0) {
    return null;
  }

  // Mixed files are normalized to their dominant style after patching.
  return crlfMatches >= lfMatches ? "crlf" : "lf";
}

function hasFinalNewline(text) {
  return /\r?\n$/.test(text);
}

function restoreLineEnding(text, style, finalNewline) {
  const newline = style === "crlf" ? "\r\n" : "\n";

  // Normalize first so we can re-emit the file in a single consistent style.
  let result = text.replace(/\r\n/g, "\n").replace(/\r/g, "\n");

  if (style === "crlf") {
    result = result.replace(/\n/g, "\r\n");
  }

  if (finalNewline) {
    if (result.length > 0 && !result.endsWith(newline)) {
      result += newline;
    }
    return result;
  }

  return result.endsWith(newline) ? result.slice(0, -newline.length) : result;
}

// V2 plugin definition (Plugin.define is an identity helper). No SDK dependency
// is needed at runtime: this plugin only uses Node's built-in filesystem API.
export default {
  id: "local.preserve-patch-eol",
  async setup(ctx) {
    const patchState = new Map();
    const key = (event) => JSON.stringify([event.sessionID, event.id]);

    await ctx.tool.hook("execute.before", async (event) => {
      if (event.tool !== "patch") {
        return;
      }

      patchState.delete(key(event));
      if (typeof event.input?.patchText !== "string") {
        return;
      }
      const session = await ctx.session.get({ sessionID: event.sessionID });
      // Match patch's active Location, including sessions moved to a new folder.
      const baseDir = session.location.directory;
      const entries = new Map();

      for (const operation of parsePatchTargets(event.input.patchText)) {
        // Only existing files have an EOL style to preserve.
        if (operation.type !== "update" || !operation.source || !operation.target) {
          continue;
        }

        const sourcePath = path.resolve(baseDir, operation.source);

        try {
          const content = await fs.readFile(sourcePath, "utf8");
          // A one-line file still needs its missing final newline preserved.
          const lineEnding = detectLineEnding(content) ?? "lf";
          const targetPath = path.resolve(baseDir, operation.target);
          let previousTarget = content;
          if (targetPath !== sourcePath) {
            try {
              previousTarget = await fs.readFile(targetPath, "utf8");
            } catch (error) {
              if (error.code !== "ENOENT") throw error;
              previousTarget = null;
            }
          }

          // Store against the post-patch path so moves inherit the source file's style.
          entries.set(targetPath, {
            path: targetPath,
            lineEnding,
            finalNewline: hasFinalNewline(content),
            previousTarget,
          });
        } catch (error) {
          if (error.code !== "ENOENT") throw error;
        }
      }

      patchState.set(key(event), [...entries.values()]);
    });

    await ctx.tool.hook("execute.after", async (event) => {
      if (event.tool !== "patch") {
        return;
      }

      const entries = patchState.get(key(event)) ?? [];
      // Clear even when restoration fails; after also runs on tool errors.
      patchState.delete(key(event));

      for (const entry of entries) {
        try {
          const content = await fs.readFile(entry.path, "utf8");
          // Failed validation/permission checks must not normalize untouched files.
          if (content === entry.previousTarget) continue;
          const restored = restoreLineEnding(content, entry.lineEnding, entry.finalNewline);

          // Skip unchanged files to avoid unnecessary rewrites.
          if (restored !== content) {
            await fs.writeFile(entry.path, restored, "utf8");
          }
        } catch (error) {
          // A failed patch may already have written some files. Restore those
          // too, and report real I/O failures rather than silently losing EOLs.
          if (error.code !== "ENOENT") {
            console.error(`[preserve-patch-eol] ${entry.path}:`, error);
          }
        }
      }
    });

    return () => patchState.clear();
  },
};
