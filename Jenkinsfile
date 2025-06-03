pipeline {
    agent any
    
    environment {
        // Asegúrate que estas rutas coincidan con tu estructura
        PROJECT_DIR = "HealthyIAC"  // Contiene los archivos de Terraform
        FRONTEND_DIR = "FrontEnd"  // Contiene la aplicación frontend
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
                    // Verificación explícita de la estructura de directorios
                    def files = findFiles()
                    echo "Contenido del workspace: ${files.collect { it.name }}"
                    
                    // Verificación específica de los directorios clave
                    dir(PROJECT_DIR) {
                        sh 'ls -la'
                        sh 'terraform --version'
                    }
                    dir(FRONTEND_DIR) {
                        sh 'ls -la'
                    }
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
                        // Limpiar estado previo si existe
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
                        // Forzar el despliegue aunque no esté en main (para pruebas)
                        sh 'terraform apply -auto-approve'
                        
                        // Verificar el estado final
                        sh 'terraform state list'
                        sh 'terraform output'
                    }
                }
            }
        }
        
        stage('Desplegar Frontend') {
            steps {
                script {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        // Obtener IPs de las instancias frontend
                        def frontend_ips = sh(
                            script: 'aws ec2 describe-instances --filters "Name=tag:Name,Values=Healthy-Frontend" --query "Reservations[].Instances[].PublicIpAddress" --output text',
                            returnStdout: true
                        ).trim()
                        
                        if (frontend_ips?.trim()) {
                            frontend_ips.split(' ').each { ip ->
                                echo "Desplegando frontend en ${ip}"
                                sh "rsync -avz -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' ${FRONTEND_DIR}/dist/ ec2-user@${ip}:/usr/share/nginx/html/"
                                sh "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@${ip} 'sudo systemctl restart nginx'"
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
            script {
                echo "Pipeline completado - Estado: ${currentBuild.currentResult}"
                echo "URL del Build: ${env.BUILD_URL}"
                
                // Limpieza final
                deleteDir()
            }
        }
        success {
            script {
                // Obtener outputs de Terraform para mostrar URLs
                dir(PROJECT_DIR) {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        def app_url = sh(script: 'terraform output -raw frontend_url || echo "No disponible"', returnStdout: true).trim()
                        echo "✅ Despliegue completado correctamente"
                        echo "🌐 URL de la aplicación: ${app_url}"
                    }
                }
            }
        }
        failure {
            script {
                echo "❌ Pipeline falló - Revisar en ${env.BUILD_URL}"
                
                // Intentar destruir la infraestructura si falla (opcional)
                dir(PROJECT_DIR) {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        sh 'terraform destroy -auto-approve || true'
                    }
                }
            }
        }
    }
}