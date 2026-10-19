variable "name" {
  description = "Repository name."
  type        = string
}

variable "max_image_count" {
  description = "Number of images to retain."
  type        = number
  default     = 10
}
