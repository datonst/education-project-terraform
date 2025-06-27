resource "null_resource" "ecr_image" {
  triggers = {
    docker_file = filesha256(var.docker_file_path)

    build_args = jsonencode(var.build_args)
    image_tag  = var.image_tag
  }

  provisioner "local-exec" {
    command = <<EOF
      # Login to AWS ECR
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.ecr_repository_url}
      
      # Build the Docker image
      cd ${dirname(var.docker_file_path)}
      docker build -t ${var.ecr_repository_url}:${var.image_tag} ${join(" ", [for k, v in var.build_args : "--build-arg ${k}=${v}"])}  .
      
      # Push the Docker image
      docker push ${var.ecr_repository_url}:${var.image_tag}
    EOF
  }
}
