# Bastion-Host-Task-4
_**In this project, I have launched a Web Server with Bastion Host that allows ssh only.**_

**=>I have create a web portal for our company with all the security as much as possible.**

   **So, I use the WordPress software with a dedicated database server.**

**=>The database should not be accessible from the outside world for security purposes.**

**=>We only need the public WordPress for clients.**


# What is Bastion Host?

_**A bastion host is a special-purpose computer on a network specifically designed and configured to withstand attacks. The computer generally hosts a single application, for example a proxy server, and all other services are removed or limited to reduce the threat to the computer.**_


I am o\performing the following steps:
1.  Write an Infrastructure as code using terraform, which automatically create a VPC.
2.  In that VPC we have to create 2 subnets:
    1.   public  subnet [ Accessible for Public World! ] 
    2.   private subnet [ Restricted for Public World! ]
3. Create a public facing internet gateway for connect our VPC/Network to the internet world and attach this gateway to our VPC.
4. Create  a routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet.
5.  Create a NAT gateway for connect our VPC/Network to the internet world  and attach this gateway to our VPC in the public network
6.  Update the routing table of the private subnet, so that to access the internet it uses the nat gateway created in the public subnet
7.  Launch an ec2 instance which has Wordpress setup already having the security group allowing  port 80 sothat our client can connect to our wordpress site. Also attach the key to instance for further login into it.
8.  Launch an ec2 instance which has MYSQL setup already with security group allowing  port 3306 in private subnet so that our wordpress vm can connect with the same. Also attach the key with the same.

Note: Wordpress instance has to be part of public subnet so that our client can connect our site. 
mysql instance has to be part of private  subnet so that outside world can't connect to it.
Don't forgot to add auto ip assign and auto dns name assignment option to be enabled.

Terraform code for the same to have a proper understanding of workflow of task.

# Let's Start

_**Step-1.**_ 

_First of all, I configure my AWS profile in my local system using cmd. Filling the details & press Enter._

          aws configure --profile Vishnu
                        AWS Access Key ID [****************BXEO]:
                        AWS Secret Access Key [****************Jt5v]:
                        Default region name [ap-south-1]:
                        Default output format [json]:
                        
                        
           
_**Step-2.**_ 

_Next, I create a VPC and Create a public-facing internet gateway to connect my VPC/Network to the internet world and attach this gateway to my VPC._

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
                    
                    
  _**Step-3.**_      
  
_Now, I am creating a routing table for Internet gateway so that instance can connect to the outside world, update and associate it with the public subnet._
_Then, I create the security groups having the inbound rule allowing port 80 so that our client can connect to our WordPress site._
_Finally, I create the security groups having the inbound rule allowing port 3306 in a private subnet so that our wordpress VM can connect with the same._


 _Public Subnet_ [ Accessible for Public World! ] 
 
 
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
                      

 _Private Subnet_ [ Restricted for Public World! ]
 
 
            resource "aws_subnet" "vishnu_private_subnet" {
                        depends_on=[aws_vpc.vishnu_vpc]
                        vpc_id = "${aws_vpc.vishnu_vpc.id}"
                        cidr_block = "192.168.1.0/24"
                        availability_zone = "ap-south-1a"
                        tags = {
                          Name = "vishnu_private_subnet"
                        }
                      }
                      
                      
 _Route table for public subnet_  Create a routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet.


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

_Associating the route table with the public subnet_ 

          resource "aws_route_table_association" "vishnu_rta" {
                      depends_on = [aws_route_table.vishnu_rt]
                      subnet_id = aws_subnet.vishnu_public_subnet.id
                      route_table_id = aws_route_table.vishnu_rt.id
                    }

_Security group for public subnet_

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


                        ingress {
                          description = "allow_mysql"
                          from_port   = 3306
                          to_port     = 3306
                          protocol    = "tcp"
                          cidr_blocks = ["0.0.0.0/0"]
                        }

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

_Security group with Bastion Host _


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

_Bastion host allow to sql with ssh_


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
                      
  _**Step-4.**_                          
_Now, I am creating a NAT gateway to connect our VPC/Network to the internet world and attach this gateway to our VPC in the public network
Update the routing table of the private subnet, so that to access the internet it uses the nat gateway created in the public subnet_


