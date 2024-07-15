#create vpc
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "myvpc"
  }
}

#create subnet 1
resource "aws_subnet" "app_sub" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "app_subnet"
  }
}

#create subnet 2
resource "aws_subnet" "web_sub" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "web_subnet"
  }
}

#create subnet 3
resource "aws_subnet" "db_sub" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "db_subnet"
  }
}

#create internet_gateway and attach to vpc
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "igw"
  }
}


#create the public route table
resource "aws_route_table" "pbrtb" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }

  tags = {
    Name = "pbrtb"
  }
}

#Associate with the public subnet
resource "aws_route_table_association" "pb" {
  subnet_id      = aws_subnet.web_sub.id
  route_table_id = aws_route_table.pbrtb.id
}

#create the private route table
resource "aws_route_table" "pvrtb" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "pvrtb"
  }
}

#Associate with the private subnet
resource "aws_route_table_association" "pv" {
  subnet_id      = aws_subnet.app_sub.id
  route_table_id = aws_route_table.pvrtb.id
}

#create security group
resource "aws_security_group" "mysg" {
  name        = "mysg"
  description = "Allow http and ssh inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  tags = {
    Name = "allow_http_and_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = aws_vpc.myvpc.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = aws_vpc.myvpc.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#create s3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "fawzee-tf-ass-bucket"

  tags = {
    Name        = "My Tf bucket"
    Environment = "Dev"
  }
}

resource "aws_key_pair" "tf_kp" {
  key_name   = "tf_kp"
  public_key = file("tf_kp.pub")
}

#create App server
resource "aws_instance" "app" {
  ami                    = "ami-0a0e5d9c7acc336f1"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id              = aws_subnet.app_sub.id
  user_data              = file("userdata.sh")
  key_name               = aws_key_pair.tf_kp.id

  tags = {
    Name = "App Server"
  }
}

#create web server
resource "aws_instance" "web" {
  ami                    = "ami-0a0e5d9c7acc336f1"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id              = aws_subnet.web_sub.id
  user_data              = file("userdata2.sh")
  key_name               = aws_key_pair.tf_kp.id

  tags = {
    Name = "Web Server"
  }
}

resource "aws_db_subnet_group" "db_sub1" {
  name       = "main"
  subnet_ids = [aws_subnet.db_sub.id, aws_subnet.app_sub.id]

  tags = {
    Name = "My DB subnet group"
  }
}

#create rds_msql_db
resource "aws_db_instance" "myrdsdb" {
  allocated_storage    = 20
  identifier           = "my-terraform-rds"
  db_name              = "myrdsdb"
  engine               = "mysql"
  engine_version       = "8.0.35"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "password111"
  skip_final_snapshot  = true
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.db_sub1.id
  availability_zone    = "us-east-1c"
  tags = {
    Name = "My sql db"
  }
}