#!/bin/bash
set -e # Abort on error

echo "User data started" > /var/log/user-data.log

cat <<EOF | sudo tee /etc/users.env
DB_URL=jdbc:postgresql://${db_host}:5432/${db_name}
DB_USER=${db_user}
DB_PASS=${db_pass}
EOF

# Download application JAR
aws s3 cp s3://sgimeno-main-bucket/users-0.0.1-SNAPSHOT.jar /home/ubuntu/users-0.0.1-SNAPSHOT.jar
sudo chown ubuntu:ubuntu /home/ubuntu/users-0.0.1-SNAPSHOT.jar

sudo systemctl start users

echo "User data finished" >> /var/log/user-data.log
