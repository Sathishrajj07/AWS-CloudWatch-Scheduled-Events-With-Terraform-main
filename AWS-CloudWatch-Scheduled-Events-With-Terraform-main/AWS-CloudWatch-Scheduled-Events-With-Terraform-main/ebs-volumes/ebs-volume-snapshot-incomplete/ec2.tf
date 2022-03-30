resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "this" {
  instance_type               = var.instance_type
  ami                         = var.ami
  associate_public_ip_address = false
  tags = {
    Name        = var.name
    Environment = var.environment
    Terraform   = true
  }

  root_block_device {
    delete_on_termination = true
    volume_size           = "8"
  }

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = 8
  }

  iam_instance_profile   = aws_iam_instance_profile.instance.name
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.this.id]
  subnet_id              = data.aws_subnet.subnet.id
  depends_on             = [aws_iam_instance_profile.instance, aws_key_pair.this]

}
