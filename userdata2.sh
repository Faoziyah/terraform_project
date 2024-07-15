#!/bin/bash
sudo apt update -y &&
sudo apt install -y nginx
echo "Hello web server Demo" > /var/www/html/index.html