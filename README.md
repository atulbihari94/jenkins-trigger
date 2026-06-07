# Event Bridge Monorepo - CI/CD Pipeline

## Overview

This is a monorepo containing multiple firmware products (ONE, TIM, TIM+, FLO) with shared code (common/, sdk/). The CI/CD pipeline automatically detects which products have changes and deploys only those products.

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
│   ├── board/
│   ├── drivers/
│   ├── lora/
│   └── platform/
├── sdk/                           # Shared SDK (Drivers, Middlewares, Utilities)
│   ├── Drivers/
│   ├── Middlewares/
│   └── Utilities/
└── docs/
```

## CI/CD Flow

```
Developer merges PR into develop
         │
         ▼
GitHub Actions (trigger-jenkins.yml)
         │
         ├─ Detects changed files
         ├─ Runs build jobs for changed products
         ├─ If builds pass → triggers Jenkins via API
         │
         ▼
Jenkins (Jenkinsfile)
         │
         ├─ Checks out latest code
         ├─ Detects which folders changed (git diff HEAD~1 HEAD)
         ├─ Determines products to deploy:
         │     • common/ or sdk/ changed → deploy ALL products
         │     • products/X/ changed → deploy only X
         │     • Only Jenkinsfile/docs/etc → skip deployment
         │
         ▼
Deploy only affected products
```

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

## Tested Scenarios

All scenarios verified with successful Jenkins builds:

1. **TIM-only change** (Build #6): Changed `products/TIM/app/main.c` → Only TIM deployed
2. **Common folder change** (Build #8): Changed `common/board/inc/board_config.h` → ALL products deployed (ONE, TIM, TIM+, FLO)
3. **Multiple products** (Build #10): Changed `products/ONE/` + `products/FLO/` → Only ONE and FLO deployed
4. **Non-product change** (Build #4): Changed only `Jenkinsfile` → No deployment

## Setup Requirements

### GitHub Actions Secrets

| Secret | Description |
|---|---|
| `JENKINS_URL` | Jenkins server URL (e.g., `https://build.afreespace.com`) |
| `JENKINS_USER` | Jenkins user ID (Azure AD Object ID) |
| `JENKINS_TOKEN` | Jenkins API token (generated from Jenkins user profile → Security → API Token) |

### Jenkins Configuration

- **Job Type**: Multibranch Pipeline
- **Repository**: `https://github.com/atulbihari94/jenkins-trigger.git`
- **Branches to build**: `develop`, `qa-devops`
- **Build Configuration**: Jenkinsfile from SCM

### How GitHub Actions Triggers Jenkins

The GitHub Actions workflow uses authenticated Jenkins REST API calls:

1. Gets a CRUMB (CSRF token) from `/crumbIssuer/api/json`
2. Triggers the branch build via POST to `/job/{JOB_NAME}/job/{BRANCH}/build`
3. Jenkins picks up the latest commit and runs the Jenkinsfile

## Branches

| Branch | Environment | Purpose |
|---|---|---|
| `develop` | Development | Automatic deployment on merge |
| `qa-devops` | QA | Automatic deployment on merge |
| `feature/*` | N/A | Development branches (no auto-deploy) |

## Adding a New Product

1. Create `products/NEW_PRODUCT/` folder with your code
2. Add `'NEW_PRODUCT'` to the `allProducts` list in `Jenkinsfile`
3. Add a new `stage('Deploy NEW_PRODUCT')` block in `Jenkinsfile`
4. Add detection in `.github/workflows/trigger-jenkins.yml`

## Local Development

```bash
# Clone the repository
git clone https://github.com/atulbihari94/jenkins-trigger.git
cd jenkins-trigger

# Create a feature branch
git checkout develop
git checkout -b feature/my-change

# Make changes, commit, push
git add .
git commit -m "Description of change"
git push origin feature/my-change

# Create PR targeting develop → merge triggers deployment
```
