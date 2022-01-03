data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.ubuntu.id
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
}

output "instance_id" {
  value = aws_instance.this.id
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "fleet"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "fleet"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_ssm_association" "inventory" {
  name                = "AWS-GatherSoftwareInventory"
  schedule_expression = "rate(1 day)"
  targets {
    key    = "InstanceIds"
    values = ["*"]
  }

  parameters = {
    "applications"                = "Enabled"
    "awsComponents"               = "Enabled"
    "customInventory"             = "Enabled"
    "instanceDetailedInformation" = "Enabled"
    "networkConfig"               = "Enabled"
    "services"                    = "Enabled"
    "windowsRoles"                = "Enabled"
    "windowsUpdates"              = "Enabled"
  }
}

resource "aws_ssm_association" "cloudwatch_install" {
  name                = "AWS-ConfigureAWSPackage"
  schedule_expression = "rate(1 day)"

  targets {
    key    = "tag:Type"
    values = ["Workload"]
  }

  parameters = {
    "action"           = "Install"
    "installationType" = "In-place update"
    "name"             = "AmazonCloudWatchAgent"
  }
}
