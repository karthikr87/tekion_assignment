#!/bin/bash
cd ~/spring-app
echo "Deploying java spring app.."
sudo docker service create --name registry --publish published=5000,target=5000 registry:2
sudo docker-compose build
sudo docker-compose push
sudo docker stack deploy --compose-file docker-compose.yml springMusic
echo "Deployed successfully"
