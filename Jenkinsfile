/*
 * ┌─────────────────────────────────────────────────────────────────────────┐
 * │                    STM32 MONOREPO PIPELINE                             │
 * ├─────────────────────────────────────────────────────────────────────────┤
 * │                                                                       │
 * │  This Jenkinsfile calls the STM32MonorepoPipeline shared library      │
 * │  from wf-jenkins-lib. All pipeline logic lives in the library.        │
 * │                                                                       │
 * │  FLOW:                                                                │
 * │  ─────                                                                │
 * │  1. GitHub Actions (.github/workflows/trigger-jenkins.yml):           │
 * │     - Runs on PR merge to develop / qa-devops                         │
 * │     - Auto-discovers products from products/ directory                │
 * │     - Builds only changed products (dynamic matrix)                   │
 * │     - Product changes → triggers Jenkins via API                      │
 * │     - Non-product changes only → shows "Manual Deploy" notice         │
 * │                                                                       │
 * │  2. Jenkins (STM32MonorepoPipeline library):                          │
 * │     - Detects HOW it was triggered (API vs manual)                    │
 * │     - API trigger + product changes → AUTO deploy                     │
 * │     - Manual trigger from Jenkins UI → MANUAL (user selects)          │
 * │     - Non-product changes only → MANUAL (user selects)                │
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
 * │  New folder in products/   → auto-discovered, no code changes needed  │
 * │                                                                       │
 * │  TODO:                                                                │
 * │  ─────                                                                │
 * │  - [ ] Add real Dockerfile for STM32 build environment                │
 * │  - [ ] Configure actual firmware build commands (make/cmake)          │
 * │  - [ ] Set up C Unity test framework per product                      │
 * │  - [ ] Merge wf-jenkins-lib feature/stm32-monorepo to master,        │
 * │        then change @Library below to @Library('wf-jenkins-lib') _     │
 * │                                                                       │
 * └─────────────────────────────────────────────────────────────────────────┘
 */

@Library('wf-jenkins-lib@feature/stm32-monorepo') _

// Register AUTO_DEPLOY so GitHub Actions can pass it on first auto-build
properties([
    parameters([
        booleanParam(
            name: 'AUTO_DEPLOY',
            defaultValue: false,
            description: 'Set by GitHub Actions on PR merge. Do not enable manually.'
        )
    ])
])

STM32MonorepoPipeline()
