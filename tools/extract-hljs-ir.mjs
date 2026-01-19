#!/usr/bin/env node
import fs from "fs/promises";
import path from "path";
import { fileURLToPath, pathToFileURL } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");
const modesPath = path.join(repoRoot, "highlight.js", "src", "lib", "modes.js");
const regexPath = path.join(repoRoot, "highlight.js", "src", "lib", "regex.js");
const utilsPath = path.join(repoRoot, "highlight.js", "src", "lib", "utils.js");

const modes = await import(pathToFileURL(modesPath).href);
const regex = await import(pathToFileURL(regexPath).href);
const utils = await import(pathToFileURL(utilsPath).href);

const hljs = {
  ...modes,
  regex,
  inherit: utils.inherit
};

const args = process.argv.slice(2);
const langs = [];
let all = false;

for (let i = 0; i < args.length; i++) {
  if (args[i] === "--all") {
    all = true;
  } else if (args[i] === "--lang" && args[i + 1]) {
    langs.push(args[i + 1]);
    i += 1;
  }
}

const languagesDir = path.join(repoRoot, "highlight.js", "src", "languages");
const outputDir = path.join(repoRoot, "tools", "ir");

const languageFiles = all
  ? (await fs.readdir(languagesDir)).filter((f) => f.endsWith(".js"))
  : langs.map((l) => `${l}.js`);

function normalizeKeywordList(value) {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  if (typeof value === "string") {
    return value.split(/\s+/).filter(Boolean);
  }
  return [];
}

function serializePattern(value) {
  if (!value) return null;
  if (value instanceof RegExp) {
    return { type: "regex", source: value.source, flags: value.flags || "" };
  }
  if (typeof value === "string") {
    return { type: "string", source: value };
  }
  return null;
}

function serializeSequence(value) {
  if (Array.isArray(value)) {
    const source = regex._rewriteBackreferences(value, { joinWith: "" });
    return { type: "regex", source, flags: "" };
  }
  return serializePattern(value);
}

function serializeEither(value) {
  if (Array.isArray(value)) {
    const source = regex.either(...value);
    return { type: "regex", source, flags: "" };
  }
  return serializePattern(value);
}

function serializeKeywords(value) {
  if (!value) return null;
  if (typeof value === "string") {
    return {
      pattern: null,
      keyword: [],
      literal: [],
      built_in: [],
      type: [],
      custom: {},
      raw: value
    };
  }

  const pattern = value.$pattern ? serializePattern(value.$pattern) : null;
  const custom = {};
  for (const [key, entry] of Object.entries(value)) {
    if (key === "$pattern" || key === "keyword" || key === "literal" || key === "built_in" || key === "type") {
      continue;
    }
    const list = normalizeKeywordList(entry);
    if (list.length) {
      custom[key] = list;
    }
  }
  return {
    pattern,
    keyword: normalizeKeywordList(value.keyword),
    literal: normalizeKeywordList(value.literal),
    built_in: normalizeKeywordList(value.built_in),
    type: normalizeKeywordList(value.type),
    custom,
    raw: null
  };
}

function serializeScope(value) {
  if (!value) return null;
  if (typeof value === "string") return value;
  if (typeof value === "object" && !Array.isArray(value)) {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      out[String(k)] = v;
    }
    return out;
  }
  return null;
}

function remapScope(scope, regexes) {
  if (!scope || typeof scope !== "object" || Array.isArray(scope)) return scope;
  if (!Array.isArray(regexes)) return scope;

  let offset = 0;
  const out = {};

  for (let i = 1; i <= regexes.length; i += 1) {
    const key = String(i);
    if (Object.prototype.hasOwnProperty.call(scope, key)) {
      out[String(i + offset)] = scope[key];
    }
    offset += regex.countMatchGroups(regexes[i - 1]);
  }

  return out;
}

