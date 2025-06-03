resource "aws_instance" "backend" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.main_subnet_1.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name


  associate_public_ip_address = true  
  tags = {
    Name = "backend-ec2-instance"
  }

   user_data = file("setup_backend.sh")
}
