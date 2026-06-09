/*
 * ┌─────────────────────────────────────────────────────────────────────────┐
 * │                    STM32 MONOREPO PIPELINE                             │
 * ├─────────────────────────────────────────────────────────────────────────┤
 * │                                                                       │
 * │  This Jenkinsfile calls the STM32MonorepoPipeline shared library      │
 * │  from wf-jenkins-lib. All pipeline logic lives in the library.        │
 * │                                                                       │
 * │  PARAMETERS (shown in Jenkins UI):                                    │
 * │  ──────────────────────────────────                                   │
 * │  - TARGET_ENV: dev / qa environment                                   │
 * │  - DEPLOY_PRODUCT: Product to deploy (auto-set by GitHub Actions)     │
 * │  - IS_SCAN_ONLY_SRC: SonarQube scan src folder only                   │
 * │                                                                       │
 * │  CONFIGURATION (hardcoded in wf-jenkins-lib):                         │
 * │  ─────────────────────────────────────────────                        │
 * │  - productsDir: 'products' (cannot be changed from Jenkinsfile)       │
 * │                                                                       │
 * │  FLOW:                                                                │
 * │  ─────                                                                │
 * │  1. GitHub Actions (.github/workflows/trigger-jenkins.yml):           │
 * │     - Runs on PR merge to develop / qa-devops                         │
 * │     - Uses GitHub PR Files API to detect changed files                │
 * │     - Builds only changed products (dynamic matrix)                   │
 * │     - Product changes → triggers Jenkins via API                      │
 * │     - Non-product changes only → shows "Manual Deploy" notice         │
 * │                                                                       │
 * │  2. Jenkins (STM32MonorepoPipeline library):                          │
 * │     - API trigger (RemoteCause)      → auto deploy products           │
 * │     - Manual trigger from Jenkins UI → user selects product           │
 * │     - Builds firmware in STM32 Docker container                       │
 * │     - Uploads .bin artifacts to S3                                    │
 * │                                                                       │
 * │  DEPLOYMENT RULES:                                                    │
 * │  ─────────────────                                                    │
 * │  products/ONE/ changed     → auto deploy ONE only                     │
 * │  products/ONE/ + TIM/      → auto deploy ONE and TIM                  │
 * │  products/ONE/ + common/   → auto deploy ONE only                     │
 * │  common/ or sdk/ only      → manual deploy (user picks)               │
 * │  Manual trigger from UI    → manual deploy (user picks)               │
 * │                                                                       │
 * └─────────────────────────────────────────────────────────────────────────┘
 */

@Library('wf-jenkins-lib@feature/stm32-monorepo') _

STM32MonorepoPipeline()
