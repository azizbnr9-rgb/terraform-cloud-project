data "aws_region" "current" {}

data "aws_ssm_parameter" "ami" {
  name = var.ami_ssm_parameter
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.name_prefix}-lt-"
  description   = "Launch Template des serveurs web ${var.name_prefix}"
  image_id      = data.aws_ssm_parameter.ami.value
  instance_type = var.instance_type

  vpc_security_group_ids = [var.app_sg_id]

  iam_instance_profile {
    name = var.instance_profile_name
  }

  # IMDSv2 obligatoire (protection contre le vol d'identifiants par SSRF)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = var.detailed_monitoring
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
    environment    = var.environment
    app_port       = var.app_port
    db_address     = var.db_address
    db_name        = var.db_name
    db_port        = var.db_port
    db_secret_arn  = var.db_secret_arn
    s3_bucket_name = var.s3_bucket_name
    aws_region     = data.aws_region.current.name
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name_prefix}-web" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = "${var.name_prefix}-web-root" })
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.name_prefix}-asg"
  vpc_zone_identifier = var.app_subnet_ids
  target_group_arns   = [var.target_group_arn]

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 120
  default_instance_warmup   = 60

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  # Remplacement progressif des instances quand le Launch Template change
  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupTotalInstances",
  ]

  dynamic "tag" {
    for_each = merge(var.tags, { Name = "${var.name_prefix}-web" })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    # Permet de modifier temporairement la capacité (test d'Auto Scaling)
    # sans que Terraform ne l'annule au prochain apply.
    ignore_changes = [desired_capacity]
  }
}

# Mise à l'échelle automatique : maintien de la CPU moyenne autour de la cible
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.name_prefix}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target_value
  }
}
