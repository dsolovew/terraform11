provider "aws" {
  region = "us-east-2"
}

resource "aws_security_group" "web_server_group" {
  name = "Web Server Security Group"
  description = "Ingress Egress rules for web server"

  dynamic "ingress" {
      for_each = ["80","22"]
      content {
          from_port = ingress.value
          to_port   = ingress.value
          protocol  = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
      }
  }

  egress = [ {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "outbount rule"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  } ]
}

resource "aws_instance" "nginx_server" {
  ami           = "ami-0a91cd140a1fc148a"
  instance_type = "t3.micro"
  key_name      = "ssh-key"
  vpc_security_group_ids = [ "aws_security_group.web_server_group.id" ]
  user_data = templatefile("index.html", {
      f_name = "Denis"
  })

  tags = {
    "Name"  = "Web Server Build by Terraform"
    "Owner" = "Denis Solovyev"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = aws_instance.nginx_server.public_ip
    private_key = file("/root/.ssh/ssh-key-private")
    timeout     = "1m"
  }

  provisioner "file" {
    source      = "index.html"
    destination = "/tmp/index.html"
  }

  provisioner "remote-exec" {
    inline = [
        "sudo apt-get update",
        "sudo apt-get install nginx -y",
        "sudo cp /tmp/index.html /var/www/html/index.html",
        "sudo service nginx restart"
    ]
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name = "ssh-key"
  public_key = file("/root/.ssh/ssh-key-pub.pub")
}