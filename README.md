# Event Bridge Monorepo - CI/CD Pipeline

## Overview

This is a monorepo containing multiple firmware products (ONE, TIM, TIM+, FLO) with shared code (common/, sdk/). The CI/CD pipeline automatically detects which products have changes and deploys only those products — triggered exclusively when a Pull Request is merged.

## Repository Structure

```
├── Jenkinsfile                    # Pipeline definition (smart deployment)
├── .github/workflows/
│   └── trigger-jenkins.yml        # GitHub Actions: build + trigger Jenkins
├── products/
│   ├── ONE/                       # ONE (FSO) product
│   ├── TIM/                       # TIM product
│   ├── TIM+/                      # TIM+ product
│   └── FLO/                       # FLO product
├── common/                        # Shared code (board, drivers, lora, platform)
├── sdk/                           # Shared SDK (Drivers, Middlewares, Utilities)
└── docs/
```

## CI/CD Flow

1. Developer creates a feature branch from `develop`
2. Makes changes to product code, common code, or SDK
3. Pushes the branch and creates a Pull Request targeting `develop`
4. On PR merge → GitHub Actions triggers:
   - Detects which product folders changed
   - Runs build/test for affected products
   - If all builds pass → triggers Jenkins deployment via API
5. Jenkins runs the Jenkinsfile:
   - Re-detects changed products from the merge commit
   - Deploys only the affected products
   - Sets build display name to show deployed products (e.g., `#15 [ONE+TIM+FLO]`)

## Trigger Configuration

Deployment **ONLY** triggers when a PR is merged. Direct pushes to `develop` are ignored.

**File:** `.github/workflows/trigger-jenkins.yml`

```yaml
on:
  pull_request:
    types: [closed]       # fires when PR is closed
    branches:
      - develop           # target branch for DEV deployment
      - qa-devops         # target branch for QA deployment
```

The `if: github.event.pull_request.merged == true` condition ensures only merged PRs (not closed/rejected PRs) trigger the pipeline.

## Deployment Logic

| Changed Folder | Products Deployed |
|---|---|
| `products/ONE/` | ONE only |
| `products/TIM/` | TIM only |
| `products/TIM+/` | TIM+ only |
| `products/FLO/` | FLO only |
| `products/ONE/` + `products/FLO/` | ONE and FLO |
| `common/` (any file) | ALL (ONE, TIM, TIM+, FLO) |
| `sdk/` (any file) | ALL (ONE, TIM, TIM+, FLO) |
| `Jenkinsfile`, `README.md`, etc. | NONE (no deployment) |

## Verified Test Results

| Build # | Trigger | Changed | Jenkins Display | Result |
|---|---|---|---|---|
| #13 | Merge `feature/bump-one-firmware` | `products/ONE/` | `#13 [ONE]` | SUCCESS |
| #14 | Merge `feature/bump-flo-firmware` | `products/FLO/` | `#14 [FLO]` | SUCCESS |
| #15 | Merge `feature/update-common-drivers` | `common/` | `#15 [ONE+TIM+TIM++FLO]` | SUCCESS |

## Setup Guide (New Repo / New Account)

### Prerequisites

- A GitHub repository with the monorepo structure
- A Jenkins instance with Multibranch Pipeline support
- Jenkins user with API token capability

### Step 1: Jenkins Setup

1. Create a **Multibranch Pipeline** job in Jenkins
2. Configure **Branch Sources** → Git:
   - Repository URL: `https://github.com/<owner>/<repo>.git`
   - Credentials: Add a GitHub PAT with `repo` scope
3. Set **Discover branches** behavior
4. Save and run "Scan Multibranch Pipeline Now"

### Step 2: Generate Jenkins API Token

1. Log in to Jenkins
2. Go to your user profile → **Security** (URL: `/user/<your-id>/security/`)
3. Under **API Token**, click "Add new Token"
4. Generate and copy the token (it won't be shown again)
5. Note your Jenkins user ID (visible in the URL — it may be a UUID for Azure AD users)

### Step 3: GitHub Repository Secrets

Go to: `https://github.com/<owner>/<repo>/settings/secrets/actions`

Add these repository secrets:

| Secret | Value | Example |
|---|---|---|
| `JENKINS_URL` | Your Jenkins base URL | `https://build.afreespace.com` |
| `JENKINS_USER` | Jenkins user ID | `4a7e14af-e679-4e49-8203-a9a027848cd7` |
| `JENKINS_TOKEN` | Jenkins API token | `1129a413c78fedfeaf762e17d471c9bb57` |

### Step 4: Add the Workflow and Jenkinsfile

Copy these files into your repository:
- `.github/workflows/trigger-jenkins.yml` — GitHub Actions workflow
- `Jenkinsfile` — Jenkins pipeline definition

Update the `JOB_NAME` variable in the workflow to match your Jenkins job name.

### Step 5: Configure Branch Protection (Recommended)

In GitHub repo settings → Branches → Add rule for `develop`:
- Require pull request reviews before merging
- Require status checks to pass (select the build jobs)
- This ensures only reviewed, passing code gets deployed

## Branches

| Branch | Environment | Purpose |
|---|---|---|
| `develop` | Development | Auto-deploy on PR merge |
| `qa-devops` | QA | Auto-deploy on PR merge |
| `feature/*` | N/A | Development (no auto-deploy) |

## Adding a New Product

1. Create `products/NEW_PRODUCT/` folder with your code
2. Add `'NEW_PRODUCT'` to the `allProducts` list in `Jenkinsfile`
3. Add a new `stage('Deploy NEW_PRODUCT')` block in `Jenkinsfile`
4. Add a new `build-NEW_PRODUCT` job in `.github/workflows/trigger-jenkins.yml`
5. Add the detection logic in the `Detect changes` step

## Local Development

```bash
git clone https://github.com/<owner>/<repo>.git
cd <repo>
git checkout develop
git checkout -b feature/my-change

# Make changes
git add .
git commit -m "Description of change"
git push origin feature/my-change

# Create PR on GitHub targeting 'develop'
# Merge PR → deployment triggers automatically
```
