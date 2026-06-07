pipeline {
    agent any

    stages {
        stage('Hello') {
            steps {
                echo 'Hello World from Jenkins!'
                echo "Branch: ${env.BRANCH_NAME}"
                echo "Build: ${env.BUILD_NUMBER}"
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
    }
}
