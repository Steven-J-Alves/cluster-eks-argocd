data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = "${var.tag_env}-devops"
  public_key = var.public_key
}

resource "aws_security_group" "this" {
  name   = "bastion_host"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow ALL egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bastion_host-${var.tag_env}" }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.this.id]
  key_name               = aws_key_pair.this.id
  subnet_id              = element(var.public_subnets, 0)

  root_block_device {
    volume_size           = 30
    volume_type           = "gp2"
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [user_data, vpc_security_group_ids, tags, volume_tags, root_block_device]
  }

  tags = { Name = "${var.tag_env}-bastion_host" }
}

resource "aws_eip" "this" {
  instance = aws_instance.this.id
  tags     = { Name = "bastion_host-elastic-ip" }
}
