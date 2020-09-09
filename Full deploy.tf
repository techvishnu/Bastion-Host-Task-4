resource "aws_vpc" "vishnu_vpc" {
            cidr_block = "192.168.0.0/16"
            instance_tenancy = "default"
            enable_dns_hostnames = true
            tags = {
              Name = "vishnu_vpc"
            }
          }


resource "aws_internet_gateway" "vishnu_gw" {
            vpc_id = "${aws_vpc.vishnu_vpc.id}"
            tags = {
              Name = "vishnu_gw"
            }
          }


// Public Subnet
resource "aws_subnet" "vishnu_public_subnet" {
            depends_on=[aws_vpc.vishnu_vpc]
            vpc_id = "${aws_vpc.vishnu_vpc.id}"
            cidr_block = "192.168.0.0/24"
            availability_zone = "ap-south-1a"
            map_public_ip_on_launch = "true"
            tags = {
              Name = "vishnu_public_subnet"
            }
          }

// Private Subnet
resource "aws_subnet" "vishnu_private_subnet" {
            depends_on=[aws_vpc.vishnu_vpc]
            vpc_id = "${aws_vpc.vishnu_vpc.id}"
            cidr_block = "192.168.1.0/24"
            availability_zone = "ap-south-1a"
            tags = {
              Name = "vishnu_private_subnet"
            }
          }



// Route table for public subnet

resource "aws_route_table" "vishnu_rt" {
            depends_on=[aws_subnet.vishnu_public_subnet]
            vpc_id = "${aws_vpc.vishnu_vpc.id}"

            route {
              cidr_block = "0.0.0.0/0"
              gateway_id = "${aws_internet_gateway.vishnu_gw.id}"
            }

            tags = {
              Name = "vishnu_public_subnet_rt"
            }
          }

// Associating the route table with the public subnet

resource "aws_route_table_association" "vishnu_rta" {
            depends_on = [aws_route_table.vishnu_rt]
            subnet_id = aws_subnet.vishnu_public_subnet.id
            route_table_id = aws_route_table.vishnu_rt.id
          }

// Security group for public subnet

resource "aws_security_group" "vishnu_public_sg" {
            depends_on=[aws_subnet.vishnu_public_subnet]
            name        = "HTTP_SSH_PING"
            description = "It allows HTTP SSH PING inbound traffic"
            vpc_id      = "${aws_vpc.vishnu_vpc.id}"


            ingress {
            
              description = "allow http from VPC"
              from_port   = 80
              to_port     = 80
              protocol    = "tcp"
              cidr_blocks = [ "0.0.0.0/0"]

            }


              ingress {
                description = "allow ssh from VPC"
                from_port   = 22
                to_port     = 22
                protocol    = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
              }


              ingress {
                description = "allow icmp from VPC"
                from_port   = 0
                to_port     = 0
                protocol    = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
              }


              # ingress {
              #   description = "allow_mysql"
              #   from_port   = 3306
              #   to_port     = 3306
              #   protocol    = "tcp"
              #   cidr_blocks = ["0.0.0.0/0"]
              # }

              egress {
                from_port   = 0
                to_port     = 0
                protocol    = "-1"
                cidr_blocks = ["0.0.0.0/0"]
              }


              tags = {
              Name = "HTTP_SSH_PING"
            }
          }

// Security group with Bastion Host 


resource "aws_security_group" "bastion_ssh_only" {
  depends_on=[aws_subnet.vishnu_public_subnet]
  name        = "bastion_ssh_only"
  description = "It allows bastion ssh inbound traffic"
  vpc_id      =  aws_vpc.vishnu_vpc.id



ingress {
    description = "allow bastion with ssh only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks =  ["::/0"]
  }


egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks =  ["::/0"]
  }


  tags = {
    Name = "bastion_ssh_only"
  }
}


