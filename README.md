# STM32 Firmware Monorepo — CI/CD Pipeline

## Overview

Monorepo containing multiple STM32 firmware products with shared code. The CI/CD pipeline **auto-discovers** products, detects changes using **GitHub PR Files API**, and deploys **only the products that changed**.

- **Product folder changes** → automatic build & deploy
- **Non-product changes only** (common/, sdk/, docs/, etc.) → manual deploy from Jenkins UI
- **New products** → just create a folder under `products/` — no pipeline changes needed

## How Change Detection Works

The pipeline uses **GitHub's PR Files API** — the same data shown in the "Files changed" tab when you view a PR. This ensures:

- ✅ **All commits included** — PR with 70 commits shows all changed files, not just the last commit
- ✅ **Exact match to PR UI** — what you see in "Files changed" is what triggers deployment
- ✅ **Works with any merge strategy** — squash, merge commit, or rebase

```
PR #123: feature/update-flo → develop
         │
         ▼
┌─────────────────────────────────────┐
│  GitHub API: /pulls/123/files       │
│  (same as "Files changed" tab)      │
│                                     │
│  products/FLO/app/main.c            │
│  products/FLO/lora/app_version.h    │
│  common/board/inc/board_config.h    │
│  README.md                          │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  Match file paths → product folders │
│                                     │
│  products/FLO/...  →  FLO ✓         │
│  common/...        →  non-product   │
│  README.md         →  non-product   │
└─────────────────────────────────────┘
         │
         ▼
   Auto Deploy: ["FLO"]
```

## Repository Structure

```
├── Jenkinsfile                         # Calls STM32MonorepoPipeline shared library
├── .github/workflows/
│   └── trigger-jenkins.yml             # GitHub Actions: build + trigger Jenkins
├── products/                           # ← Product folder (configurable name)
│   ├── ONE/                            #   ONE (FSO) firmware
│   │   ├── app/main.c
│   │   ├── lora/lora_app.c
│   │   └── tests/test/test_main.c
│   ├── TIM/                            #   TIM firmware
│   ├── TIM+/                           #   TIM+ firmware
│   └── FLO/                            #   FLO firmware
├── common/                             # Shared: board init, drivers, lora, platform
├── sdk/                                # Vendor SDK: HAL, LoRaWAN stack, utilities
└── docs/                               # Documentation
```

## Deployment Logic

| What Changed | Build & Deploy | Mode |
|---|---|---|
| `products/ONE/` | ONE only | Auto |
| `products/TIM/` + `products/FLO/` | TIM and FLO | Auto |
| `products/ONE/` + `common/` | ONE only | Auto |
| `products/ONE/` + `products/TIM/` + `sdk/` | ONE and TIM | Auto |
| `common/` only | User selects from Jenkins UI | Manual |
| `sdk/` only | User selects from Jenkins UI | Manual |
| `common/` + `sdk/` + `docs/` | User selects from Jenkins UI | Manual |
| `Jenkinsfile` or `README.md` only | User selects from Jenkins UI | Manual |

**Key rule:** If any `products/<name>/` folder has changes, only those products auto-deploy. Everything outside `products/` is ignored for auto-deploy.

## CI/CD Flow

```
Developer → PR to develop/qa-devops → Merge
                                        │
                    ┌───────────────────┤
                    ▼                    ▼
           GitHub Actions            Jenkins (Multibranch)
           ─────────────            ────────────────────
           1. Detect changes        1. Detect changes (git diff)
           2. Build changed         2. Auto or Manual routing
              products (matrix)     3. Build in STM32 Docker
           3. Trigger Jenkins       4. Run unit tests
              (if products          5. Upload .bin to S3
               changed)            6. SCA scan
```

### GitHub Actions (`.github/workflows/trigger-jenkins.yml`)

- Runs **only on PR merge** (not direct pushes)
- **Change detection:** Uses GitHub PR Files API (`gh api /pulls/{pr}/files`)
  - Matches exactly what you see in PR "Files changed" tab
  - Includes ALL files from ALL commits in the PR
  - Works with squash, merge commit, or rebase strategies
- Auto-discovers products from `products/` directory (no hardcoding)
- Uses **dynamic matrix** to build only changed products in parallel
- If product changes → triggers Jenkins deployment via API
- If non-product changes only → shows "Manual Deploy Required" notice

### Jenkins (`Jenkinsfile` → `STM32MonorepoPipeline` library)

- Loads shared library from `wf-jenkins-lib`
- Auto-discovers products from `products/` directory
- Receives changed products list from GitHub Actions (via `DEPLOY_PRODUCT` parameter)
- **Auto mode:** deploys changed products without user input
- **Manual mode:** pauses pipeline, user selects which products to deploy
- Builds each product inside STM32 Docker container
- Uploads `.bin` firmware artifacts to S3

