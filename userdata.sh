#!/bin/bash
sudo apt update -y &&
sudo apt install -y nginx
echo "Hello App server Demo" > /var/www/html/index.html