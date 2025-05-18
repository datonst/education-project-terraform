variable "docker_file_path" {
  description = "Path to the Dockerfile"
  type        = string
}

variable "source_path" {
  description = "Path to the source code directory"
  type        = string
  default     = ""
}

variable "build_args" {
  description = "Build arguments for Docker build"
  type        = map(string)
  default     = {}
}

variable "image_tag" {
  description = "Tag for the Docker image"
  type        = string
  default     = "latest"
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}


variable "domain_name" {
  description = "Domain name"
  type        = string
}
