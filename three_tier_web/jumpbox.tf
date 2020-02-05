resource "aws_instance" "bastion" {
  ami                         = "ami-0620d12a9cf777c87"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.espm_pub_subnet.0.id
  key_name = aws_key_pair.bastion_key.key_name
  user_data = file("install_docker.sh")
  security_groups = [aws_security_group.bastion-sg.id]
}
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
resource "aws_key_pair" "bastion_key" {
  key_name   = "karthik_ssh_key"
  public_key = file("id_rsa.pub")
}
resource "aws_security_group" "bastion-sg" {
  name   = "bastion-security-group"
  vpc_id = aws_vpc.espm_vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
