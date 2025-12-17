# Run these 2 commands before running terraform apply
# ssh-keygen -t rsa -b 4096 -f cloud-laptop
# chmod 400 cloud-laptop


# ---------------------------------------------------------
# 1. Data Sources (Get AZs and AMI)
# ---------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "debian_12" {
  most_recent = true
  owners      = ["136693071363"] 

  filter {
    name   = "name"
    values = ["debian-12-arm64-*"] 
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_instances" "cloud_laptop_live" {
  instance_tags = {
    Name = "Cloud Laptop ASG"
  }

  instance_state_names = ["running", "pending"]
}

data "aws_instance" "cloud_laptop_details" {
  # Only run this if we actually found an instance ID in the previous step
  count = length(data.aws_instances.cloud_laptop_live.ids) > 0 ? 1 : 0

  instance_id = data.aws_instances.cloud_laptop_live.ids[0]
}

resource "aws_key_pair" "laptop_key" {
  key_name   = "cloud-laptop-key"
  public_key = file(var.public_key_path)
}

# ---------------------------------------------------------
# 2. Network (VPC & Dynamic Subnets)
# ---------------------------------------------------------
resource "aws_vpc" "cloud_laptop_vpc" {
  cidr_block         = var.vpc_cidr
  enable_dns_support = true # Allow instance to look up domains instead of raw IP

  tags = {
    Name = "cloud-laptop-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.cloud_laptop_vpc.id

  tags = {
    Name = "cloud-laptop-igw"
  }
}

# DYNAMIC SUBNETS: Creates one subnet for every AZ found in the region
resource "aws_subnet" "main" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.cloud_laptop_vpc.id
  
  # Auto-increment CIDR (10.0.1.0, 10.0.2.0, etc.)
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true # Allow instance to get public IP automatically

  tags = {
    Name = "cloud-laptop-subnet-${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.cloud_laptop_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "cloud-laptop-rt"
  }
}

# Associate ALL subnets with the Route Table
resource "aws_route_table_association" "main_assoc" {
  count          = length(aws_subnet.main)
  subnet_id      = aws_subnet.main[count.index].id
  route_table_id = aws_route_table.main_rt.id
}

# ---------------------------------------------------------
# 3. Security Group
# ---------------------------------------------------------
resource "aws_security_group" "main_sg" {
  name        = "cloud-laptop-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.cloud_laptop_vpc.id

  tags = {
    Name = "cloud-laptop-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.main_sg.id
  cidr_ipv4         = "0.0.0.0/0" 
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.main_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---------------------------------------------------------
# 4. Compute (Launch Template & ASG)
# ---------------------------------------------------------
resource "aws_launch_template" "cloud_laptop_lt" {
  name_prefix   = "cloud-laptop-lt-"
  image_id      = data.aws_ami.debian_12.id
  key_name      = aws_key_pair.laptop_key.key_name

  vpc_security_group_ids = [aws_security_group.main_sg.id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.root_volume_size
      volume_type = "gp3"
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y git
    cd /home/admin
    git clone https://github.com/alanpham2k2/Cloud-Laptop.git
    chown -R admin:admin /home/admin/Cloud-Laptop
    su - admin -c "cd /home/admin/Cloud-Laptop && ./setup.sh"
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Cloud Laptop (Spot)"
    }
  }
}

resource "aws_autoscaling_group" "cloud_laptop_asg" {
  name                = "cloud-laptop-asg"
  
  # Point to ALL subnets created above
  vpc_zone_identifier = aws_subnet.main[*].id
  
  desired_capacity    = 0
  min_size            = 0
  max_size            = 1

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.cloud_laptop_lt.id
      }
      
      # ASG ignores the instance type set in your Launch Template
      # Only pick from the instance types explicitly listed in `override` blocks
      override {
        instance_requirements {
          memory_mib {
            min = 4096 # 4GB RAM
          }
          vcpu_count {
            min = 2 #
          }
          
          burstable_performance = "included"
          
          cpu_manufacturers = ["amazon-web-services"]
          # Exclude expensive GPU types
          excluded_instance_types = ["g*", "p*", "inf*"]
        }
      }
    }

    instances_distribution {
      # Minimum number of On-Demand instances that will always be running
      on_demand_base_capacity                  = 0
      # Remaining instances after the base capacity is full
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
  }

  tag {
    key                 = "Name"
    value               = "Cloud Laptop ASG"
    propagate_at_launch = true
  }
}
