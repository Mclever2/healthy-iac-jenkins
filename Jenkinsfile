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
        
        stage('Verificar Estructura') {
            steps {
                script {
                    // Verificación alternativa sin findFiles
                    sh 'ls -la'
                    sh "ls -la ${PROJECT_DIR} || true"
                    sh "ls -la ${FRONTEND_DIR} || true"
                }
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
        
        stage('Preparar Terraform') {
            steps {
                dir(PROJECT_DIR) {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        sh 'rm -rf .terraform* || true'
                        sh 'terraform init'
                    }
                }
            }
        }
        
        stage('Validar Terraform') {
            steps {
                dir(PROJECT_DIR) {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        sh 'terraform validate'
                        sh 'terraform plan -detailed-exitcode'
                    }
                }
            }
        }
        
        stage('Desplegar Infraestructura') {
            steps {
                dir(PROJECT_DIR) {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        sh 'terraform apply -auto-approve'
                        sh 'terraform output'
                    }
                }
            }
        }
        
        stage('Desplegar Frontend') {
            steps {
                script {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        // Obtener IPs usando AWS CLI
                        def frontend_ips = sh(
                            script: 'aws ec2 describe-instances --filters "Name=tag:Name,Values=Healthy-Frontend" --query "Reservations[].Instances[].PublicIpAddress" --output text',
                            returnStdout: true
                        ).trim()
                        
                        if (frontend_ips?.trim()) {
                            frontend_ips.split(' ').each { ip ->
                                sh """
                                    rsync -avz -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' \
                                    ${FRONTEND_DIR}/dist/ ec2-user@${ip}:/usr/share/nginx/html/
                                    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                                    ec2-user@${ip} 'sudo systemctl restart nginx'
                                """
                            }
                        } else {
                            error "No se encontraron instancias EC2 con el tag Healthy-Frontend"
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            deleteDir()
        }
        success {
            script {
                echo "✅ Pipeline completado exitosamente"
                // Obtener URL de salida de Terraform si existe
                dir(PROJECT_DIR) {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        def app_url = sh(
                            script: 'terraform output -raw frontend_url || echo "URL-no-disponible"',
                            returnStdout: true
                        ).trim()
                        echo "🌐 URL de la aplicación: ${app_url}"
                    }
                }
            }
        }
        failure {
            script {
                echo "❌ Pipeline falló - Revisar los logs"
                // Limpieza opcional en caso de fallo
                dir(PROJECT_DIR) {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        sh 'terraform destroy -auto-approve || true'
                    }
                }
            }
        }
    }
}