#!/usr/bin/env bash

echo "Construindo a imagem Docker da aplicação Java..."

# Seu Dockerfile espera o JAR compilado em target/,
# que foi garantido no script deploy.sh.
# O Docker Compose (V2) cuidará da construção.
sudo docker compose build java-crud-app