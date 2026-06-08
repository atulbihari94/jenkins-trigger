/*
 * ┌─────────────────────────────────────────────────────────────────────────┐
 * │                    STM32 MONOREPO PIPELINE                             │
 * ├─────────────────────────────────────────────────────────────────────────┤
 * │                                                                       │
 * │  This Jenkinsfile calls the STM32MonorepoPipeline shared library      │
 * │  from wf-jenkins-lib. All pipeline logic lives in the library.        │
 * │                                                                       │
 * │  WHAT THIS REPO DOES (jenkins-trigger):                               │
 * │  ─────────────────────────────────────                                │
 * │  1. GitHub Actions (.github/workflows/trigger-jenkins.yml):           │
 * │     - Runs on PR merge to develop / qa-devops                         │
 * │     - Auto-discovers product folders from products/ directory         │
 * │     - Builds only the products that have changes (dynamic matrix)     │
 * │     - If product changes exist → triggers Jenkins deployment          │
 * │     - If only non-product changes → shows "Manual Deploy" notice      │
 * │                                                                       │
 * │  2. Jenkinsfile (this file → STM32MonorepoPipeline library):          │
 * │     - Auto-discovers products from products/ directory                │
 * │     - Detects changes via git diff                                    │
 * │     - Product folder changes → AUTO deploys those products            │
 * │     - Non-product changes only → MANUAL deploy (user selects)         │
 * │     - Builds firmware in STM32 Docker container                       │
 * │     - Runs unit tests per product                                     │
 * │     - Uploads .bin artifacts to S3                                    │
 * │     - Runs SCA scan                                                   │
 * │                                                                       │
 * │  WHEN DOES EACH PRODUCT BUILD:                                        │
 * │  ─────────────────────────────                                        │
 * │  products/ONE/ changed     → auto-build & deploy ONE only             │
 * │  products/TIM/ changed     → auto-build & deploy TIM only             │
 * │  products/TIM+/ changed    → auto-build & deploy TIM+ only            │
 * │  products/FLO/ changed     → auto-build & deploy FLO only             │
 * │  products/ONE/ + TIM/      → auto-build & deploy ONE and TIM          │
 * │  products/ONE/ + common/   → auto-build & deploy ONE only             │
 * │  common/ or sdk/ only      → MANUAL deploy (user picks products)      │
 * │  Jenkinsfile or docs/ only → MANUAL deploy (user picks products)      │
 * │  New folder in products/   → auto-discovered, no code changes needed  │
 * │                                                                       │
 * │  TODO (pending):                                                      │
 * │  ────────────────                                                     │
 * │  - [ ] Add real Dockerfile for STM32 build environment                │
 * │  - [ ] Configure actual firmware build commands (make/cmake)          │
 * │  - [ ] Set up C Unity test framework per product                      │
 * │  - [ ] Merge wf-jenkins-lib feature/stm32-monorepo to master,        │
 * │        then change @Library below to @Library('wf-jenkins-lib') _     │
 * │                                                                       │
 * │  CONFIGURATION:                                                       │
 * │  ──────────────                                                       │
 * │  To rename the products folder: change productsDir below.             │
 * │  To add a new product: just create a folder under products/.          │
 * │                                                                       │
 * └─────────────────────────────────────────────────────────────────────────┘
 */

@Library('wf-jenkins-lib@feature/stm32-monorepo') _

STM32MonorepoPipeline(
    productsDir: 'products'
)
