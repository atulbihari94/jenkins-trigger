/*
 * STM32 Monorepo Pipeline
 *
 * Uses the shared library STM32MonorepoPipeline from wf-jenkins-lib.
 * All logic (change detection, auto/manual deploy, product discovery)
 * lives in the library.
 *
 * To change the product folder name, update productsDir below.
 * Any subfolder inside that directory is auto-discovered as a product.
 *
 * Deploy logic (handled by the library):
 *   Product folder changes     → auto-deploy affected products
 *   Non-product changes only   → manual deploy (user selects)
 *   No changes                 → skip deployment
 *
 * ────────────────────────────────────────────────────────────────
 * NOTE: Update the @Library version below to match your branch:
 *   - For testing:    @Library('wf-jenkins-lib@feature/stm32-monorepo') _
 *   - For production: @Library('wf-jenkins-lib') _
 * ────────────────────────────────────────────────────────────────
 */

@Library('wf-jenkins-lib@feature/stm32-monorepo') _

STM32MonorepoPipeline(
    productsDir: 'products'
)
