import { promises as fs } from "node:fs";
import path from "node:path";

// Keep per-call metadata so the after-hook can restore EOLs after apply_patch runs.
const patchState = new Map();

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

  return result.replace(/(?:\r\n|\n)$/, "");
}

export const PreserveApplyPatchLineEndings = async ({ worktree, directory }) => {
  // apply_patch paths are relative to the active worktree, not the config directory.
  const baseDir = worktree || directory || process.cwd();

  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "apply_patch") {
        return;
      }

      const entries = new Map();

      for (const operation of parsePatchTargets(output.args.patchText)) {
        // Only existing files have an EOL style to preserve.
        if (operation.type !== "update" || !operation.source || !operation.target) {
          continue;
        }

        const sourcePath = path.resolve(baseDir, operation.source);

        try {
          const content = await fs.readFile(sourcePath, "utf8");
          const lineEnding = detectLineEnding(content);

          if (!lineEnding) {
            continue;
          }

          // Store against the post-patch path so moves inherit the source file's style.
          entries.set(path.resolve(baseDir, operation.target), {
            path: path.resolve(baseDir, operation.target),
            lineEnding,
            finalNewline: hasFinalNewline(content),
          });
        } catch {
          // Ignore files that do not exist yet or are not readable.
        }
      }

      patchState.set(input.callID, [...entries.values()]);
    },

    "tool.execute.after": async (input) => {
      if (input.tool !== "apply_patch") {
        return;
      }

      const entries = patchState.get(input.callID) ?? [];
      patchState.delete(input.callID);

      for (const entry of entries) {
        try {
          const content = await fs.readFile(entry.path, "utf8");
          const restored = restoreLineEnding(content, entry.lineEnding, entry.finalNewline);

          // Skip unchanged files to avoid unnecessary rewrites.
          if (restored !== content) {
            await fs.writeFile(entry.path, restored, "utf8");
          }
        } catch {
          // Ignore files that were deleted by the patch.
        }
      }
    },
  };
};
