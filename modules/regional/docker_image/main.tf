resource "null_resource" "ecr_image" {
  triggers = {
    docker_file = filesha256(var.docker_file_path)
    app_files   = var.source_path != "" ? sha256(join("", [for f in fileset(var.source_path, "**") : filesha256("${var.source_path}/${f}")])) : ""
    build_args  = jsonencode(var.build_args)
    image_tag   = var.image_tag
  }

  provisioner "local-exec" {
    command = <<EOF
      # Login to AWS ECR
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.ecr_repository_url}
      
      # Build the Docker image
      cd ${dirname(var.docker_file_path)}
      docker build -t ${var.ecr_repository_url}:${var.image_tag} ${join(" ", [for k, v in var.build_args : "--build-arg ${k}=${v}"])} --build-arg DOMAIN_NAME=${var.domain_name} .
      
      # Push the Docker image
      docker push ${var.ecr_repository_url}:${var.image_tag}
    EOF
  }
}
