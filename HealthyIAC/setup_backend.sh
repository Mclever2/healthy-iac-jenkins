#!/bin/bash

# Actualizar paquetes e instalar Java 17
yum update -y
yum install java-17-amazon-corretto -y

# Crear directorio para la app
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

# Descargar el JAR desde S3 (asegúrate que la instancia EC2 tenga permisos)
aws s3 cp s3://healthy-app-files-1234567890/healthy-api-0.0.1-SNAPSHOT.jar .

# Dar permisos de ejecución por si acaso
chmod +x healthy-api-0.0.1-SNAPSHOT.jar

# Ejecutar en segundo plano
nohup java -jar healthy-api-0.0.1-SNAPSHOT.jar > /home/ec2-user/app.log 2>&1 &
