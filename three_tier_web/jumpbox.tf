resource "aws_instance" "bastion" {
  ami                         = "ami-969ab1f6"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.espm_pub_subnet.0.id
  key_name = aws_key_pair.bastion_key.key_name
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