_Creation of EIP _

              resource "aws_eip" "vishnu-ip" {
                vpc              = true
                public_ipv4_pool = "amazon"
              }
              output "new_output" {
                  value=  aws_eip.vishnu-ip
              }
                  
_Creating NAT gateway in public subnet_

              
              resource "aws_nat_gateway" "vishnu_nat_gw" {
                depends_on    = [aws_eip.vishnu-ip]
                allocation_id = aws_eip.vishnu-ip.id
                subnet_id     = aws_subnet.vishnu_public_subnet.id


                tags = {
                  Name = "vishnu_nat_gw"
                }
              }



_Creating the route table for nat gateway (Private Subnet)_


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
              
              
_Associating the route to the private subnet_


              resource "aws_route_table_association" "vp_private_subnet_for_rt_association" {
                depends_on = [aws_route_table.vp_private_subnet_for_rt]
                subnet_id      = aws_subnet.vishnu_private_subnet.id
                route_table_id = aws_route_table.vp_private_subnet_for_rt.id
              }


_**Step-5.**_


_Launching an ec2 instance which has Wordpress setup already having the security group allowing  port 80 sothat our client can connect to our wordpress site. Also attach the key to instance for further login into it._

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
                    
 _**Step-6.**_ 
 
_Launching an ec2 instance which has MYSQL setup already with security group allowing  port 3306 in private subnet so that our wordpress vm can connect with the same. Also attach the key with the same._

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
                  
 _**Step-7.**_    
 
 _Launching an ec2 instance that has a security group allowing ssh in a private subnet so that we can maintain the instance running in the private subnet._
 
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
                                    
  _**Step-8.**_           
  
  _** Now the commands of Terraform to be run:**_
  
            terraform init
            
_The `terraform init` command is used to initialize a working directory containing Terraform configuration files. This is the first command that should be run after writing a new Terraform configuration or cloning an existing one from version control. It is safe to run this command multiple times._


 _**Step-9.**_  
 
            terraform apply -auto-approve
            
 _The `terraform apply` command is used to apply the changes required to reach the desired state of the configuration, or the predetermined set of actions generated by a terraform plan execution plan. If -auto-approve is set for apply and destroy, then the confirmation will not be shown._
 
 # The whole process is shown below in the form of images. 
 
 
 ![init](https://user-images.githubusercontent.com/66829650/92615676-fd055980-f2da-11ea-922a-3ddb70d50828.png)
 
 
 ![2](https://user-images.githubusercontent.com/66829650/92615866-3342d900-f2db-11ea-90fc-d99bcd9a7122.png)


![3](https://user-images.githubusercontent.com/66829650/92616022-5f5e5a00-f2db-11ea-8b56-91277ca9956f.png)


![4](https://user-images.githubusercontent.com/66829650/92616044-64bba480-f2db-11ea-969d-c4f9818ce7c5.png)

![vpc](https://user-images.githubusercontent.com/66829650/92616524-f3c8bc80-f2db-11ea-9388-36c93a57da1b.png)

![subnet](https://user-images.githubusercontent.com/66829650/92616518-f1fef900-f2db-11ea-80c7-40e5ec4821f9.png)

![security](https://user-images.githubusercontent.com/66829650/92616509-ee6b7200-f2db-11ea-94a9-1ea8a839bb77.png)


![nat](https://user-images.githubusercontent.com/66829650/92616402-cc71ef80-f2db-11ea-92d4-869214ebe72e.png)

![EIP](https://user-images.githubusercontent.com/66829650/92616275-a8161300-f2db-11ea-9457-606f83a784fc.png)

![instances](https://user-images.githubusercontent.com/66829650/92616322-b5cb9880-f2db-11ea-894f-3148cc793e45.png)

**Here, the web page...**

![wordpress](https://user-images.githubusercontent.com/66829650/92616528-f4f9e980-f2db-11ea-8a85-282002b1f02d.png)



![thank-you-page-examples](https://user-images.githubusercontent.com/66829650/92617556-08f21b00-f2dd-11ea-99a7-3f0bfe609b73.jpg)


