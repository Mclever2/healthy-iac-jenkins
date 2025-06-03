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
                script {
                    // Verifica si Node.js está instalado
                    try {
                        sh 'node --version'
                        sh 'npm --version'
                    } catch (Exception e) {
                        error "Node.js/npm no está instalado. Por favor instala Node.js en el agente Jenkins"
                    }
                }
            }
        }
        
        stage('Verify Structure') {
            steps {
                script {
                    dir(FRONTEND_DIR) {
                        sh 'ls -la'
                    }
                    dir(PROJECT_DIR) {
                        sh 'ls -la'
                    }
                }
            }
        }
        
        stage('Build Frontend') {
            steps {
                dir(FRONTEND_DIR) {
                    sh 'npm install'
                    sh 'npm run build'
                    archiveArtifacts artifacts: 'dist/**', fingerprint: true
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
        
        stage('Deploy Frontend') {
            steps {
                script {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        def frontend_ips = sh(
                            script: 'aws ec2 describe-instances --filters "Name=tag:Name,Values=Healthy-Frontend" --query "Reservations[].Instances[].PrivateIpAddress" --output text',
                            returnStdout: true
                        ).trim()
                        
                        if (frontend_ips?.trim()) {
                            frontend_ips.split(' ').each { ip ->
                                sh "rsync -avz -e 'ssh -o StrictHostKeyChecking=no' ${FRONTEND_DIR}/dist/ ec2-user@${ip}:/usr/share/nginx/html/"
                                sh "ssh -o StrictHostKeyChecking=no ec2-user@${ip} 'sudo systemctl restart nginx'"
                            }
                        } else {
                            echo "No se encontraron instancias EC2 con el tag Healthy-Frontend"
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            deleteDir() // Alternativa a cleanWs si no tienes el plugin
        }
        failure {
            script {
                echo "Pipeline falló - Revisar en ${env.BUILD_URL}"
                // Comentado hasta que configures correo correctamente
                // mail to: 'caguilari1@upao.edu.pe',
                // subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                // body: "El pipeline ha fallado. Ver detalles: ${env.BUILD_URL}"
            }
        }
    }
}