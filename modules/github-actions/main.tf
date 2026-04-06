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
        abort_incomplete_multipart_upload = { days_after_initiation = 7 }
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
          "ForAnyValue:StringLike" = {
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

resource "awscc_iam_managed_policy" "github_actions_plan" {
  managed_policy_name = "${var.project}-${var.environment}-github-actions-plan"
  policy_document = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      # NOTE: リソースを作成するリージョンとグローバルサービス（CloudFront、IAM、Route 53、etc...）のためのus-east-1以外のリージョンは全て禁止
      {
        "Effect"   = "Deny"
        "Action"   = "*"
        "Resource" = "*"
        "Condition" = {
          "StringNotEquals" = {
            "aws:RequestedRegion" = [
              "ap-northeast-1",
              "ap-northeast-3",
              "us-east-1",
            ]
          }
        }
      },
      # NOTE: tfstateの参照・更新に必要な権限
      {
        "Effect" = "Allow"
        "Action" = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
        ]
        "Resource" = "arn:aws:s3:::${awscc_s3_bucket.state_store.bucket_name}/*"
      },
      # --- cloudformation
      # NOTE: awsccプロバイダーを使用する場合は必須    
      {
        "Effect" = "Allow"
        "Action" = [
          "cloudformation:GetResource",
        ]
        "Resource" = "arn:aws:cloudformation:*:${data.aws_caller_identity.current.account_id}:resource/*"
      },
      # --- iam
      {
        "Effect" = "Allow"
        "Action" = [
          "iam:List*",
        ]
        "Resource" = "*"
      },
      {
        "Effect" = "Allow"
        "Action" = [
          "iam:GetRole",
        ]
        "Resource" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
      },
      {
        "Effect" = "Allow"
        "Action" = [
          "iam:GetInstanceProfile",
        ]
        "Resource" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
      },
      {
        "Effect" = "Allow"
        "Action" = [
          "iam:GetOpenIDConnectProvider",
        ]
        "Resource" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/*"
      },
      {
        "Effect" = "Allow"
        "Action" = [
          "iam:GetPolicy*",
        ]
        "Resource" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/*"
      },
      # --- s3
      {
        "Effect" = "Allow"
        "Action" = [
          "s3:ListAllMyBuckets",
        ]
        "Resource" = "*"
      },
      {
        "Effect" = "Allow"
        "Action" = [
          "s3:GetBucket*",
          "s3:Get*Configuration",
          "s3:ListBucket*",
          "s3:ListTagsForResource",
        ]
        "Resource" = "arn:aws:s3:::*"
      },
    ]
  })
  roles = [awscc_iam_role.github_actions_plan.role_name, ]
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
          "ForAnyValue:StringLike" = {
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

resource "awscc_iam_managed_policy" "github_actions_apply" {
  managed_policy_name = "${var.project}-${var.environment}-github-actions-apply"
  policy_document = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      # NOTE: リソースを作成するリージョンとグローバルサービス（CloudFront、IAM、Route 53、etc...）のためのus-east-1以外のリージョンは全て禁止
      {
        "Effect"   = "Deny"
        "Action"   = "*"
        "Resource" = "*"
        "Condition" = {
          "StringNotEquals" = {
            "aws:RequestedRegion" = [
              "ap-northeast-1",
              "ap-northeast-3",
              "us-east-1",
            ]
          }
        }
      },
      # NOTE: tfstateの参照・更新に必要な権限
      {
        "Effect" = "Allow"
        "Action" = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
        ]
        "Resource" = "arn:aws:s3:::${awscc_s3_bucket.state_store.bucket_name}/*"
      },
      # --- cloudformation
      # NOTE: awsccプロバイダーを使用する場合は必須    
      {
        "Effect" = "Allow"
        "Action" = [
          "cloudformation:CreateResource",
          "cloudformation:DeleteResource",
          "cloudformation:GetResource",
          "cloudformation:GetResourceRequestStatus",
          "cloudformation:UpdateResource",
        ]
        "Resource" = "arn:aws:cloudformation:*:${data.aws_caller_identity.current.account_id}:resource/*"
      },
      # --- iam
      {
        "Effect" = "Allow"
        "Action" = [
          "iam:List*",
          "iam:Tag*",
          "iam:Untag*",
        ]
        "Resource" = "*"
      },
      {
        "Effect" = "Allow"
        "Action" = [
          "iam:AttachRolePolicy",
          "iam:CreateRole",
          "iam:DeleteRole*",
          "iam:DetachRolePolicy",
          "iam:GetRole",
          "iam:PutRole*",
          "iam:UpdateAssumeRolePolicy",
          "iam:UpdateRole*",
        ]
        "Resource" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
      },
      {
        "Effect" = "Allow"
        "Action" = [
          "iam:AddRoleToInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
        ]
        "Resource" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
      },
      {
        "Effect" = "Allow"
        "Action" = [
          "iam:AddClientIDToOpenIDConnectProvider",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:RemoveClientIDFromOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint",
        ]
        "Resource" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/*"
      },
      {
        "Effect" = "Allow"
        "Action" = [
          "iam:CreatePolicy*",
          "iam:DeletePolicy*",
          "iam:GetPolicy*",
          "iam:SetDefaultPolicyVersion",
        ]
        "Resource" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/*"
      },
      # --- s3
      {
        "Effect" = "Allow"
        "Action" = [
          "s3:ListAllMyBuckets",
        ]
        "Resource" = "*"
      },
      {
        "Effect" = "Allow"
        "Action" = [
          "s3:CreateBucket",
          "s3:DeleteBucket*",
          "s3:GetBucket*",
          "s3:Get*Configuration",
          "s3:ListBucket*",
          "s3:ListTagsForResource",
          "s3:PutBucket*",
          "s3:Put*Configuration",
          "s3:TagResource",
          "s3:UntagResource",
        ]
        "Resource" = "arn:aws:s3:::*"
      },
    ]
  })
  roles = [awscc_iam_role.github_actions_apply.role_name, ]
}

resource "github_repository_environment" "github_actions" {
  environment = var.environment
  repository  = "learning-terraform"
}

resource "github_actions_environment_secret" "plan_role_arn" {
  depends_on = [github_repository_environment.github_actions, ]

  environment     = var.environment
  plaintext_value = awscc_iam_role.github_actions_plan.arn
  repository      = "learning-terraform"
  secret_name     = upper(replace("${var.project}_PLAN_ROLE_ARN", "-", "_"))
}

resource "github_actions_environment_secret" "apply_role_arn" {
  depends_on = [github_repository_environment.github_actions, ]

  environment     = var.environment # -> github_repository_environment.github_actions.environment
  plaintext_value = awscc_iam_role.github_actions_apply.arn
  repository      = "learning-terraform"
  secret_name     = upper(replace("${var.project}_APPLY_ROLE_ARN", "-", "_"))
}
