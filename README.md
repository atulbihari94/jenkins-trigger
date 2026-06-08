# STM32 Firmware Monorepo — CI/CD Pipeline

## Overview

Monorepo containing multiple STM32 firmware products with shared code. The CI/CD pipeline **auto-discovers** products, detects changes via git diff, and deploys **only the products that changed**.

- **Product folder changes** → automatic build & deploy
- **Non-product changes only** (common/, sdk/, docs/, etc.) → manual deploy from Jenkins UI
- **Manual trigger from Jenkins UI** → always manual (user selects products)
- **New products** → just create a folder under `products/` — no pipeline changes needed

## Repository Structure

```
├── Jenkinsfile                         # Calls STM32MonorepoPipeline shared library
├── .github/workflows/
│   └── trigger-jenkins.yml             # GitHub Actions: build + trigger Jenkins
├── products/                           # Product folder (hardcoded in library)
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
| `common/` only | User selects from Jenkins UI | Manual |
| `sdk/` or `docs/` only | User selects from Jenkins UI | Manual |
| Manual trigger from Jenkins UI | User selects from Jenkins UI | Manual |

**Key rule:** If any `products/<name>/` folder has changes, only those products auto-deploy. Everything outside `products/` is ignored for auto-deploy. Manual trigger from Jenkins UI **always** prompts for product selection.

## CI/CD Flow

```
Developer → PR to develop/qa-devops → Merge
                                        │
                    ┌───────────────────┤
                    ▼                    ▼
           GitHub Actions            Jenkins (Multibranch)
           ─────────────            ────────────────────
           1. Detect changes        1. Check trigger source
              (git diff HEAD~1)        (API vs manual)
           2. Build changed         2. Auto or Manual routing
              products (matrix)     3. Build in STM32 Docker
           3. Trigger Jenkins       4. Run unit tests
              (if products          5. Upload .bin to S3
               changed)            6. SCA scan
                                   7. Slack/email notification
```

### GitHub Actions (`.github/workflows/trigger-jenkins.yml`)

- Runs **only on PR merge** (not direct pushes)
- Uses `actions/checkout@v4` with `fetch-depth: 2` (2 commits: merge + parent)
- Change detection: `git diff --name-only HEAD~1 HEAD` compares merge commit with parent
- Auto-discovers products from `products/` directory
- Uses **dynamic matrix** to build only changed products in parallel
- If product changes → triggers Jenkins deployment via API
- If non-product changes only → shows "Manual Deploy Required" notice

### Jenkins (`Jenkinsfile` → `STM32MonorepoPipeline` library)

- Loads shared library from `wf-jenkins-lib`
- Checks trigger source: `UserIdCause` (manual UI) vs `RemoteCause` (GitHub API)
- **Auto mode:** API trigger + product changes → deploys changed products
- **Manual mode:** manual trigger or non-product only → user selects products
- Build display name: `#21 [ONE-v3.1.0] (AUTO)` or `#21 [TIM-v4.1.0] (MANUAL)`
- Builds each product inside STM32 Docker container
- Uploads `.bin` firmware artifacts to S3

## Notifications

The pipeline sends notifications on build success, failure, and abort.

### Slack

Requires the [Slack Notification Plugin](https://plugins.jenkins.io/slack/) in Jenkins.

| Event | Channel | Color | Message |
|---|---|---|---|
| Success | `#firmware-deployments` | Green | Products deployed, mode, build link |
| Failure | `#firmware-deployments` | Red | Failed stage, console log link |
| Aborted | `#firmware-deployments` | Yellow | Build link |

**Setup:**
1. Install Slack Notification Plugin in Jenkins
2. Create a Slack app or incoming webhook
3. Configure in Jenkins: Manage Jenkins → System → Slack
4. Set workspace, channel, and credentials

### Email

Requires the [Email Extension Plugin](https://plugins.jenkins.io/email-ext/) in Jenkins.

Sends HTML email on failure to:
- **Requestor** — person who triggered the build
- **Culprits** — developers whose commits are in the build

**Setup:**
1. Install Email Extension Plugin in Jenkins
2. Configure SMTP in Jenkins: Manage Jenkins → System → Extended E-mail Notification
3. Set SMTP server, port, credentials, and default recipients

### GitHub Actions Failure

GitHub Actions sends notifications natively:
- Failed checks appear on the PR and in GitHub notification settings
- Configure email/Slack notifications in GitHub → Settings → Notifications

## Adding a New Product

1. Create a folder: `products/NEW_PRODUCT/`
2. Add `app/main.c` with `#define FIRMWARE_VERSION "1.0.0"`
3. Done — the pipeline auto-discovers it

## Branches & Environments

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
STM32MonorepoPipeline()
```

## GitHub Secrets Required

| Secret | Description |
|---|---|
| `JENKINS_URL` | Jenkins base URL (e.g., `https://build.afreespace.com`) |
| `JENKINS_USER` | Jenkins user ID |
| `JENKINS_TOKEN` | Jenkins API token |

## Pending TODO

- [ ] **Dockerfile:** Add real STM32 build Docker image
- [ ] **Build commands:** Replace placeholder `make` commands with actual firmware toolchain
- [ ] **Unit tests:** Configure C Unity test framework per product
- [ ] **Library merge:** Merge `wf-jenkins-lib` branch `feature/stm32-monorepo` to master, then update `@Library` in Jenkinsfile
- [ ] **Slack:** Install Slack plugin and configure webhook in Jenkins
- [ ] **Email:** Configure SMTP settings in Jenkins for failure emails

## Test Log

| # | Date | Branch | Change Type | Expected | Actual | Status |
|---|------|--------|-------------|----------|--------|--------|
| 1 | Jun 8 | feature/common-lora-update | Non-product (common/) | Manual Notice | Manual Notice shown | PASS |
| 2 | Jun 8 | feature/one-v3.0 | Product (ONE/) | Auto deploy ONE | Auto deploy ONE triggered | PASS |
| 3 | Jun 9 | feature/test-non-product-change | Non-product (README) | Manual Notice | Manual Notice shown, no Jenkins trigger | PASS |
| 4 | Jun 9 | feature/test-product-change | Product (TIM/) | Auto deploy TIM | Build TIM passed, Jenkins trigger attempted | PASS |
