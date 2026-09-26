// Update-check redirect patch — the ONLY code change 9router-fnos applies to
// the pristine upstream source before building the fpk.
//
// Why: the fnOS fpk ships from this repo's GitHub Releases (not npm), so the
// in-app update check must look at techysy/9router-fnos releases/latest
// (tag_name) instead of the npm `9router` package, and the manual-update panel
// must point users at the fpk download page instead of `npm i -g`.
//
// Everything else stays byte-identical to upstream. Run from the repo root of
// a fresh upstream clone:  node <this-file>
// Exits non-zero (touching nothing) if any marker is missing — upstream drift
// must be reviewed, not silently skipped.
import fs from "node:fs";

const files = {
  versionRoute: "src/app/api/version/route.js",
  config: "src/shared/constants/config.js",
};

function replaceExactly(file, from, to) {
  const src = fs.readFileSync(file, "utf8");
  if (!src.includes(from)) {
    console.error(`[update-check patch] marker not found in ${file}:\n---\n${from}\n---`);
    console.error("Upstream drifted — review and update this patch manually. Aborting.");
    process.exit(1);
  }
  if (src.includes(to)) {
    console.log(`[update-check patch] ${file}: already patched, skipping`);
    return;
  }
  fs.writeFileSync(file, src.replace(from, to));
  console.log(`[update-check patch] ${file}: ok`);
}

// ── 1. /api/version: latest version ← GitHub releases of the packaging repo ──
replaceExactly(
  files.versionRoute,
  `const NPM_PACKAGE_NAME = "9router";
const VERSION_CACHE_TTL_MS = 3600000; // cache npm latest lookup for 1h`,
  `// fnOS fpk channel: versions ship as .fpk assets on the packaging repo's
// GitHub Releases — check there instead of the npm registry.
const RELEASES_API = "https://api.github.com/repos/techysy/9router-fnos/releases/latest";
const VERSION_CACHE_TTL_MS = 3600000; // cache latest lookup for 1h`,
);

replaceExactly(
  files.versionRoute,
  `// Fetch latest version from npm registry
function fetchLatestVersion() {
  return new Promise((resolve) => {
    const req = https.get(
      \`https://registry.npmjs.org/\${NPM_PACKAGE_NAME}/latest\`,
      { timeout: 4000 },
      (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          try {
            resolve(JSON.parse(data).version || null);
          } catch {
            resolve(null);
          }
        });
      }
    );`,
  `// Fetch latest version from GitHub releases (tag_name, "v" prefix stripped)
function fetchLatestVersion() {
  return new Promise((resolve) => {
    const req = https.get(
      RELEASES_API,
      { timeout: 4000, headers: { "User-Agent": "9router-fnos-updater", Accept: "application/vnd.github+json" } },
      (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          try {
            resolve(String(JSON.parse(data).tag_name || "").replace(/^v/, "") || null);
          } catch {
            resolve(null);
          }
        });
      }
    );`,
);

// ── 2. Manual-update panel: npm install cmd → fpk download page ──
replaceExactly(
  files.config,
  `  npmPackageName: "9router",
  installCmd: "npm i -g 9router",
  installCmdLatest: "npm i -g 9router@latest --prefer-online",`,
  `  npmPackageName: "9router",
  // fnOS fpk packaging: updates are .fpk assets on the packaging repo — the
  // manual-update panel points there instead of an npm command.
  installCmd: "fpk: https://github.com/techysy/9router-fnos/releases",
  installCmdLatest: "fpk: https://github.com/techysy/9router-fnos/releases",`,
);

console.log("[update-check patch] done");
