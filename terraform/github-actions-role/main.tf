data "aws_caller_identity" "current" {}

data "tls_certificate" "tfc_certificate" {
  url = "https://token.actions.githubusercontent.com"
}

resource "awscc_iam_oidc_provider" "oidc_provide" {
  client_id_list = ["sts.amazonaws.com"]
  tags = [
    { key = "Environment", value = var.environment },
    { key = "Project", value = var.project },
    { key = "Terragrunt", value = var.terragrunt_path },
  ]
  thumbprint_list = [data.tls_certificate.tfc_certificate.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.tfc_certificate.url
}

# --- IAM role for terragrunt plan
resource "awscc_iam_role" "github_actions_plan_role" {
  assume_role_policy_document = jsonencode({
    "Statement" = [
      {
        "Effect" = "Allow"
        "Principal" = {
          "Federated" = awscc_iam_oidc_provider.oidc_provide.arn
        }
        "Action" = "sts:AssumeRoleWithWebIdentity"
        "Condition" = {
          "StringEquals" = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          "StringLike" = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.owner}/${var.repository}:*"
          }
        }
      },
    ]
    "Version" = "2012-10-17"
  })
  permissions_boundary = "arn:aws:iam::308307205114:policy/security-boundary-policy"
  role_name            = "${var.project}-${var.environment}-github-actions-plan"
  tags = [
    { key = "Environment", value = var.environment },
    { key = "Project", value = var.project },
    { key = "Terragrunt", value = var.terragrunt_path },
  ]
}

resource "awscc_iam_managed_policy" "github_actions_plan_policy" {
  description         = var.terragrunt_path
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
      # --- cloudformation  
      # NOTE: awsccプロバイダーを使用する場合は必須    
      {
        "Effect" = "Allow"
        "Action" = [
          "cloudformation:GetResource",
          #"cloudformation:GetResourceRequestStatus",
        ]
        "Resource" = "arn:aws:cloudformation:*:${data.aws_caller_identity.current.account_id}:resource/*"
      },
      # --- s3
      #{
      #  "Effect" = "Allow"
      #  "Action" = [
      #    "s3:ListAllMyBuckets"
      #  ]
      #  "Resource" = "*"
      #},
      {
        "Effect" = "Allow"
        "Action" = [
          #"s3:GetBucket*",
          "s3:ListBucket*",
        ]
        "Resource" = "arn:aws:s3:::${var.backend_bucket_name}"
      },
      {
        "Effect" = "Allow"
        "Action" = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
        ]
        "Resource" = "arn:aws:s3:::${var.backend_bucket_name}/*" # TODO: ファイル名を指定出来るか検証する
      },
    ]
  })
  roles = [awscc_iam_role.github_actions_plan_role.role_name]
}

resource "github_actions_secret" "plan_role_arn_secret" {
  repository      = var.repository
  secret_name     = "${replace(upper(var.project), "-", "_")}_PLAN_ROLE_ARN"
  plaintext_value = awscc_iam_role.github_actions_plan_role.arn
}

# --- IAM role for terragrunt apply
resource "awscc_iam_role" "github_actions_apply_role" {
  assume_role_policy_document = jsonencode({
    "Statement" = [
      {
        "Effect" = "Allow"
        "Principal" = {
          "Federated" = awscc_iam_oidc_provider.oidc_provide.arn
        }
        "Action" = "sts:AssumeRoleWithWebIdentity"
        "Condition" = {
          "StringEquals" = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          "StringLike" = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.owner}/${var.repository}:*"
          }
        }
      },
    ]
    "Version" = "2012-10-17"
  })
  permissions_boundary = "arn:aws:iam::308307205114:policy/security-boundary-policy"
  role_name            = "${var.project}-${var.environment}-github-actions-apply"
  tags = [
    { key = "Environment", value = var.environment },
    { key = "Project", value = var.project },
    { key = "Terragrunt", value = var.terragrunt_path },
  ]
}

resource "awscc_iam_managed_policy" "github_actions_apply_policy" {
  description         = var.terragrunt_path
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
          "s3:ListAllMyBuckets"
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
      {
        "Effect" = "Allow"
        "Action" = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
        ]
        "Resource" = "arn:aws:s3:::${var.backend_bucket_name}/*"
      },
    ]
  })
  roles = [awscc_iam_role.github_actions_apply_role.role_name]
}

resource "github_actions_secret" "apply_role_arn_secret" {
  repository      = var.repository
  secret_name     = "${replace(upper(var.project), "-", "_")}_APPLY_ROLE_ARN"
  plaintext_value = awscc_iam_role.github_actions_apply_role.arn
}

# NOTE: AWSアカウント（環境）ごとにIAMロールを作成して格納する場合は以下のようにしても良い
#resource "github_repository_environment" "repository_environment" {
#  environment = "${var.project}-${var.environment}"
#  repository  = var.repository
#}
#
#resource "github_actions_environment_secret" "assume_role_arn_secret" {
#  depends_on = [github_repository_environment.repository_environment]
#
#  environment     = "${var.project}-${var.environment}"
#  plaintext_value = awscc_iam_role.github_actions_role.arn
#  repository      = var.repository
#  secret_name     = "${replace(upper(var.project), "-", "_")}_ASSUME_ROLE_ARN"
#}
