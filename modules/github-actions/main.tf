data "aws_caller_identity" "current" {}

data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

resource "awscc_s3_bucket" "state_store" {
  bucket_encryption = {
    server_side_encryption_configuration = [
      { server_side_encryption_by_default = { sse_algorithm = "AES256" } },
    ]
  }
  bucket_name = "${var.project}-${var.environment}-states"
  lifecycle_configuration = {
    rules = [
      {
        abort_incomplete_multipart_upload = { days_after_initiation = 1 }
        status                            = "Enabled"
      },
    ]
  }
  logging_configuration = {
    destination_bucket_name = var.log_store_bucket_name
    log_file_prefix         = "s3/"
    target_object_key_format = {
      partitioned_prefix = {
        partition_date_source = "EventTime"
      }
    }
  }
  public_access_block_configuration = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
  tags                     = var.tags
  versioning_configuration = { status = "Enabled" }

  lifecycle {
    ignore_changes  = [tags, ] # NOTE: タグの順番で差分を検知するため無視させる
    prevent_destroy = true
  }
}

resource "awscc_iam_oidc_provider" "github_actions" {
  client_id_list  = ["sts.amazonaws.com", ]
  tags            = var.tags
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint, ]
  url             = data.tls_certificate.github_actions.url
}

resource "awscc_iam_role" "github_actions_plan" {
  assume_role_policy_document = jsonencode({
    "Statement" = [
      {
        "Effect" = "Allow"
        "Principal" = {
          "Federated" = awscc_iam_oidc_provider.github_actions.arn
        }
        "Action" = "sts:AssumeRoleWithWebIdentity"
        "Condition" = {
          "StringEquals" = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          "StringLike" = {
            "token.actions.githubusercontent.com:sub" = "repo:minikocha/learning-terraform:*"
          }
        }
      },
    ]
    "Version" = "2012-10-17"
  })
  permissions_boundary = "arn:aws:iam::308307205114:policy/security-boundary-policy"
  role_name            = "${var.project}-${var.environment}-github-actions-plan"
  tags                 = var.tags
}

resource "awscc_iam_role" "github_actions_apply" {
  assume_role_policy_document = jsonencode({
    "Statement" = [
      {
        "Effect" = "Allow"
        "Principal" = {
          "Federated" = awscc_iam_oidc_provider.github_actions.arn
        }
        "Action" = "sts:AssumeRoleWithWebIdentity"
        "Condition" = {
          "StringEquals" = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          "StringLike" = {
            "token.actions.githubusercontent.com:sub" = "repo:minikocha/learning-terraform:*"
          }
        }
      },
    ]
    "Version" = "2012-10-17"
  })
  permissions_boundary = "arn:aws:iam::308307205114:policy/security-boundary-policy"
  role_name            = "${var.project}-${var.environment}-github-actions-apply"
  tags                 = var.tags
}

data "aws_iam_policy_document" "read" {
  # NOTE: リソースを作成するリージョンとグローバルサービス（CloudFront、IAM、Route 53、etc...）のためのus-east-1以外のリージョンは全て禁止
  statement {
    effect    = "Deny"
    actions   = ["*", ]
    resources = ["*", ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values = [
        "ap-northeast-1",
        "ap-northeast-3",
        "us-east-1",
      ]
    }
  }

  # NOTE: tfstateの参照・更新に必要な権限
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
    ]
    resources = ["arn:aws:s3:::${awscc_s3_bucket.state_store.bucket_name}/*/terraform.tfstate*", ] # NOTE: ロック取得時に作成するファイル名は`terraform.tfstate.tflock`
  }

  statement {
    effect = "Allow"
    actions = [
      "autoscaling:Describe*",
      "cloudformation:GetResource", # NOTE: awsccプロバイダーを使用する場合に必須
      "ec2:Describe*",
      "ecs:Describe*",
      "elasticache:Describe*",
      "elasticache:List*",
      "iam:GetInstanceProfile",
      "iam:GetOpenIDConnectProvider",
      "iam:GetPolicy*",
      "iam:GetRole*",
      "iam:List*Policies",
      "iam:ListEntitiesForPolicy",
      "iam:ListInstanceProfiles",
      "iam:ListOpenIDConnectProviders",
      "iam:ListPolicyVersions",
      "iam:ListRoles",
      "logs:Describe*",
      "rds:Describe*",
      "rds:ListTagsForResource",
      "s3:Get*Configuration",
      "s3:GetBucket*",
      "s3:List*",
    ]
    resources = ["*", ]
  }

  lifecycle {
    postcondition {
      condition     = length(self.json) <= 6144 # NOTE: マネージドポリシーのサイズは6144文字が上限
      error_message = ""
    }
  }
}