## Configuration

### Renaming the Products Folder

If you need to rename `products/` to something else (e.g., `firmware/`):

| File | What to Change |
|---|---|
| `Jenkinsfile` | `productsDir: 'firmware'` |
| `trigger-jenkins.yml` | `PRODUCTS_DIR: firmware` |

### Adding a New Product

1. Create a folder: `products/NEW_PRODUCT/`
2. Add your firmware code inside it
3. Done — the pipeline auto-discovers it

### Branches & Environments

| Branch | Environment | Deploy Trigger |
|---|---|---|
| `develop` | Development | PR merge |
| `qa-devops` | QA | PR merge |
| `feature/*` | — | No auto-deploy |

## Shared Library

The pipeline logic lives in `wf-jenkins-lib` at `vars/STM32MonorepoPipeline.groovy`.

```groovy
// Jenkinsfile — this is all you need
@Library('wf-jenkins-lib') _

STM32MonorepoPipeline(
    productsDir: 'products'
)
```

### Library Configuration Options

| Parameter | Default | Description |
|---|---|---|
| `productsDir` | `'products'` | Root folder containing product subdirectories |
| `additionalChoiceParam` | `[:]` | Extra Jenkins job parameters |
| `isTeamEnvironment` | `false` | Team environment flag |
| `dockerImage` | STM32IDE image | Override Docker build image |

## Setup Guide

### Prerequisites

- GitHub repository with monorepo structure
- Jenkins Multibranch Pipeline job
- `wf-jenkins-lib` configured as a Global Shared Library in Jenkins

### GitHub Secrets Required

| Secret | Description |
|---|---|
| `JENKINS_URL` | Jenkins base URL (e.g., `https://build.afreespace.com`) |
| `JENKINS_USER` | Jenkins user ID |
| `JENKINS_TOKEN` | Jenkins API token |

### Jenkins Job Configuration

1. Create **Multibranch Pipeline** → point to this repo
2. Configure **Branch Sources** → Git with credentials
3. The `Jenkinsfile` automatically uses the shared library

## Pending TODO

- [ ] **Dockerfile:** Add real STM32 build Docker image
- [ ] **Build commands:** Replace placeholder `make` commands with actual firmware toolchain
- [ ] **Unit tests:** Configure C Unity test framework per product
- [ ] **Library merge:** Merge `wf-jenkins-lib` branch `feature/stm32-monorepo` to master, then update `@Library` in Jenkinsfile

## Local Development

```bash
git checkout develop
git checkout -b feature/my-change

# Make changes to product code
git add . && git commit -m "Update ONE firmware"
git push origin feature/my-change

# Create PR targeting develop → merge → auto-deploy
```

## Testing Change Detection Locally

You can verify which files/products would be detected before merging:

```bash
# See changed files for a PR (same as "Files changed" tab)
gh pr diff 123 --name-only

# Or via API (exactly what the workflow uses)
gh api repos/OWNER/REPO/pulls/123/files --jq '.[].filename'

# Compare branches directly
git diff --name-only develop...feature/my-branch

# Checkout PR to inspect
gh pr checkout 123
```

## Version Management

Each product maintains its version in `lora/app_version.h`:

```c
#define APP_VERSION_MAIN   (0x01U)  // Major
#define APP_VERSION_SUB1   (0x06U)  // Minor
#define APP_VERSION_SUB2   (0x03U)  // Patch
// → Version tag: [FLO-v1.6.3]
```

| Product | Version File | Example Tag |
|---------|--------------|-------------|
| FLO | `products/FLO/lora/app_version.h` | `[FLO-v1.6.3]` |
| ONE | `products/ONE/lora/app_version.h` | `[ONE-v3.1.3]` |
| TIM | `products/TIM/lora/app_version.h` | `[TIM-v4.1.2]` |
| TIM+ | `products/TIM+/lora/app_version.h` | `[TIM_PLUS-v1.5.1]` |
| FSO | `products/FSO/lora/app_version.h` | `[FSO-v1.0.0]` |

## Test Log

| # | Date | Branch | Change Type | Expected | Actual | Status |
|---|------|--------|-------------|----------|--------|--------|
| 1 | Jun 8 | feature/common-lora-update | Non-product (common/) | Manual Notice | Manual Notice shown | PASS |
| 2 | Jun 8 | feature/one-v3.0 | Product (ONE/) | Auto deploy ONE | Auto deploy ONE triggered | PASS |
| 3 | Jun 9 | feature/test-non-product-change | Non-product (README) | Manual Notice | Pending... | - |
| 4 | Jun 9 | feature/test-product-change | Product (TIM/) | Auto deploy TIM | Pending... | - |