function extractLanguageIR(language) {
  const modeIds = new Map();
  const modes = [];
  let counter = 0;

  const getId = (mode) => {
    if (modeIds.has(mode)) return modeIds.get(mode);
    counter += 1;
    const id = `m${counter}`;
    modeIds.set(mode, id);
    modes.push(serializeMode(mode, id));
    return id;
  };

  const serializeContains = (contains, owner) => {
    if (!Array.isArray(contains)) return [];
    return contains.map((item) => {
      if (item === "self") return "self";
      if (owner && item === owner) return "self";
      if (typeof item === "object") return { ref: getId(item) };
      return null;
    }).filter(Boolean);
  };

  const serializeVariants = (variants) => {
    if (!Array.isArray(variants)) return [];
    return variants.map((item) => ({ ref: getId(item) }));
  };

  const serializeMode = (mode, id) => {
    const rawScope = mode.scope;
    const rawClassName = mode.className;
    const scope = typeof rawScope === "string" ? rawScope : null;
    const className = typeof rawClassName === "string" ? rawClassName : null;

    let beginScope = serializeScope(mode.beginScope);
    let endScope = serializeScope(mode.endScope);

    if (!beginScope && rawScope && typeof rawScope === "object" && !Array.isArray(rawScope)) {
      beginScope = serializeScope(rawScope);
    }
    if (!beginScope && rawClassName && typeof rawClassName === "object" && !Array.isArray(rawClassName)) {
      beginScope = serializeScope(rawClassName);
    }

    if (Array.isArray(mode.begin) && beginScope && typeof beginScope === "object") {
      beginScope = remapScope(beginScope, mode.begin);
    }
    if (Array.isArray(mode.match) && beginScope && typeof beginScope === "object") {
      beginScope = remapScope(beginScope, mode.match);
    }
    if (Array.isArray(mode.end) && endScope && typeof endScope === "object") {
      endScope = remapScope(endScope, mode.end);
    }

    const starts = mode.starts ? { ref: getId(mode.starts) } : null;

    return {
      id,
      scope,
      className,
      begin: serializeSequence(mode.begin),
      end: serializeSequence(mode.end),
      match: serializeSequence(mode.match),
      beginScope,
      endScope,
      contains: serializeContains(mode.contains, mode),
      variants: serializeVariants(mode.variants),
      starts,
      keywords: serializeKeywords(mode.keywords),
      illegal: serializeEither(mode.illegal),
      relevance: typeof mode.relevance === "number" ? mode.relevance : null,
      excludeBegin: Boolean(mode.excludeBegin),
      excludeEnd: Boolean(mode.excludeEnd),
      returnBegin: Boolean(mode.returnBegin),
      returnEnd: Boolean(mode.returnEnd),
      endsWithParent: Boolean(mode.endsWithParent),
      endsParent: Boolean(mode.endsParent),
      skip: Boolean(mode.skip),
      subLanguage: mode.subLanguage || null,
      beginKeywords: mode.beginKeywords || null
    };
  };

  const ir = {
    version: 1,
    language: {
      name: language.name || null,
      aliases: language.aliases || [],
      disableAutodetect: Boolean(language.disableAutodetect),
      caseInsensitive: Boolean(language.case_insensitive),
      unicodeRegex: Boolean(language.unicodeRegex),
      keywords: serializeKeywords(language.keywords),
      illegal: serializeEither(language.illegal),
      classNameAliases: language.classNameAliases || {},
      contains: serializeContains(language.contains || [], null)
    },
    modes
  };

  return ir;
}

async function run() {
  await fs.mkdir(outputDir, { recursive: true });

  for (const file of languageFiles) {
    const langPath = path.join(languagesDir, file);
    const langModule = await import(pathToFileURL(langPath).href);
    if (!langModule.default) {
      console.error(`Skipping ${file}: no default export`);
      continue;
    }

    const langFn = langModule.default;
    const language = langFn(hljs);
    const ir = extractLanguageIR(language);

    const outName = file.replace(/\.js$/, ".json");
    const outPath = path.join(outputDir, outName);
    await fs.writeFile(outPath, JSON.stringify(ir, null, 2) + "\n", "utf8");
    console.log(`Wrote ${outPath}`);
  }
}

if (!all && langs.length === 0) {
  console.error("Usage: tools/extract-hljs-ir.mjs --lang swift | --all");
  process.exit(1);
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
