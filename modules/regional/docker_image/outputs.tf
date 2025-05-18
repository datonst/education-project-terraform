output "image_url" {
  description = "URL of the Docker image"
  value       = "${var.ecr_repository_url}:${var.image_tag}"
}

output "image_tag" {
  description = "Tag of the Docker image"
  value       = var.image_tag
}

output "build_completed" {
  description = "Indicates if the build has completed"
  value       = null_resource.ecr_image.id
}