resource "awscc_iam_managed_policy" "read" {
  managed_policy_name = "${var.project}-${var.environment}-github-actions-read"
  policy_document     = data.aws_iam_policy_document.read.json
  roles = [
    awscc_iam_role.github_actions_plan.role_name,
    awscc_iam_role.github_actions_apply.role_name,
  ]
}

data "aws_iam_policy_document" "write" {
  # NOTE: リソースを作成するリージョンとグローバルサービス（CloudFront、IAM、Route 53、etc...）のためのus-east-1以外のリージョンは全て禁止
  statement {
    effect    = "Deny"
    actions   = ["*", ]
    resources = ["*", ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values = [
        "ap-northeast-1",
        "ap-northeast-3",
        "us-east-1",
      ]
    }
  }

  # NOTE: tfstateの参照・更新に必要な権限
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
    ]
    resources = ["arn:aws:s3:::${awscc_s3_bucket.state_store.bucket_name}/*/terraform.tfstate*", ] # NOTE: ロック取得時に作成するファイル名は`terraform.tfstate.tflock`
  }

  statement {
    effect = "Allow"
    actions = [
      "autoscaling:*MetricsCollection",
      "autoscaling:Create*",
      "autoscaling:Delete*",
      "autoscaling:UpdateAutoScalingGroup",
      "cloudformation:*Resource*",
      "ec2:*Tags",
      "ec2:Associate*",
      "ec2:Attach*",
      "ec2:AuthorizeSecurityGroup*",
      "ec2:Create*",
      "ec2:Delete*",
      "ec2:Detach*",
      "ec2:Disassociate*",
      "ec2:Modify*",
      "ec2:Replace*",
      "ec2:RevokeSecurityGroup*",
      "ec2:UpdateSecurityGroupRuleDescriptions*",
      "ecs:*TaskDefinition",
      "ecs:Create*",
      "ecs:Delete*",
      "ecs:PutClusterCapacityProviders",
      "ecs:TagResource",
      "ecs:UntagResource",
      "ecs:UpdateService",
      "elasticache:AddTagsToResource",
      "elasticache:Create*",
      "elasticache:Delete*",
      "elasticache:Modify*",
      "elasticache:RemoveTagsFromResource",
      "iam:*InstanceProfile",
      "iam:*OpenIDConnectProvider*",
      "iam:AttachRolePolicy",
      "iam:CreatePolicy*",
      "iam:CreateRole",
      "iam:DeletePolicy*",
      "iam:DeleteRole*",
      "iam:DetachRolePolicy",
      "iam:PutRole*",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole*",
      "iam:Untag*",
      "iam:Tag*",
      "logs:CreateLog*",
      "logs:DeleteLog*",
      "logs:PutRetentionPolicy",
      "rds:AddTagsToResource",
      "rds:CreateDB*",
      "rds:DeleteDB*",
      "rds:ModifyDBSubnetGroup",
      "rds:RemoveTagsFromResource",
      "s3:*Bucket*",
      "s3:Put*Configuration",
      "s3:Update*Configuration",
      "s3:TagResource",
      "s3:UntagResource",
      "vpce:AllowMultiRegion",
    ]
    resources = ["*", ]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole", ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-${var.environment}-*", ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:RunInstances", ]
    resources = ["*", ]

    condition {
      test     = "ArnLike"
      variable = "ec2:LaunchTemplate"
      values   = ["arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*", ]
    }
  }

  lifecycle {
    postcondition {
      condition     = length(self.json) <= 6144 # NOTE: マネージドポリシーのサイズは6144文字が上限
      error_message = ""
    }
  }
}

resource "awscc_iam_managed_policy" "write" {
  managed_policy_name = "${var.project}-${var.environment}-github-actions-write"
  policy_document     = data.aws_iam_policy_document.write.json
  roles               = [awscc_iam_role.github_actions_apply.role_name, ]
}

resource "github_repository_environment" "github_actions" {
  environment = var.environment
  repository  = "learning-terraform"
}

resource "github_actions_environment_secret" "plan_role_arn" {
  depends_on = [github_repository_environment.github_actions, ]

  environment = var.environment
  repository  = "learning-terraform"
  secret_name = upper(replace("${var.project}_PLAN_ROLE_ARN", "-", "_"))
  value       = awscc_iam_role.github_actions_plan.arn
}

resource "github_actions_environment_secret" "apply_role_arn" {
  depends_on = [github_repository_environment.github_actions, ]

  environment = var.environment
  repository  = "learning-terraform"
  secret_name = upper(replace("${var.project}_APPLY_ROLE_ARN", "-", "_"))
  value       = awscc_iam_role.github_actions_apply.arn
}
