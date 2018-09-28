resource "aws_vpc" "devops_vpc" {
    cidr_block = "${var.cidr_base}.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"

    tags {
        Name = "dropwizard-vpc"
    }
}

##############################################
#### Subnets #####
##############################################

resource "aws_subnet" "dropwizard_servers_subnet_a" {

    vpc_id = "${aws_vpc.devops_vpc.id}"
    cidr_block = "${var.cidr_base}.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "eu-west-1a"

    tags {
        Name = "dropwizard-servers-subnet-a"
    }
}

resource "aws_subnet" "dropwizard_servers_subnet_b" {

    vpc_id = "${aws_vpc.devops_vpc.id}"
    cidr_block = "${var.cidr_base}.2.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "eu-west-1b"

    tags {
        Name = "dropwizard-servers-subnet-b"
    }
}

resource "aws_subnet" "dropwizard_servers_subnet_c" {

    vpc_id = "${aws_vpc.devops_vpc.id}"
    cidr_block = "${var.cidr_base}.3.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "eu-west-1c"

    tags {
        Name = "dropwizard-servers-subnet-c"
    }
}

##############################################
####### Internet GW  ####

resource "aws_internet_gateway" "internet_gw" {
    vpc_id = "${aws_vpc.devops_vpc.id}"

    tags {
        Name = "internet_gw"
    }
}


##############################################
# Route Table # 
##############################################

resource "aws_route_table" "devops_routing" {
  vpc_id = "${aws_vpc.devops_vpc.id}"
  depends_on = ["aws_internet_gateway.internet_gw"]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gw.id}"
  }
}



##############################################
# route associations public
##############################################
resource "aws_route_table_association" "devops_subnet_route_association_a" {
    subnet_id = "${aws_subnet.dropwizard_servers_subnet_a.id}"
    route_table_id = "${aws_route_table.devops_routing.id}"
}

resource "aws_route_table_association" "devops_subnet_route_association_b" {
    subnet_id = "${aws_subnet.dropwizard_servers_subnet_b.id}"
    route_table_id = "${aws_route_table.devops_routing.id}"
}

resource "aws_route_table_association" "devops_subnet_route_association_c" {
    subnet_id = "${aws_subnet.dropwizard_servers_subnet_c.id}"
    route_table_id = "${aws_route_table.devops_routing.id}"
}


###############################################
##### ECS Cluster
###############################################

resource "aws_ecs_cluster" "ecs_dropwizard_cluster" {
  name = "ecs_dropwizard_cluster"
}


###############################################
##### ECS EC2 Role
###############################################

resource "aws_iam_role" "ec2-iam-role" {
    name = "ec2-iam-role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

###############################################
##### ECS EC2 Role Policy
##############################################

resource "aws_iam_role_policy" "ecs-ec2-role-policy" {
    name = "ecs-ec2-role-policy"
    role = "${aws_iam_role.ec2-iam-role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "ecs:CreateCluster",
              "ecs:DeregisterContainerInstance",
              "ecs:DiscoverPollEndpoint",
              "ecs:Poll",
              "ecs:RegisterContainerInstance",
              "ecs:StartTelemetrySession",
              "ecs:Submit*",
              "ecs:StartTask",
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF
}

###############################################
##### EC2 Instance Profile
##############################################

resource "aws_iam_instance_profile" "ec2-iam-profile" {
     lifecycle = {
    create_before_destroy = false
  }
    name = "ecs-ec2-profile"
    role = "${aws_iam_role.ec2-iam-role.name}"
}


###############################################
##### EC2 Service Role
##############################################

resource "aws_iam_role" "ecs-service-role" {
    name = "ecs-service-role"
  
    assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_policy_attachment" "ecs-service-attach1" {
    name = "ecs-service-attach1"
    roles = ["${aws_iam_role.ecs-service-role.id}"]
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"  
}

###############################################
##### EC2 Container Definition
##############################################

data "aws_ecs_container_definition" "ecs-dropwizard" {
  task_definition = "${aws_ecs_task_definition.dropwizard_ecs_task_definition.family}"
  container_name  = "dropwizard"

  depends_on = ["aws_ecs_task_definition.dropwizard_ecs_task_definition"]
}

###############################################
##### EC2 Task Definition
##############################################

data "aws_ecr_repository" "dropwizard_ecr" {
  name = "${var.image_name}"
}


resource "aws_ecs_task_definition" "dropwizard_ecs_task_definition" {
  family                = "dropwizard"
# task_role_arn         = "${aws_iam_role.ec2-iam-role.arn}"
  container_definitions = <<DEFINITION
[
  {
    "name": "dropwizard",
    "essential": true,
    "image": "${data.aws_ecr_repository.dropwizard_ecr.repository_url}:latest",
    "cpu": 0,
    "memory": 600,
    "memoryReservation": 400,
    "privileged": false,
    "portMappings": [
      {
        "hostPort": 8080,
        "containerPort": 8080,
        "protocol": "tcp"
      }
    ]
  }
]
DEFINITION
}


##############################################
#  ECS Service #
##############################################

resource "aws_ecs_service" "dropwizard_ecs_service" {
  name            = "dropwizard-ecs-service"
  cluster         = "${aws_ecs_cluster.ecs_dropwizard_cluster.id}"
  desired_count   = 1
  task_definition = "${aws_ecs_task_definition.dropwizard_ecs_task_definition.arn}"
}

##############################################
#  EC2 Instance #
##############################################

resource "aws_instance" "dropwizard-instance" {
  ami           = "ami-a1491ad2"
  instance_type = "t2.small"
  iam_instance_profile        = "${aws_iam_instance_profile.ec2-iam-profile.name}" 
  subnet_id                   = "${aws_subnet.dropwizard_servers_subnet_a.id}"
  vpc_security_group_ids      = ["${aws_security_group.servers_security_group.id}"] 
  associate_public_ip_address = "true"
#  key_name                    = "test"
  user_data                   = "#!/bin/bash\necho 'ECS_CLUSTER=ecs_dropwizard_cluster' > /etc/ecs/ecs.config"

  tags {
    Name = "dropwizard-web"
  }
}


##############################################
#  Security Group for Server Ports #
##############################################
resource "aws_security_group" "servers_security_group" {

name        = "servers-security-group"
description = "dropwizard-servers-firewall"
vpc_id      = "${aws_vpc.devops_vpc.id}"


  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}