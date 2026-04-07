variable "cidr_block" {
  type        = string
  description = ""
  nullable    = false

  validation {
    condition     = can(regex("^172\\.(1[6-9]|2[0-9]|3[0-1])\\.0\\.0/16$", var.cidr_block)) # NOTE: クラスBのネットワーク(172.16.0.0/16 - 172.31.0.0/16)のみ許可.
    error_message = ""
  }
}

variable "environment" {
  type        = string
  description = ""
  nullable    = false
}

variable "log_store_bucket_arn" {
  type        = string
  description = ""
  nullable    = false

  validation {
    condition     = can(regex("^arn:aws:s3:::[a-z0-9][a-z0-9.-]*$", var.log_store_bucket_arn))
    error_message = ""
  }
}

variable "project" {
  type        = string
  description = ""
  nullable    = false
}

variable "short_region_code" {
  type        = string
  description = "Abbreviated region code(e.g. ap-northeast-1 -> apne1)"
  nullable    = false

  validation {
    condition     = contains(["apne1", "apne3", "use1", ], var.short_region_code)
    error_message = ""
  }
}

variable "tags" {
  type        = list(object({ key = string, value = string }))
  description = ""
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = ""
  }
}
