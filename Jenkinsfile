pipeline {
    agent any
    
    environment {
        // Rutas relativas al workspace de Jenkins (ya no usamos /var/jenkins_home)
        PROJECT_DIR = "HealthyIAC"
        BACKEND_DIR = "BackEnd"
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
        
        stage('Verify Structure') {
            steps {
                script {
                    // Verifica que las carpetas existan
                    dir(BACKEND_DIR) {
                        sh 'ls -la'
                    }
                    dir(PROJECT_DIR) {
                        sh 'ls -la'
                    }
                }
            }
        }
        
        stage('Build Backend') {
            steps {
                dir(BACKEND_DIR) {
                    sh 'mvn clean package'
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
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
        
        stage('Deploy Backend') {
            steps {
                script {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        def backend_ips = sh(
                            script: 'aws ec2 describe-instances --filters "Name=tag:Name,Values=Healthy-Backend" --query "Reservations[].Instances[].PrivateIpAddress" --output text',
                            returnStdout: true
                        ).trim()
                        
                        if (backend_ips?.trim()) {
                            backend_ips.split(' ').each { ip ->
                                sh "scp -o StrictHostKeyChecking=no ${BACKEND_DIR}/target/*.jar ec2-user@${ip}:/home/ec2-user/app.jar"
                                sh "ssh -o StrictHostKeyChecking=no ec2-user@${ip} 'sudo systemctl restart backend.service'"
                            }
                        } else {
                            echo "No se encontraron instancias EC2 con el tag Healthy-Backend"
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        failure {
            mail to: 'caguilari1@upao.edu.pe',
            subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
            body: "El pipeline ha fallado. Ver detalles: ${env.BUILD_URL}"
        }
    }
}