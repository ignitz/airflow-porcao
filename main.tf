provider "aws" {
  # alias = "us-east-1"


  # access_key = var.access_key
  # secret_key = var.secret_key
  region = "us-east-1"
}

data "aws_caller_identity" "current" {
}

resource "aws_s3_bucket" "airflow-bucket" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.instance_name}"
  acl    = "private"

  tags = {
    Name        = "${data.aws_caller_identity.current.account_id}-${var.instance_name}"
  }

  force_destroy = true
}

resource "aws_instance" "mymachine" {
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t3a.medium"

  tags = {
    Name = var.instance_name
  }

  iam_instance_profile = aws_iam_instance_profile.airflow_profile.name

  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_mymachine.id]
  user_data = templatefile("${path.module}/user_data.sh", {
    HOME     = "/home/ubuntu"
    S3BUCKET = aws_s3_bucket.airflow-bucket.bucket
  })

  subnet_id = var.subnet_id
}

resource "aws_iam_instance_profile" "airflow_profile" {
  name = "${var.instance_name}_profile"
  role = aws_iam_role.airflow.name
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "airflow" {
  name               = "${var.instance_name}-role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json # (not shown)

  inline_policy {
    name = "${var.instance_name}-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetBucketLocation",
            "s3:ListAllMyBuckets"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": ["s3:ListBucket"],
          "Resource": ["arn:aws:s3:::${aws_s3_bucket.airflow-bucket.bucket}"]
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject"
          ],
          "Resource": ["arn:aws:s3:::${aws_s3_bucket.airflow-bucket.bucket}/*"]
        }
      ]
    })
  }
}

resource "aws_security_group" "allow_mymachine" {
  name = "allow_mymachine"

  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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

data "aws_ami" "latest-ubuntu" {
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
