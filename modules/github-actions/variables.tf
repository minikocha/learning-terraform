variable "environment" {
  type        = string
  description = ""
  nullable    = false
}

variable "log_store_bucket_name" {
  type        = string
  description = ""
  nullable    = false
}

variable "project" {
  type        = string
  description = ""
  nullable    = false
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