resource "aws_security_group" "vishnu_sg_private" {
            depends_on=[aws_subnet.vishnu_public_subnet]
            name        = "mysql_web"
            description = "It allows only mysql"
            vpc_id      = "${aws_vpc.vishnu_vpc.id}"
          
            ingress {
            
              description = "allow_mysql"
              from_port   = 3306
              to_port     = 3306
              protocol    = "tcp"
              security_groups = [aws_security_group.vishnu_public_sg.id]
            }


            ingress {
              description = "allow_icmp"
              from_port   = -1
              to_port     = -1
              protocol    = "icmp"
              security_groups = [aws_security_group.vishnu_public_sg.id]
              }

            egress {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
            ipv6_cidr_blocks =  ["::/0"]
          }
          
          
          tags = {

              Name = "mysql_web"
            }
          }

//  Bastion host allow to sql with ssh


resource "aws_security_group" "bastion_host_sql_only" {
  depends_on=[aws_subnet.vishnu_public_subnet]
  name        = "bastion_with_ssh_only"
  description = "It allows bastion host with ssh only"
  vpc_id      =  aws_vpc.vishnu_vpc.id



ingress {
    description = "bastion host ssh only "
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups=[aws_security_group.bastion_ssh_only.id]

}


egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "bastion_with_ssh_only"
  }
}


// Creation of EIP 

resource "aws_eip" "vishnu-ip" {


  vpc              = true
  public_ipv4_pool = "amazon"
}


output "new_output" {


    value=  aws_eip.vishnu-ip

// Creating NAT gateway in public subnet

}
resource "aws_nat_gateway" "vishnu_nat_gw" {
  depends_on    = [aws_eip.vishnu-ip]
  allocation_id = aws_eip.vishnu-ip.id
  subnet_id     = aws_subnet.vishnu_public_subnet.id


  tags = {
    Name = "vishnu_nat_gw"
  }
}



// Creating the route table for nat gateway (Private Subnet)


resource "aws_route_table" "vp_private_subnet_for_rt" {
  depends_on = [aws_nat_gateway.vishnu_nat_gw]
  vpc_id = aws_vpc.vishnu_vpc.id







  route {
    cidr_block = "0.0.0.0/0"

    gateway_id = aws_nat_gateway.vishnu_nat_gw.id
  }





  tags = {
    Name = "vp_private_subnet_for_rt"
  }
}



//  associating the route to the private subnet


resource "aws_route_table_association" "vp_private_subnet_for_rt_association" {
  depends_on = [aws_route_table.vp_private_subnet_for_rt]
  subnet_id      = aws_subnet.vishnu_private_subnet.id
  route_table_id = aws_route_table.vp_private_subnet_for_rt.id
}

// Creating wordpress i.e. Public Web Instance
resource "aws_instance" "wordpress" {
        
        ami           = "ami-ff82f990"
        instance_type = "t2.micro"
        //key_name      =  "newkey"
        subnet_id     = "${aws_subnet.vishnu_public_subnet.id}"
        security_groups = ["${aws_security_group.vishnu_public_sg.id}"]
        //associate_public_ip_address = true
        availability_zone = "ap-south-1a"


        tags = {
          Name = "vishnu_wordpress"
          }
        } 

//  Creating Bastion Host 


resource "aws_instance" "host_bastion_only" {
  depends_on=[aws_security_group.bastion_ssh_only]
  ami             =  "ami-08706cb5f68222d09"
  instance_type   =  "t2.micro"
  key_name        =  "task4"
  subnet_id= aws_subnet.vishnu_public_subnet.id 
  vpc_security_group_ids=[aws_security_group.bastion_ssh_only.id]
  




  tags = {
    Name = "host_bastion"
  }
}

// Creating My SQL i.e. private instance
resource "aws_instance" "sql" {
                    depends_on      = [aws_security_group.bastion_host_sql_only,aws_security_group.bastion_ssh_only]
                    ami             =  "ami-08706cb5f68222d09"
                    instance_type   =  "t2.micro"
                    key_name        =  "newkey"
                    subnet_id     = "${aws_subnet.vishnu_private_subnet.id}"
                    availability_zone = "ap-south-1a"
                    security_groups = [aws_security_group.bastion_host_sql_only.id,aws_security_group.bastion_ssh_only.id]
                    
                    tags = {
                      Name = "vishnu_sql"
                      }
                    }              