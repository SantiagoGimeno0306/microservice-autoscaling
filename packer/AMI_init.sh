#!/bin/bash
set -e # Abort on error

sudo apt update
sudo apt-get update -y
sudo apt-get install -y unzip curl openjdk-17-jre-headless

# Install AWS CLI
curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
cd /tmp
unzip awscliv2.zip
sudo ./aws/install

# Create systemd service
sudo tee /etc/systemd/system/users.service > /dev/null <<'EOF'
[Unit]
Description=Users Spring Boot Service
After=network.target

[Service]
Type=simple
User=ubuntu
EnvironmentFile=/etc/users.env
WorkingDirectory=/home/ubuntu
ExecStart=/usr/bin/java \
  -jar /home/ubuntu/users-0.0.1-SNAPSHOT.jar
Restart=no
KillSignal=SIGTERM
RestartSec=15
TimeoutStartSec=120
SuccessExitStatus=143

MemoryMax=700M
CPUQuota=50%

[Install]
WantedBy=multi-user.target
EOF

# Enable service
sudo systemctl daemon-reload
sudo systemctl enable users




