################################################################################
# EC2 Instance
################################################################################

resource "aws_instance" "ec2" {
  count = length(var.ec2_ips)

  ami                  = var.ami_id
  instance_type        = var.instance_type[count.index]
  iam_instance_profile = var.iam_role_name != "" ? var.iam_role_name : ""

  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip_address
  vpc_security_group_ids      = concat(var.vpc_security_group_ids)
  private_ip                  = var.ec2_ips[count.index]

  user_data  = var.user_data
  monitoring = var.monitoring

  key_name = var.key_name

  ebs_optimized = var.ebs_optimized

  tags = merge(
    { "Name" = "${var.name}-${count.index}" },
    var.common_tags,
    var.private_tags[count.index]
  )

  volume_tags = var.enable_volume_tags ? merge(
    { "Name" = "${var.name}-${count.index}" },
    var.common_tags, var.private_tags[count.index]
  ) : null

  root_block_device {
    volume_size           = var.volume_size[count.index]
    delete_on_termination = var.delete_on_termination
    encrypted             = var.encrypted_device
  }

  metadata_options {
    http_endpoint               = var.metadata_http_endpoint_enabled ? "enabled" : "disabled"
    instance_metadata_tags      = var.metadata_tags_enabled ? "enabled" : "disabled"
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    http_tokens                 = var.metadata_http_tokens_required ? "required" : "optional"
  }
}

# Attach EBS
resource "aws_ebs_volume" "this" {
  count             = var.ebs_volume_count
  availability_zone = var.availability_zone
  size              = var.ebs_volume_size
  iops              = var.ebs_volume_type
  throughput        = var.root_throughput
  type              = var.ebs_volume_type
  encrypted         = var.ebs_volume_encrypted
  kms_key_id        = var.kms_key_id
}

resource "aws_volume_attachment" "this" {
  count       = var.ebs_volume_count
  device_name = var.ebs_device_name[count.index]
  volume_id   = aws_ebs_volume.this[count.index].id
  instance_id = one(aws_instance.ec2[*].id)
}
