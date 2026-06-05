def deployProducts = []
def prId = 'N/A'
def commitMsg = ''
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

        stage('Detect PR & Changes') {
            steps {
                script {
                    commitMsg = sh(
                        script: "git log -1 --pretty=%B",
                        returnStdout: true
                    ).trim()

                    def prMatch = (commitMsg =~ /Merge pull request #(\d+)/)
                    if (prMatch.find()) {
                        prId = prMatch.group(1)
                    } else {
                        def prMatch2 = (commitMsg =~ /#(\d+)/)
                        if (prMatch2.find()) {
                            prId = prMatch2.group(1)
                        }
                    }

                    def changes = sh(
                        script: "git diff --name-only HEAD~1 HEAD || echo ''",
                        returnStdout: true
                    ).trim()

                    def changedFiles = changes.split('\n')

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
                    echo "         DEPLOYMENT PIPELINE"
                    echo "============================================"
                    echo "  PR ID:              #${prId}"
                    echo "  Branch:              ${env.BRANCH_NAME}"
                    echo "  Commit:              ${commitMsg}"
                    echo "  Common changed:      ${commonChanged}"
                    echo "  SDK changed:         ${sdkChanged}"
                    echo "  Changed files:"
                    changedFiles.each { echo "    - ${it}" }
                    if (commonChanged || sdkChanged) {
                        echo "  >> SHARED CODE changed — deploying ALL products"
                    }
                    echo "  Products to deploy:  ${deployProducts.isEmpty() ? 'NONE' : deployProducts.join(', ')}"
                    echo "============================================"
                }
            }
        }

        stage('Deploy ONE') {
            when {
                allOf {
                    expression { return deployProducts.contains('ONE') }
                    anyOf { branch 'develop'; branch 'qa-devops' }
                }
            }
            steps {
                script {
                    def env_name = env.BRANCH_NAME == 'develop' ? 'DEVELOPMENT' : 'QA'
                    def reason = (commonChanged || sdkChanged) ? 'shared code changed — deploying all' : 'products/ONE/ changed'
                    echo "============================================"
                    echo "  DEPLOYING: ONE (FSO)"
                    echo "  PR:          #${prId}"
                    echo "  Reason:      ${reason}"
                    echo "  Environment: ${env_name}"
                    echo "============================================"
                    // sh "cd products/ONE && ./deploy.sh ${env.BRANCH_NAME == 'develop' ? 'dev' : 'qa'}"
                }
            }
        }

        stage('Deploy TIM') {
            when {
                allOf {
                    expression { return deployProducts.contains('TIM') }
                    anyOf { branch 'develop'; branch 'qa-devops' }
                }
            }
            steps {
                script {
                    def env_name = env.BRANCH_NAME == 'develop' ? 'DEVELOPMENT' : 'QA'
                    def reason = (commonChanged || sdkChanged) ? 'shared code changed — deploying all' : 'products/TIM/ changed'
                    echo "============================================"
                    echo "  DEPLOYING: TIM"
                    echo "  PR:          #${prId}"
                    echo "  Reason:      ${reason}"
                    echo "  Environment: ${env_name}"
                    echo "============================================"
                    // sh "cd products/TIM && ./deploy.sh ${env.BRANCH_NAME == 'develop' ? 'dev' : 'qa'}"
                }
            }
        }

        stage('Deploy TIM+') {
            when {
                allOf {
                    expression { return deployProducts.contains('TIM+') }
                    anyOf { branch 'develop'; branch 'qa-devops' }
                }
            }
            steps {
                script {
                    def env_name = env.BRANCH_NAME == 'develop' ? 'DEVELOPMENT' : 'QA'
                    def reason = (commonChanged || sdkChanged) ? 'shared code changed — deploying all' : 'products/TIM+/ changed'
                    echo "============================================"
                    echo "  DEPLOYING: TIM+"
                    echo "  PR:          #${prId}"
                    echo "  Reason:      ${reason}"
                    echo "  Environment: ${env_name}"
                    echo "============================================"
                    // sh "cd 'products/TIM+' && ./deploy.sh ${env.BRANCH_NAME == 'develop' ? 'dev' : 'qa'}"
                }
            }
        }

        stage('Deploy FLO') {
            when {
                allOf {
                    expression { return deployProducts.contains('FLO') }
                    anyOf { branch 'develop'; branch 'qa-devops' }
                }
            }
            steps {
                script {
                    def env_name = env.BRANCH_NAME == 'develop' ? 'DEVELOPMENT' : 'QA'
                    def reason = (commonChanged || sdkChanged) ? 'shared code changed — deploying all' : 'products/FLO/ changed'
                    echo "============================================"
                    echo "  DEPLOYING: FLO"
                    echo "  PR:          #${prId}"
                    echo "  Reason:      ${reason}"
                    echo "  Environment: ${env_name}"
                    echo "============================================"
                    // sh "cd products/FLO && ./deploy.sh ${env.BRANCH_NAME == 'develop' ? 'dev' : 'qa'}"
                }
            }
        }
    }

    post {
        success {
            echo "============================================"
            echo "  DEPLOYMENT COMPLETE"
            echo "  PR:             #${prId}"
            echo "  Branch:         ${env.BRANCH_NAME}"
            echo "  Common changed: ${commonChanged}"
            echo "  SDK changed:    ${sdkChanged}"
            echo "  Products:       ${deployProducts.isEmpty() ? 'none' : deployProducts.join(', ')}"
            echo "============================================"
        }
        failure {
            echo "============================================"
            echo "  DEPLOYMENT FAILED"
            echo "  PR:       #${prId}"
            echo "  Branch:   ${env.BRANCH_NAME}"
            echo "============================================"
        }
    }
}
