#!/bin/bash
cd ~/monitoring
echo "Deploying monitoring for containers.."
sudo docker stack deploy -c docker-compose.yml monitoring
echo "Deployed successfully"
