def changedFolders = []

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
                        script: "git diff --name-only HEAD~1 HEAD || echo ''",
                        returnStdout: true
                    ).trim()

                    echo "============================================"
                    echo "Branch: ${env.BRANCH_NAME}"
                    echo "Changed files:\n${changes}"
                    echo "============================================"

                    def folders = ['one', 'two']
                    folders.each { folder ->
                        if (changes.split('\n').any { it.startsWith("${folder}/") }) {
                            changedFolders.add(folder)
                        }
                    }

                    if (changedFolders.isEmpty()) {
                        echo "No project folder changes detected. Skipping build & deploy."
                    } else {
                        echo "Folders with changes: ${changedFolders.join(', ')}"
                    }
                }
            }
        }

        stage('Build folder: one') {
            when {
                expression { return changedFolders.contains('one') }
            }
            steps {
                echo "Building project in folder 'one'..."
                sh 'ls -la one/'
            }
        }

        stage('Build folder: two') {
            when {
                expression { return changedFolders.contains('two') }
            }
            steps {
                echo "Building project in folder 'two'..."
                sh 'ls -la two/'
            }
        }

        stage('Deploy folder: one') {
            when {
                allOf {
                    expression { return changedFolders.contains('one') }
                    anyOf {
                        branch 'develop'
                        branch 'qa-devops'
                    }
                }
            }
            steps {
                script {
                    echo "Deploying folder 'one' from branch: ${env.BRANCH_NAME}"
                    if (env.BRANCH_NAME == 'develop') {
                        echo "Deploying 'one' to DEVELOPMENT environment..."
                        // sh 'cd one && ./deploy.sh dev'
                    } else if (env.BRANCH_NAME == 'qa-devops') {
                        echo "Deploying 'one' to QA environment..."
                        // sh 'cd one && ./deploy.sh qa'
                    }
                }
            }
        }

        stage('Deploy folder: two') {
            when {
                allOf {
                    expression { return changedFolders.contains('two') }
                    anyOf {
                        branch 'develop'
                        branch 'qa-devops'
                    }
                }
            }
            steps {
                script {
                    echo "Deploying folder 'two' from branch: ${env.BRANCH_NAME}"
                    if (env.BRANCH_NAME == 'develop') {
                        echo "Deploying 'two' to DEVELOPMENT environment..."
                        // sh 'cd two && ./deploy.sh dev'
                    } else if (env.BRANCH_NAME == 'qa-devops') {
                        echo "Deploying 'two' to QA environment..."
                        // sh 'cd two && ./deploy.sh qa'
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed for branch: ${env.BRANCH_NAME}"
            echo "Deployed folders: ${changedFolders.isEmpty() ? 'none' : changedFolders.join(', ')}"
        }
        failure {
            echo "Pipeline FAILED for branch: ${env.BRANCH_NAME}"
        }
    }
}
