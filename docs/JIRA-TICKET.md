# JIRA Ticket — STM32 Monorepo CI/CD Pipeline

## Ticket: Implement Smart CI/CD for STM32 Firmware Monorepo

### Title

**Implement selective build & deploy pipeline for STM32 firmware monorepo with auto/manual deployment routing**

### Type

Story

### Priority

High

### Epic

DevOps / CI/CD Infrastructure

---

### Description

Implement a CI/CD pipeline for the STM32 firmware monorepo that automatically detects which product folders have changed and deploys only those products. The pipeline should support both automatic and manual deployment modes based on what files changed.

#### Background

We have a monorepo containing multiple STM32 firmware products (ONE, TIM, TIM+, FLO) along with shared code (`common/`, `sdk/`). Currently there is no smart change detection — deployments are either all-or-nothing. We need a pipeline that:

1. **Auto-discovers** product folders (no hardcoding product names)
2. **Detects changes** at the folder level using git diff
3. **Auto-deploys** only the specific products that changed
4. **Requires manual approval** when only shared code changes (no product folder changes)
5. **Never auto-deploys all products** just because shared code changed

#### Solution Implemented

**Three components were built:**

| Component | Location | Purpose |
|---|---|---|
| GitHub Actions Workflow | `.github/workflows/trigger-jenkins.yml` | Build & trigger Jenkins on PR merge |
| Jenkins Shared Library | `wf-jenkins-lib/vars/STM32MonorepoPipeline.groovy` | Reusable pipeline with change detection |
| Jenkinsfile | `Jenkinsfile` | 3-line call to the shared library |

#### Deployment Rules

| Changed Files | Action | Mode |
|---|---|---|
| `products/ONE/` changed | Build & deploy ONE only | Automatic |
| `products/ONE/` + `products/TIM/` changed | Build & deploy ONE and TIM | Automatic |
| `products/ONE/` + `common/` changed | Build & deploy ONE only | Automatic |
| `common/` only changed | Pipeline pauses, user selects products | Manual |
| `sdk/` only changed | Pipeline pauses, user selects products | Manual |
| `Jenkinsfile` or `docs/` changed | Pipeline pauses, user selects products | Manual |
| New folder added to `products/` | Auto-discovered, no pipeline changes | — |

#### Key Design Decisions

- **No hardcoded product names**: Products are discovered at runtime from `products/` subdirectories
- **Dynamic matrix builds**: GitHub Actions uses `fromJson()` matrix strategy — no per-product job definitions
- **Shared library pattern**: Pipeline logic in `wf-jenkins-lib` follows the same pattern as `STM32IDEPipeline`, `NodeJSCloudfrontCDKPipeline`, etc.
- **products/ is the only auto-deploy trigger**: Any file outside `products/` is treated as non-product and requires manual deployment

---

### Acceptance Criteria

- [x] Products are auto-discovered from `products/` directory — no hardcoded names
- [x] Changes inside `products/<name>/` auto-deploy only that product
- [x] Changes outside `products/` (common, sdk, docs, Jenkinsfile) trigger manual deploy
- [x] Mixed changes (product + non-product) auto-deploy only the changed products
- [x] GitHub Actions uses dynamic matrix for parallel product builds
- [x] Jenkins shared library (`STM32MonorepoPipeline`) follows existing library patterns
- [x] Jenkinsfile is minimal (calls shared library)
- [x] `DEPLOY_ALL` logic removed — never auto-deploys all products
- [x] Product folder name is configurable (`productsDir` parameter)
- [x] Pipeline tested across 23 scenarios covering all change combinations
- [ ] **TODO:** Real Dockerfile for STM32 build environment
- [ ] **TODO:** Actual firmware build commands (make/cmake)
- [ ] **TODO:** C Unity test framework configuration per product
- [ ] **TODO:** Merge `feature/stm32-monorepo` branch in `wf-jenkins-lib` to master

---

### Test Results

**23/23 scenarios passed** covering:

| Category | Tests | Result |
|---|---|---|
| Single product changes | 3 | Pass |
| Multiple product changes | 3 | Pass |
| Product + non-product mixed | 4 | Pass |
| Non-product only (manual deploy) | 8 | Pass |
| Real branch simulations | 5 | Pass |

---

### Files Changed

#### `jenkins-trigger` repo (GitHub)

| File | Lines | Change |
|---|---|---|
| `Jenkinsfile` | 55 → 3 lines of code | Replaced inline pipeline with shared library call |
| `.github/workflows/trigger-jenkins.yml` | 242 → 165 lines | Removed hardcoded products, dynamic matrix, removed DEPLOY_ALL |
| `README.md` | Full rewrite | Updated documentation |
| `docs/JIRA-TICKET.md` | New | This file |

#### `wf-jenkins-lib` repo (CodeCommit)

| File | Lines | Change |
|---|---|---|
| `vars/STM32MonorepoPipeline.groovy` | 435 lines | New shared library pipeline |

### Branch: `feature/stm32-monorepo` (wf-jenkins-lib)

---

### Dependencies

- `wf-jenkins-lib` shared library must be available in Jenkins Global Library configuration
- Jenkins Multibranch Pipeline job configured for the repo
- GitHub secrets: `JENKINS_URL`, `JENKINS_USER`, `JENKINS_TOKEN`

### Estimated Effort

| Task | Status | Effort |
|---|---|---|
| Pipeline design & implementation | Done | 1 day |
| Shared library (STM32MonorepoPipeline) | Done | 0.5 day |
| Testing (23 scenarios) | Done | 0.5 day |
| Dockerfile for STM32 build | TODO | 0.5 day |
| Real firmware build integration | TODO | 1 day |
| C Unity test setup | TODO | 0.5 day |
| Library merge & production deploy | TODO | 0.5 day |
| **Total** | | **~4.5 days** |
