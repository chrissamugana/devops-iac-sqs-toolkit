variable "queue_names" {
  type        = list(string)
  description = "List of queue names to create with associated DLQs"
}

variable "create_roles" {
  type        = bool
  default     = false
  description = "Whether to create IAM roles for policies"
}
