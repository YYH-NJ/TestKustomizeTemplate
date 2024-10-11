provider "aws" {
  region = "{{ $sys.deploymentCell.region }}"
}

module "ec2_instance" {
  source  = "git::https://{{ $sys.deployment.terraformPrivateModuleGitAccessTokens.token }}@github.com/terraform-aws-modules/terraform-aws-ec2-instance"

  instance_type = "t2.micro"
  key_name      = "yuhui-test"          # Replace with your key pair name
}

resource "aws_security_group" "allow_ssh" {
  name_prefix = "allow_ssh"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}