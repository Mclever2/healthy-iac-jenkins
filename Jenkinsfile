pipeline {
    agent any

    environment {
        PROJECT_DIR = "HealthyIAC"
        FRONTEND_DIR = "FrontEnd"
        AWS_REGION = "us-east-1"
        TF_PLAN_FILE = "tfplan.out"
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
                    sh """
                        echo 'Verificando estructura del proyecto...'
                        ls -la
                        ls -la ${PROJECT_DIR} || true
                        ls -la ${FRONTEND_DIR} || true
                    """
                }
            }
        }

        stage('Setup Node.js') {
            steps {
                nodejs(nodeJSInstallationName: 'NodeJS 16.x') {
                    sh 'node --version && npm --version'
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
                        sh '''
                            echo 'Inicializando Terraform...'
                            rm -rf .terraform* || true
                            terraform init
                        '''
                    }
                }
            }
        }

        stage('Análisis de Seguridad - Checkov') {
            steps {
                dir(PROJECT_DIR) {
                    script {
                        sh '''
                            echo "🔍 Ejecutando análisis de seguridad con Checkov (Docker)..."

                            docker run --rm \
                              -v "${PWD}:/app" \
                              --workdir /app \
                              bridgecrew/checkov \
                              --directory /app \
                              -o junitxml \
                              --output-file-path results.xml || true
                        '''
                        junit allowEmptyResults: true, testResults: 'results.xml'
                    }
                }
            }
        }

        stage('Validar Terraform') {
            steps {
                dir(PROJECT_DIR) {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        sh """
                            echo 'Validando configuración de Terraform...'
                            terraform validate

                            terraform plan -out=${TF_PLAN_FILE}
                        """
                    }
                }
            }
        }

        stage('Desplegar Infraestructura') {
            steps {
                dir(PROJECT_DIR) {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        sh """
                            echo 'Aplicando cambios de infraestructura...'
                            terraform apply -auto-approve ${TF_PLAN_FILE}

                            echo 'Salidas de Terraform:'
                            terraform output
                        """
                    }
                }
            }
        }

        stage('Desplegar Frontend') {
            steps {
                script {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        def frontend_ips = sh(
                            script: 'aws ec2 describe-instances --filters "Name=tag:Name,Values=Healthy-Frontend" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].PublicIpAddress" --output text',
                            returnStdout: true
                        ).trim()

                        if (frontend_ips?.trim()) {
                            echo "Instancias frontend encontradas: ${frontend_ips}"
                            frontend_ips.split(' ').each { ip ->
                                sh """
                                    echo "Desplegando en ${ip}..."
                                    rsync -avz -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' \
                                    ${FRONTEND_DIR}/dist/ ec2-user@${ip}:/usr/share/nginx/html/

                                    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                                    ec2-user@${ip} 'sudo systemctl restart nginx'
                                """
                            }
                        } else {
                            echo "Advertencia: No se encontraron instancias EC2 con el tag Healthy-Frontend"
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            deleteDir()
            script {
                echo "Pipeline completado - Estado: ${currentBuild.currentResult}"
            }
        }
        success {
            script {
                echo "✅ ¡Despliegue completado con éxito!"
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
                echo "❌ Pipeline falló - Revisar los logs completos"
                dir(PROJECT_DIR) {
                    withAWS(credentials: 'aws-healthy-creds', region: AWS_REGION) {
                        sh 'terraform destroy -auto-approve || true'
                    }
                }
            }
        }
    }
}
