#!/bin/bash
yum update -y
yum install java-17-amazon-corretto -y

# Puedes cambiar esto según cómo subas tu JAR o usar wget si está en S3
aws s3 cp healthy-api-0.0.1-SNAPSHOT.jar s3://healthy-app-files-1234567890/healthy-api-0.0.1-SNAPSHOT.jar

# Ejecutar la app en segundo plano
nohup java -jar /home/ec2-user/healthy-api-0.0.1-SNAPSHOT.jar > /home/ec2-user/app.log 2>&1 &
