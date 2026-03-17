#!/bin/bash
set -e # Abort on error

echo "User data started" > /var/log/user-data.log

echo "Updating 1..." >> /var/log/user-data.log
sudo apt update

echo "Updating 2..." >> /var/log/user-data.log
sudo apt-get update -y

echo "Installing docker..." >> /var/log/user-data.log

sudo apt-get install -y docker.io
sudo chown ubuntu  /var/run/docker.sock

echo "Installing unzip..." >> /var/log/user-data.log

sudo apt-get install -y unzip

echo "Installing AWS CLI..." >> /var/log/user-data.log

curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
cd /tmp
unzip awscliv2.zip
sudo ./aws/install

aws ecr get-login-password --region us-east-1 \
| docker login \
--username AWS \
--password-stdin ${account_id}.dkr.ecr.us-east-1.amazonaws.com

docker pull ${account_id}.dkr.ecr.us-east-1.amazonaws.com/users-service:latest

docker run -d \
  --restart always \
  -p 8021:8021 \
  -e DB_URL="jdbc:postgresql://${db_host}/${db_name}" \
  -e DB_USER="${db_user}" \
  -e DB_PASS="${db_pass}" \
  ${account_id}.dkr.ecr.us-east-1.amazonaws.com/users-service:latest

echo "User data finished" >> /var/log/user-data.log

docker exec -it c6232c255d3f env | grep DB