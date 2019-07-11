pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh '/c/OpenModelica/bin/omc -g=MetaModelica CI/BuildModelRecursive.mos'
            }
        }
    }
    post {
        always {
            echo 'Run: DONE'
            archiveArtifacts artifacts: 'CI/workdir/report/*'
        }
        success {
            echo 'Run: SUCCESS'
        }
        failure {
            echo 'Run: FAILED'
        }
        changed {
            echo 'This will run only if the state of the Pipeline has changed'
            echo 'For example, if the Pipeline was previously failing but is now successful'
        }
    }
}