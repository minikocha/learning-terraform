variable "environment" {
  type        = string
  description = ""
  nullable    = false
}

variable "project" {
  type        = string
  description = ""
  nullable    = false
}

variable "route_table_id" {
  type        = string
  description = ""
  nullable    = false

  #validation {
  #  condition     = can(regex("^rtb-[a-z0-9][a-z0-9.-]*$", var.route_table_id))
  #  error_message = ""
  #}
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

variable "subnet_id" {
  type        = string
  description = ""
  nullable    = false

  #validation {
  #  condition     = can(regex("^subnet-[a-z0-9][a-z0-9.-]*$", var.subnet_id))
  #  error_message = ""
  #}
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
