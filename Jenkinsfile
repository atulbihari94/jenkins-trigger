def changedFolders = []
def deployFolders = []
def prId = 'N/A'
def commitMsg = ''
def commonChanged = false

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

                    def productFolders = ['one', 'two']

                    if (changes.split('\n').any { it.startsWith("common/") }) {
                        commonChanged = true
                        deployFolders = productFolders.collect()
                    } else {
                        productFolders.each { folder ->
                            if (changes.split('\n').any { it.startsWith("${folder}/") }) {
                                changedFolders.add(folder)
                            }
                        }
                        deployFolders = changedFolders.collect()
                    }

                    echo "============================================"
                    echo "         DEPLOYMENT PIPELINE"
                    echo "============================================"
                    echo "  PR ID:              #${prId}"
                    echo "  Branch:              ${env.BRANCH_NAME}"
                    echo "  Common changed:      ${commonChanged}"
                    echo "  Changed files:"
                    changes.split('\n').each { echo "    - ${it}" }
                    if (commonChanged) {
                        echo "  >> COMMON folder changed — deploying ALL products"
                    }
                    echo "  Products to deploy:  ${deployFolders.isEmpty() ? 'NONE' : deployFolders.join(', ')}"
                    echo "============================================"
                }
            }
        }

        stage('Deploy product: one') {
            when {
                allOf {
                    expression { return deployFolders.contains('one') }
                    anyOf {
                        branch 'develop'
                        branch 'qa-devops'
                    }
                }
            }
            steps {
                script {
                    def env_name = env.BRANCH_NAME == 'develop' ? 'DEVELOPMENT' : 'QA'
                    def reason = commonChanged ? 'common/ changed — deploying all products' : 'one/ changed'
                    echo "============================================"
                    echo "  DEPLOYING PRODUCT: one"
                    echo "  PR:          #${prId}"
                    echo "  Reason:      ${reason}"
                    echo "  Environment: ${env_name}"
                    echo "  Branch:      ${env.BRANCH_NAME}"
                    echo "============================================"
                    if (env.BRANCH_NAME == 'develop') {
                        // sh 'cd one && ./deploy.sh dev'
                        echo "Deploy command: cd one && ./deploy.sh dev"
                    } else if (env.BRANCH_NAME == 'qa-devops') {
                        // sh 'cd one && ./deploy.sh qa'
                        echo "Deploy command: cd one && ./deploy.sh qa"
                    }
                }
            }
        }

        stage('Deploy product: two') {
            when {
                allOf {
                    expression { return deployFolders.contains('two') }
                    anyOf {
                        branch 'develop'
                        branch 'qa-devops'
                    }
                }
            }
            steps {
                script {
                    def env_name = env.BRANCH_NAME == 'develop' ? 'DEVELOPMENT' : 'QA'
                    def reason = commonChanged ? 'common/ changed — deploying all products' : 'two/ changed'
                    echo "============================================"
                    echo "  DEPLOYING PRODUCT: two"
                    echo "  PR:          #${prId}"
                    echo "  Reason:      ${reason}"
                    echo "  Environment: ${env_name}"
                    echo "  Branch:      ${env.BRANCH_NAME}"
                    echo "============================================"
                    if (env.BRANCH_NAME == 'develop') {
                        // sh 'cd two && ./deploy.sh dev'
                        echo "Deploy command: cd two && ./deploy.sh dev"
                    } else if (env.BRANCH_NAME == 'qa-devops') {
                        // sh 'cd two && ./deploy.sh qa'
                        echo "Deploy command: cd two && ./deploy.sh qa"
                    }
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
            echo "  Products:       ${deployFolders.isEmpty() ? 'none' : deployFolders.join(', ')}"
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
