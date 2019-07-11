pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'cd CI'
                sh '/c/OpenModelica/bin/omc -g=MetaModelica CI/BuildModelRecursive.mos'
            }
        }
    }
    post {
        always {
            echo 'Run: DONE'
            archiveArtifacts artifacts: 'CI/workdir/BuildModelRecursive.html', onlyIfSuccessful: true
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