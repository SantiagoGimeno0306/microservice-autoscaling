packer {
  required_plugins {
    amazon = {
      version = " >= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = formatdate("YYYYMMDD-hhmmss", timestamp())
  systemd = <<-EOT
    [Unit]
    Description=Users Spring Boot Service
    After=network.target

    [Service]
    User=ubuntu
    WorkingDirectory=/home/ubuntu
    ExecStart=/usr/bin/java -jar /home/ubuntu/users-0.0.1-SNAPSHOT.jar
    SuccessExitStatus=143
    Restart=always
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
    EOT
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "learn-packer-linux-aws-redis-${local.timestamp}"
  instance_type = "t2.nano"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
  iam_instance_profile = "ec2_read_s3_profile"
}



build {
  name    = "learn-packer"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
    provisioner "shell" {
    environment_vars = [
        "FOO=hello world",
    ]
  script = "AMI_init.sh"
    }
}
