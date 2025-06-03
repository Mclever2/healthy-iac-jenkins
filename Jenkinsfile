pipeline {
    agent any
    
    environment {
        PROJECT_DIR = "HealthyIAC"
        FRONTEND_DIR = "FrontEnd"
        AWS_REGION = "us-east-1"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                url: 'https://github.com/Mclever2/healthy-iac-jenkins.git',
                credentialsId: 'github-creds'
            }
        }
        
        stage('Setup Node.js') {
            steps {
                nodejs(nodeJSInstallationName: 'NodeJS 16.x') {
                    sh 'node --version'
                    sh 'npm --version'
                }
            }
        }
        
        stage('Build Frontend') {
            steps {
                nodejs(nodeJSInstallationName: 'NodeJS 16.x') {
                    dir(FRONTEND_DIR) {
                        sh 'npm install'
                        sh 'npm run build'
                        archiveArtifacts artifacts: 'dist/**', fingerprint: true
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir(PROJECT_DIR) {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        sh 'terraform init'
                        sh 'terraform plan'
                    }
                }
            }
        }
        
        stage('Deploy Infrastructure') {
            when {
                branch 'main'
            }
            steps {
                dir(PROJECT_DIR) {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }
    }
    
    post {
        always {
            deleteDir()
        }
        failure {
            script {
                echo "Pipeline falló - Revisar en ${env.BUILD_URL}"
            }
        }
    }
}