variable "capacity" {
  type = object({
    default                                  = number
    max                                      = number
    min                                      = number
    on_demand_base_capacity                  = number
    on_demand_percentage_above_base_capacity = number
  })
  description = ""
  nullable    = false

  validation {
    condition = (
      (0 <= var.capacity.min && var.capacity.min <= var.capacity.default && var.capacity.default <= var.capacity.max)
      &&
      (0 <= var.capacity.on_demand_base_capacity)
      &&
      (0 <= var.capacity.on_demand_percentage_above_base_capacity && var.capacity.on_demand_percentage_above_base_capacity <= 100)
    )
    error_message = ""
  }
}

variable "container_insights" {
  type        = string
  default     = "enabled"
  description = ""
  nullable    = false

  validation {
    condition     = contains(["enabled", "disabled", ], var.container_insights)
    error_message = ""
  }
}

variable "environment" {
  type        = string
  description = ""
  nullable    = false
}

variable "image_id" {
  type        = string
  description = ""
  nullable    = false
}

variable "instance_types" {
  type        = list(object({ instance_type = string, weighted_capacity = number }))
  description = ""
  nullable    = false

  validation {
    condition     = length(var.instance_types) > 0
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

variable "subnet_ids" {
  type        = list(string)
  description = ""
  nullable    = false

  validation {
    condition     = length(var.subnet_ids) > 0
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

variable "vpc_id" {
  type        = string
  description = ""
  nullable    = false
}
