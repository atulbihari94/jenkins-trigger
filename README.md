# STM32 Firmware Monorepo CI/CD

Monorepo for multiple STM32 firmware products with intelligent change detection and selective deployment.

## Quick Links

- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [How It Works](#how-it-works)
- [Jenkins Setup Guide](#jenkins-setup-guide) (PAT, Secrets, Job Config)
- [GitHub Secrets Setup](#github-secrets-setup)
- [Adding New Products](#adding-new-products)
- [Version Management](#version-management)
- [Troubleshooting](#troubleshooting)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           STM32 MONOREPO CI/CD                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Developer                                                                 │
│      │                                                                      │
│      ▼                                                                      │
│   ┌─────────────────┐                                                       │
│   │  Create PR to   │                                                       │
│   │  develop branch │                                                       │
│   └────────┬────────┘                                                       │
│            │                                                                │
│            ▼                                                                │
│   ┌─────────────────┐     ┌─────────────────────────────────────────────┐   │
│   │  Merge PR       │────▶│  GitHub Actions (trigger-jenkins.yml)       │   │
│   └─────────────────┘     │                                             │   │
│                           │  1. Get PR files via GitHub API             │   │
│                           │  2. Auto-discover products/ folders         │   │
│                           │  3. Match files → products                  │   │
│                           │  4. Build changed products (parallel)       │   │
│                           │  5. Trigger Jenkins via REST API            │   │
│                           └────────────────────┬────────────────────────┘   │
│                                                │                            │
│                                                ▼                            │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  Jenkins (STM32MonorepoPipeline)                                    │   │
│   │                                                                     │   │
│   │  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐               │   │
│   │  │ Initial     │──▶│ Build in    │──▶│ Upload to   │               │   │
│   │  │ Setup       │   │ STM32 Docker│   │ S3          │               │   │
│   │  └─────────────┘   └─────────────┘   └─────────────┘               │   │
│   │                                                                     │   │
│   │  Trigger Detection:                                                 │   │
│   │  - RemoteCause (API) → Auto deploy, skip approval                  │   │
│   │  - UserIdCause (UI)  → Manual deploy, requires approval            │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
jenkins-trigger/
├── Jenkinsfile                              # Minimal - calls shared library
├── .github/
│   └── workflows/
│       └── trigger-jenkins.yml              # GitHub Actions workflow
├── products/                                # Auto-discovered product folders
│   ├── FLO/
│   │   ├── app/main.c
│   │   ├── lora/
│   │   │   ├── app_version.h                # Version: 1.6.5
│   │   │   └── lora_app.c
│   │   └── tests/
│   ├── ONE/
│   │   └── lora/app_version.h               # Version: 3.1.4
│   ├── TIM/
│   │   └── lora/app_version.h               # Version: 4.2.0
│   ├── TIM+/
│   │   └── lora/app_version.h               # Version: 1.5.2
│   └── FSO/
│       └── lora/app_version.h               # Version: 1.0.1
├── common/                                  # Shared code (board, drivers, lora)
├── sdk/                                     # Vendor SDK
└── docs/                                    # Documentation
```

---

## How It Works

### Change Detection

Uses **GitHub PR Files API** — same data shown in "Files changed" tab:

| PR Changes | Detected Products | Deploy Mode |
|------------|-------------------|-------------|
| `products/FLO/app/main.c` | FLO | Auto |
| `products/ONE/...` + `products/TIM/...` | ONE, TIM | Auto |
| `products/FLO/...` + `common/board.c` | FLO | Auto |
| `common/drivers/spi.c` only | None | Manual (user picks) |
| `Jenkinsfile` only | None | Manual (user picks) |

### Trigger Detection (No AUTO_DEPLOY parameter)

Jenkins detects how the build was triggered using **build causes**:

| Trigger | Build Cause | Behavior |
|---------|-------------|----------|
| GitHub Actions API | `RemoteCause` | Auto deploy, skip approval |
| Jenkins UI | `UserIdCause` | Manual deploy, requires approval + product selection |

---

## Jenkins Setup Guide

### Step 1: Create Jenkins API Token (PAT)

1. Log in to Jenkins as the user who will trigger builds
2. Click your username (top-right) → **Configure**
3. Scroll to **API Token** section
4. Click **Add new Token**
5. Give it a name (e.g., `github-actions-token`)
6. Click **Generate** and **copy the token immediately** (shown only once)

```
Token example: 11a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

### Step 2: Enable Remote Build Triggers

1. Go to your Jenkins job → **Configure**
2. Under **Build Triggers**, check **Trigger builds remotely**
3. Optionally set an authentication token (not required if using user+API token)

### Step 3: Configure Global Shared Library

1. Go to **Manage Jenkins** → **System**
2. Scroll to **Global Pipeline Libraries**
3. Click **Add**

| Field | Value |
|-------|-------|
| Name | `wf-jenkins-lib` |
| Default version | `feature/stm32-monorepo` (or `main` after merge) |
| Allow default version to be overridden | ✓ |
| Include @Library changes in job recent changes | ✓ |
| **Retrieval method** | Modern SCM |
| **Source Code Management** | Git |
| Project Repository | `ssh://git-codecommit.eu-west-1.amazonaws.com/v1/repos/wf-jenkins-lib` |
| Credentials | (your CodeCommit credentials) |

### Step 4: Create Multibranch Pipeline Job

1. **New Item** → Enter name (e.g., `stm32-firmware-monorepo`) → **Multibranch Pipeline**
2. Configure **Branch Sources**:

| Field | Value |
|-------|-------|
| Git | ✓ |
| Project Repository | `https://github.com/YOUR_ORG/jenkins-trigger.git` |
| Credentials | (GitHub credentials) |
| Behaviors | Discover branches, Filter by name: `develop|qa-devops|feature/*` |

3. Configure **Build Configuration**:

| Field | Value |
|-------|-------|
| Mode | by Jenkinsfile |
| Script Path | `Jenkinsfile` |

4. **Save** → Jenkins will scan branches and create jobs for `develop`, `qa-devops`

### Step 5: Verify Jenkins URL Format

The GitHub Actions workflow triggers Jenkins using this URL pattern:

```
https://YOUR_JENKINS_URL/job/JOB_NAME/job/BRANCH/buildWithParameters?TARGET_ENV=dev&DEPLOY_PRODUCT=FLO
```

Example:
```
https://build.afreespace.com/job/stm32-firmware-monorepo/job/develop/buildWithParameters?TARGET_ENV=dev&DEPLOY_PRODUCT=ONE
```

---

## GitHub Secrets Setup

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### Required Secrets

| Secret Name | Value | Example |
|-------------|-------|---------|
| `JENKINS_URL` | Jenkins base URL (no trailing slash) | `https://build.afreespace.com` |
| `JENKINS_USER` | Jenkins username | `atul.bihari` |
| `JENKINS_TOKEN` | Jenkins API token (from Step 1) | `11a1b2c3d4e5f6g7h8i9j0k1l2m3...` |

### How to Get Jenkins URL

1. Open Jenkins in your browser
2. Copy the URL up to the domain (no `/job/...`)
3. Remove trailing slash if present

```
✓ https://build.afreespace.com
✗ https://build.afreespace.com/
✗ https://build.afreespace.com/job/my-job
```

### How to Get Jenkins User

This is your Jenkins login username (not email):

```
✓ atul.bihari
✗ atul.bihari@company.com
```

### Testing the Secrets

After setting secrets, you can verify by triggering a workflow manually or merging a test PR.

Check the GitHub Actions log for:
```
Triggering Jenkins: stm32-firmware-monorepo/develop (DEPLOY_PRODUCT=FLO, TARGET_ENV=dev)
Jenkins triggered successfully!
```

If it fails, check:
- HTTP 401: Invalid `JENKINS_USER` or `JENKINS_TOKEN`
- HTTP 403: User doesn't have permission to trigger builds
- HTTP 404: Wrong `JENKINS_URL` or job name

---

## Adding New Products

1. Create folder: `products/NEW_PRODUCT/`
2. Add version file: `products/NEW_PRODUCT/lora/app_version.h`
3. Add your firmware code
4. Commit and push

The pipeline auto-discovers the new product on next run.

### Version File Template

```c
/* products/NEW_PRODUCT/lora/app_version.h */
#ifndef __APP_VERSION_H__
#define __APP_VERSION_H__

#define APP_VERSION_MAIN   (0x01U)  /*!< [31:24] main version */
#define APP_VERSION_SUB1   (0x00U)  /*!< [23:16] sub1 version */
#define APP_VERSION_SUB2   (0x00U)  /*!< [15:8]  sub2 version */
#define APP_VERSION_RC     (0x00U)  /*!< [7:0]   release candidate */

#endif /* __APP_VERSION_H__ */
```

---

## Version Management

Each product stores its version in `lora/app_version.h`:

| Product | File | Current Version |
|---------|------|-----------------|
| FLO | `products/FLO/lora/app_version.h` | 1.6.5 |
| ONE | `products/ONE/lora/app_version.h` | 3.1.4 |
| TIM | `products/TIM/lora/app_version.h` | 4.2.0 |
| TIM+ | `products/TIM+/lora/app_version.h` | 1.5.2 |
| FSO | `products/FSO/lora/app_version.h` | 1.0.1 |

### Version Format

```c
#define APP_VERSION_MAIN   (0x01U)  // Major: 1
#define APP_VERSION_SUB1   (0x06U)  // Minor: 6
#define APP_VERSION_SUB2   (0x05U)  // Patch: 5
// → Build label: [FLO-v1.6.5]
```

### Updating Version

1. Edit `products/<PRODUCT>/lora/app_version.h`
2. Update `APP_VERSION_MAIN`, `APP_VERSION_SUB1`, or `APP_VERSION_SUB2`
3. Commit, push, create PR, merge

---

## Jenkins UI Parameters

When using **Build with Parameters** in Jenkins:

| Parameter | Description |
|-----------|-------------|
| `TARGET_ENV` | `dev` or `qa` environment |
| `DEPLOY_PRODUCT` | `None`, `ALL`, or specific product name |
| `IS_SCAN_ONLY_SRC` | SonarQube scan setting |

### Manual Deploy Flow

1. Open Jenkins job → **Build with Parameters**
2. Select `TARGET_ENV` (dev/qa)
3. Select `DEPLOY_PRODUCT` (must select a product, cannot be `None`)
4. Click **Build**
5. Approve when prompted
6. Deployment proceeds

### Auto Deploy Flow (PR Merge)

1. Merge PR to `develop` or `qa-devops`
2. GitHub Actions detects changed products
3. GitHub Actions triggers Jenkins via API with `DEPLOY_PRODUCT` set
4. Jenkins detects `RemoteCause` → skips approval
5. Deployment proceeds automatically

---

## Troubleshooting

### Jenkins build not triggered

1. Check GitHub Actions logs for errors
2. Verify secrets are set correctly
3. Test Jenkins URL manually:
   ```bash
   curl -u "USER:TOKEN" "https://YOUR_JENKINS/job/JOB/job/develop/api/json"
   ```

### 401 Unauthorized

- Invalid `JENKINS_USER` or `JENKINS_TOKEN`
- Regenerate API token and update secret

### 403 Forbidden

- User doesn't have permission to trigger builds
- Add user to appropriate Jenkins role/group

### 404 Not Found

- Wrong job name or branch
- Check: `JENKINS_URL/job/JOB_NAME/job/BRANCH/` exists

### Products not detected

- Ensure folder exists under `products/`
- Folder must contain at least one file
- Check GitHub Actions log for "Discovered products"

### Manual deploy required when expecting auto

- Only `products/` folder changes trigger auto-deploy
- Changes to `common/`, `sdk/`, `Jenkinsfile`, etc. require manual deploy

---

## Files Reference

| File | Purpose |
|------|---------|
| `Jenkinsfile` | Entry point, calls `STM32MonorepoPipeline()` |
| `.github/workflows/trigger-jenkins.yml` | GitHub Actions workflow |
| `wf-jenkins-lib/vars/STM32MonorepoPipeline.groovy` | Main pipeline logic |
| `wf-jenkins-lib/vars/setupSTM32.groovy` | Minimal parameter setup |

---

## Test History

| Date | PR | Changes | Expected | Result |
|------|-----|---------|----------|--------|
| Jun 8 | #20 | common/lora | Manual Notice | PASS |
| Jun 8 | #21 | products/FLO + workflow | Auto deploy FLO | PASS |
| Jun 9 | #22 | 5 products (merge commit) | Auto deploy all 5 | PASS |
| Jun 9 | #23 | 3 products (rebase) | Auto deploy all 3 | PASS |
| Jun 9 | #24 | products/ONE (squash) | Auto deploy ONE | PASS |
| Jun 9 | #25 | products/TIM + Jenkinsfile | Auto deploy TIM | PASS |

---

## Pending TODOs

- [ ] Merge `wf-jenkins-lib` branch `feature/stm32-monorepo` to main
- [ ] Update `Jenkinsfile` to use `@Library('wf-jenkins-lib')` (no branch)
- [ ] Add real STM32 Docker build image
- [ ] Replace placeholder build commands with actual toolchain
- [ ] Configure C Unity test framework per product
- [ ] Add Slack/email notifications

---

## Support

For issues with this pipeline:
1. Check [Troubleshooting](#troubleshooting) section
2. Review GitHub Actions and Jenkins logs
3. Contact DevOps team
