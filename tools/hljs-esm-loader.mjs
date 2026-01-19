import fs from "fs/promises";
import path from "path";
import { fileURLToPath, pathToFileURL } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");
const hljsSrcRoot = path.join(repoRoot, "highlight.js", "src") + path.sep;
const hljsSrcUrl = pathToFileURL(hljsSrcRoot).href;

export async function load(url, context, defaultLoad) {
  if (url.startsWith(hljsSrcUrl) && url.endsWith(".js")) {
    const source = await fs.readFile(fileURLToPath(url), "utf8");
    return { format: "module", source, shortCircuit: true };
  }
  return defaultLoad(url, context, defaultLoad);
}

export async function resolve(specifier, context, defaultResolve) {
  const parentURL = context.parentURL || "";
  if (parentURL.startsWith(hljsSrcUrl) && specifier.startsWith(".")) {
    if (!specifier.endsWith(".js") && !specifier.endsWith(".mjs") && !specifier.endsWith(".json")) {
      try {
        return await defaultResolve(specifier + ".js", context, defaultResolve);
      } catch {
        // fall through
      }
    }
  }
  return defaultResolve(specifier, context, defaultResolve);
}
