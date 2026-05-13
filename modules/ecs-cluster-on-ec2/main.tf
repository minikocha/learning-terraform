data "aws_region" "current" {}

resource "awscc_ecs_cluster" "this" {
  cluster_name     = "${var.project}-${var.environment}-${var.short_region_code}-ec2"
  cluster_settings = [{ name = "containerInsights", value = var.container_insights }]
  # NOTE: 2026/05/01時点でIPv6のみのVPCでのECS-Execはサポートされていないためコメントアウト
  #configuration = {
  #  execute_command_configuration = {
  #    log_configuration = {
  #      s3_bucket_name        = var.log_store_bucket_name
  #      s3_encryption_enabled = true
  #      s3_key_prefix         = "ecs-exec/"
  #    }
  #    logging = "OVERRIDE"
  #  }
  #}
  tags = var.tags
}

resource "awscc_iam_role" "this" {
  assume_role_policy_document = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" : "Allow"
        "Principal" : { "Service" = "ec2.amazonaws.com" }
        "Action" : "sts:AssumeRole"
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
  ]
  permissions_boundary = "arn:aws:iam::308307205114:policy/security-boundary-policy"
  role_name            = awscc_ecs_cluster.this.cluster_name
  tags                 = var.tags
}

resource "awscc_iam_instance_profile" "this" {
  instance_profile_name = awscc_iam_role.this.role_name
  roles                 = [awscc_iam_role.this.role_name, ]
}

resource "awscc_ec2_security_group" "this" {
  group_description = "container instances in ${awscc_ecs_cluster.this.cluster_name} cluster"
  group_name        = awscc_ecs_cluster.this.cluster_name
  security_group_egress = [
    {
      cidr_ip     = "0.0.0.0/0"
      description = ""
      from_port   = -1
      ip_protocol = -1
      to_port     = -1
    },
    {
      cidr_ipv_6  = "::/0"
      description = ""
      from_port   = -1
      ip_protocol = -1
      to_port     = -1
    },
  ]
  tags   = var.tags
  vpc_id = var.vpc_id
}

resource "awscc_ec2_launch_template" "this" {
  launch_template_data = {
    block_device_mappings = [
      {
        device_name = "/dev/xvda"
        ebs = {
          delete_on_termination = true
          encrypted             = true
          volume_size           = 30
        }
      },
    ]
    iam_instance_profile = { arn = awscc_iam_instance_profile.this.arn }
    image_id             = var.image_id
    instance_type        = var.instance_types[0].instance_type
    maintenance_options  = { auto_recovery = "default" }
    metadata_options = {
      http_endpoint      = "enabled"
      http_protocol_ipv6 = "enabled"
      http_tokens        = "required"
    }
    monitoring = { enabled = true }
    network_interfaces = [
      {
        associate_public_ip_address = false
        delete_on_termination       = true
        device_index                = 0
        groups                      = [awscc_ec2_security_group.this.group_id, ]
      },
    ]
    tag_specifications = [
      { resource_type = "instance", tags = concat(var.tags, [{ key = "Name", value = awscc_ecs_cluster.this.cluster_name }, ]) },
      { resource_type = "network-interface", tags = concat(var.tags, [{ key = "Name", value = awscc_ecs_cluster.this.cluster_name }, ]) },
      { resource_type = "volume", tags = concat(var.tags, [{ key = "Name", value = awscc_ecs_cluster.this.cluster_name }, ]) },
    ]
    user_data = base64encode(templatefile(
      "${path.module}/files/user-data.sh.tftpl",
      {
        cluster_name = awscc_ecs_cluster.this.cluster_name,
        region       = data.aws_region.current.id,
      }
    ))
  }
  launch_template_name = awscc_ecs_cluster.this.cluster_name
  tag_specifications = [
    {
      resource_type = "launch-template",
      tags          = concat(var.tags, [{ key = "Name", value = awscc_ecs_cluster.this.cluster_name }, ])
    },
  ]
}

# NOTE: awsccで作成しようとすると`launch_template.launch_template_id`と`launch_template.launch_template_name`が両方指定されてエラーとなる。
resource "aws_autoscaling_group" "this" {
  capacity_rebalance    = true
  desired_capacity      = var.capacity.default
  desired_capacity_type = "units"
  enabled_metrics       = ["GroupDesiredCapacity", "GroupInServiceCapacity", "GroupPendingCapacity", "GroupTerminatingCapacity", ]
  health_check_type     = "EC2"
  max_instance_lifetime = 86400 * 14 # NOTE: 14 days
  max_size              = var.capacity.max
  min_size              = var.capacity.min
  metrics_granularity   = "1Minute"
  name                  = awscc_ecs_cluster.this.cluster_name
  protect_from_scale_in = true
  termination_policies  = ["Default", ]
  vpc_zone_identifier   = var.subnet_ids

  instance_maintenance_policy {
    max_healthy_percentage = 200
    min_healthy_percentage = 100
  }

  mixed_instances_policy {
    instances_distribution {
      on_demand_allocation_strategy            = "prioritized"
      on_demand_base_capacity                  = var.capacity.on_demand_base_capacity
      on_demand_percentage_above_base_capacity = var.capacity.on_demand_percentage_above_base_capacity
      spot_allocation_strategy                 = "capacity-optimized-prioritized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = awscc_ec2_launch_template.this.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.instance_types

        content {
          instance_type     = override.value.instance_type
          weighted_capacity = tostring(override.value.weighted_capacity)
        }
      }
    }
  }

  dynamic "tag" {
    for_each = concat(var.tags, [{ key = "Name", value = awscc_ecs_cluster.this.cluster_name }, { key = "AmazonECSManaged", value = "" }, ])

    content {
      key                 = tag.value.key
      propagate_at_launch = true
      value               = tag.value.value
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity, ]
  }
}

# NOTE: awsccで作成しようとするとキャパシティプロバイダーが必ず再作成される
resource "aws_ecs_capacity_provider" "this" {
  name = awscc_ecs_cluster.this.cluster_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.this.arn
    managed_draining               = "ENABLED"
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 100
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "awscc_ecs_cluster_capacity_provider_associations" "this" {
  capacity_providers = [aws_ecs_capacity_provider.this.name, ]
  cluster            = awscc_ecs_cluster.this.cluster_name
  default_capacity_provider_strategy = [
    {
      base              = 0
      capacity_provider = aws_ecs_capacity_provider.this.name
      weight            = 1
    },
  ]
}
