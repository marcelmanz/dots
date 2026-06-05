---
name: vite-environment-transfers
description: |-
  Guides the analysis of discrepancies between local development transfer sizes (e.g., 1.89 KB) and deployed build sizes (e.g., 1.28 MB). 
  Use when a user is confused by bundle size reports, different file hashes across environments, or the activation of production-like features in dev deployments.
  Examples:
  - user: "Why is my local dev so small but my deploy is 1.28 MB?" -> explain ESM vs Bundling.
  - user: "The file hashes are different locally vs pipeline" -> explain build determinism and environment inlining.
---

# Project Skill: Vite Build & Environment Analysis

This document explains the technical architecture behind why local development and deployed environments return vastly different transfer data, even with identical source code.

---

## 1. Local ESM vs. Deployed Bundling

The most significant difference is the architectural shift between Vite's dev server and the production build process.

- [cite_start]**Local Development (`pnpm dev`):** Vite serves your code using **Native ESM**, which means it does not bundle. [cite: 25] The browser receives a tiny `index.html` and the Vite client (~1.89 KB), then fetches individual modules only when needed.
- [cite_start]**Deployed Build (`pnpm build`):** The pipeline triggers a full **Rollup** build. [cite: 25] [cite_start]This transforms and bundles over **2,400 modules** into optimized chunks. [cite: 26] [cite_start]The ~1.28 MB total weight is the combined sum of these combined assets. [cite: 58]

## 2. Environment-Specific Optimizations

The project's `vite.config.ts` uses conditional logic to apply production-level optimizations to all deployed environments (including `dev`).

### Activation Logic

The config uses the following check to enable specific features:

> [cite_start]`const isDeployedEnv = ['production', 'prod', 'dev', 'stg'].includes(mode);` [cite: 25]

When this is **true** (as seen in the pipeline log), the following are activated:

- [cite_start]**Gzip Compression:** The `compression()` plugin is injected with a `threshold: 1024`, generating `.gz` files for assets larger than 1 KB. [cite: 27, 34]
- [cite_start]**Minification & Stripping:** The `esbuild` configuration drops `console` and `debugger` statements to reduce bundle size. [cite: 25]
- **Manual Chunking:** Specific dependencies are split into named vendor files to optimize caching:
  - [cite_start]**vendor-core:** Includes React, React-DOM, Router, and Zustand (~362 KB). [cite: 58]
  - [cite_start]**vendor-ui:** Includes Radix UI and Lucide React (~93 KB). [cite: 56]
  - [cite_start]**vendor-data:** Includes Tanstack Query and Zod (~166 KB). [cite: 57]

## 3. Build Determinism and File Hashes

[cite_start]File hashes (e.g., `vendor-core.yTqV9NBC.js`) vary between environments due to "Environment Inlining." [cite: 58]

| Factor                | Impact on Hash                                                                                                                                                                     |
| :-------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **OS Binaries**       | [cite_start]Pipeline runs on Linux (`node:22-slim`). [cite: 13] Local builds on Mac/Windows use different platform-specific minifiers, causing byte-level differences.             |
| **Inlined Variables** | [cite_start]System-level variables (e.g., `PORT: "3000"`, `VITE_APP_BRAND: default`) are baked into the JS files. [cite: 59, 60] Any difference in these strings changes the hash. |
| **Asset Copying**     | [cite_start]The `brandPlugin` copies assets like `favicon.ico` and `brand.css` directly to the public folder during the build. [cite: 25]                                          |

## 4. Verification Steps

To reproduce the deployed build results on your local machine for a fair comparison:

1.  [cite_start]**Clean Build:** `rm -rf dist && pnpm build --mode dev` [cite: 25]
2.  **Preview Build:** `pnpm preview`
3.  [cite_start]**Audit:** Open the browser's Network tab and look at the **Total Transferred** at the bottom, which should now align with the ~1.28 MB pipeline report. [cite: 58]

