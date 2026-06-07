def deployProducts = []
def commonChanged = false
def sdkChanged = false
def allProducts = ['ONE', 'TIM', 'TIM+', 'FLO']

pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Detect Changes') {
            steps {
                script {
                    def changes = sh(
                        script: "git diff --name-only HEAD~1 HEAD 2>/dev/null || echo ''",
                        returnStdout: true
                    ).trim()

                    def changedFiles = changes ? changes.split('\n') : []

                    commonChanged = changedFiles.any { it.startsWith("common/") }
                    sdkChanged = changedFiles.any { it.startsWith("sdk/") }

                    if (commonChanged || sdkChanged) {
                        deployProducts = allProducts.collect()
                    } else {
                        allProducts.each { product ->
                            if (changedFiles.any { it.startsWith("products/${product}/") }) {
                                deployProducts.add(product)
                            }
                        }
                    }

                    echo "============================================"
                    echo "  DEPLOYMENT PIPELINE"
                    echo "============================================"
                    echo "  Branch:             ${env.BRANCH_NAME}"
                    echo "  Common changed:     ${commonChanged}"
                    echo "  SDK changed:        ${sdkChanged}"
                    echo "  Changed files:"
                    changedFiles.each { echo "    - ${it}" }
                    if (commonChanged || sdkChanged) {
                        echo "  >> SHARED CODE changed - deploying ALL products"
                    }
                    echo "  Products to deploy: ${deployProducts.isEmpty() ? 'NONE' : deployProducts.join(', ')}"
                    echo "============================================"

                    // Set build display name with product info
                    def productLabel = deployProducts.isEmpty() ? 'no-deploy' : deployProducts.join('+')
                    currentBuild.displayName = "#${env.BUILD_NUMBER} [${productLabel}]"
                    currentBuild.description = "Products: ${deployProducts.isEmpty() ? 'NONE' : deployProducts.join(', ')}"
                }
            }
        }

        stage('Deploy ONE') {
            when {
                expression { return deployProducts.contains('ONE') }
            }
            steps {
                echo "============================================"
                echo "  DEPLOYING: ONE (FSO)"
                echo "  Environment: ${env.BRANCH_NAME == 'develop' ? 'DEVELOPMENT' : 'QA'}"
                echo "============================================"
                // sh "cd products/ONE && ./deploy.sh ${env.BRANCH_NAME == 'develop' ? 'dev' : 'qa'}"
            }
        }

        stage('Deploy TIM') {
            when {
                expression { return deployProducts.contains('TIM') }
            }
            steps {
                echo "============================================"
                echo "  DEPLOYING: TIM"
                echo "  Environment: ${env.BRANCH_NAME == 'develop' ? 'DEVELOPMENT' : 'QA'}"
                echo "============================================"
                // sh "cd products/TIM && ./deploy.sh ${env.BRANCH_NAME == 'develop' ? 'dev' : 'qa'}"
            }
        }

        stage('Deploy TIM+') {
            when {
                expression { return deployProducts.contains('TIM+') }
            }
            steps {
                echo "============================================"
                echo "  DEPLOYING: TIM+"
                echo "  Environment: ${env.BRANCH_NAME == 'develop' ? 'DEVELOPMENT' : 'QA'}"
                echo "============================================"
                // sh "cd 'products/TIM+' && ./deploy.sh ${env.BRANCH_NAME == 'develop' ? 'dev' : 'qa'}"
            }
        }

        stage('Deploy FLO') {
            when {
                expression { return deployProducts.contains('FLO') }
            }
            steps {
                echo "============================================"
                echo "  DEPLOYING: FLO"
                echo "  Environment: ${env.BRANCH_NAME == 'develop' ? 'DEVELOPMENT' : 'QA'}"
                echo "============================================"
                // sh "cd products/FLO && ./deploy.sh ${env.BRANCH_NAME == 'develop' ? 'dev' : 'qa'}"
            }
        }

        stage('No Changes') {
            when {
                expression { return deployProducts.isEmpty() }
            }
            steps {
                echo "============================================"
                echo "  NO PRODUCT CHANGES DETECTED"
                echo "  Only non-product files were modified."
                echo "  Skipping deployment."
                echo "============================================"
            }
        }
    }

    post {
        success {
            echo "============================================"
            echo "  PIPELINE COMPLETE"
            echo "  Branch:         ${env.BRANCH_NAME}"
            echo "  Common changed: ${commonChanged}"
            echo "  SDK changed:    ${sdkChanged}"
            echo "  Deployed:       ${deployProducts.isEmpty() ? 'NONE' : deployProducts.join(', ')}"
            echo "============================================"
        }
        failure {
            echo "============================================"
            echo "  PIPELINE FAILED"
            echo "  Branch: ${env.BRANCH_NAME}"
            echo "============================================"
        }
    }
}
