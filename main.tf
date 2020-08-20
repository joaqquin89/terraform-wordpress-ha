locals {
  public_subnet1 = "192.20.0.0/25"
  public_subnet2 = "192.20.0.128/25"
  private_subnet1 = "192.20.1.0/24"
  private_subnet2 = "192.20.2.0/24"
  instance_type   = "t2.micro"
}

provider "aws" {
  region = "us-east-1"
  access_key = "${var.accesskey}"
  secret_key = "${var.secretkey}"
}

resource "aws_key_pair" "aws-pem" {
  key_name   = "aws-pem"
  public_key = ""
}

module "create_network" {
  source       = "./modules/create_network"
  vpc_cidr  = "192.20.0.0/16"
  cidr_blocks_public = [local.public_subnet1, local.public_subnet2]
  cidr_blocks_private = [local.private_subnet1 ,local.private_subnet2]
  key_name_pem      = "${aws_key_pair.aws-pem.key_name}"
  vpc_tags  =  "${var.tags}"
  vpc_name  = "production-vpc"
  az        = ["us-east-1a","us-east-1b" ]
}


module "create_loadbalancer" {
  source       = "./modules/load_balancer"
  elb_name     = "productionWordpress"
  #type_lb      = "classic"
  server_port  = 80
  subnets_id   = [module.create_network.return_id_subnet_public1,module.create_network.return_id_subnet_public2]
  vpc_id       ="${module.create_network.id_vpc}"
  tags_loadbancer  =  "${var.tags}"
}

module "sg-dmz-web" {
  source       = "./modules/security_groups"
  name         = "sgDmzWeb"
  description  = "sg what allow incomming request "
  tags_sg  =  "${var.tags}"
  vpc_id       = "${module.create_network.id_vpc}"
  ingress_cidr = [local.public_subnet1,local.public_subnet2,local.private_subnet1 ,local.private_subnet2,"0.0.0.0/0"]
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"

    }
  ]
}

module "sg-rds" {
  source       = "./modules/security_groups"
  name         = "sgRds"
  description  = "sg what allow incomming request between frontend and backend "
  tags_sg  =  "${var.tags}"
  vpc_id       = "${module.create_network.id_vpc}"
  ingress_cidr = [local.private_subnet1 , local.private_subnet2 ]
  ingress_rules = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
    }
  ]

   egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
    }
  ]
}

module "sg-asg-aws" {
  source       = "./modules/security_groups"
  name         = "sgInternal"
  description  = "sg what allow communication between  "
  tags_sg  =  "${var.tags}"
  vpc_id       = "${module.create_network.id_vpc}"
  ingress_cidr = ["0.0.0.0/0"]
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
    },
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
    },
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
    }
  ]

   egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
    }
  ]
}

module "create_efs" {
  source       = "./modules/efs"
  efs_name     = "efsWorpress"
  vpc_id       = "${module.create_network.id_vpc}"
  subnet_id    = module.create_network.return_id_subnet_private1
  subnet_sg    = [local.private_subnet1 ,local.private_subnet2]
  tags         = var.tags
}

# Define webserver inside the public subnet
resource "aws_instance" "bastion_host" {
   ami  =  "ami-08bc77a2c7eb2b1da"
   instance_type = local.instance_type
   key_name      = "${aws_key_pair.aws-pem.key_name}"
   subnet_id = "${module.create_network.return_id_subnet_public1}"
   vpc_security_group_ids = [module.sg-dmz-web.return_id_sg]
   associate_public_ip_address = true
   source_dest_check = false
   user_data = <<-EOF
                #!/bin/bash
                sudo apt-add-repository ppa:ansible/ansible
                sudo apt-get update
                sudo apt-get install ansible -y
                sudo sed -i "s/#inventory/inventory/g" /etc/ansible/ansible.cfg
                sudo sed -i "s/#host_key_checking/host_key_checking/g" /etc/ansible/ansible.cfg
                sudo sed -i 's|/etc/ansible/hosts|/etc/ansible/hosts\nprivate_key_file = /home/ubuntu/aws-pem.pem|g' /etc/ansible/ansible.cfg
                EOF

    provisioner "file" {
    source      = "~/.ssh/aws-pem.pem"
    destination = "/home/ubuntu/aws-pem.pem"

    connection {
      user     = "ubuntu"
      private_key = "${file("~/.ssh/aws-pem.pem")}"
      host = "${aws_instance.bastion_host.public_ip}"
    }
  }
}

resource "aws_db_subnet_group" "mysql" {
  name       = "datasubnet"
  subnet_ids = ["${module.create_network.return_id_subnet_private2}", "${module.create_network.return_id_subnet_private1}"]
  tags = "${merge(map("Name", "DatabaseSubnetGroup"), var.tags)}"
}

resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "${var.dbname}"
  username               = "${var.username}"
  password               = "${var.password}"
  parameter_group_name   = "default.mysql5.7"
  vpc_security_group_ids = [module.sg-rds.return_id_sg]
  db_subnet_group_name   = "${aws_db_subnet_group.mysql.name}"
  skip_final_snapshot    = true
}


resource "aws_launch_configuration" "httpd-asg" {
  image_id = "ami-08bc77a2c7eb2b1da"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.aws-pem.key_name}"
  security_groups = [module.sg-asg-aws.return_id_sg]
  user_data = <<-EOF
                #!/bin/bash
                if [[ $(sudo which yum) = *yum*  ]]; then
                        sudo yum install nfs-utils -y
                        # Mount EFS
                        sudo mkdir -p /opt/efs
                        sudo chown root:root /opt/efs
                        IP=$(host ${module.create_efs.id}.efs.us-east-1.amazonaws.com | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
                        sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $IP:/ /opt/efs
                        sudo chmod 777 /opt/efs
                        # Edit fstab so EFS automatically loads on reboot
                        #sudo echo ${module.create_efs.id}.efs.us-east-1.amazonaws.com:/ /efs /efs defaults,_netdev 0 0 >> /etc/fstab
                fi
                if [[ $(sudo which apt) = *apt*  ]]; then
                        sudo apt update -y
                        sudo apt install nfs-common -y
                        # Mount EFS
                        sudo mkdir -p /var/www
                        sudo chown root:root /var/www
                        IP=$(host ${module.create_efs.id}.efs.us-east-1.amazonaws.com | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
                        sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $IP:/ /var/www
                        # Edit fstab so EFS automatically loads on reboot
                        #sudo echo ${module.create_efs.id}.efs.us-east-1.amazonaws.com:/ /efs /efs defaults,_netdev 0 0 >> /etc/fstab
                        sudo chmod -R 777 /var/www
                        #Install Apache
                        sudo apt install apache2 wget software-properties-common -y
                        sudo systemctl enable apache2
                        sudo systemctl start apache2
                fi
                EOF
  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }

  depends_on=[module.create_network, module.create_efs]
}


resource "aws_autoscaling_group" "http-asg" {
  launch_configuration = aws_launch_configuration.httpd-asg.name
  load_balancers    = [module.create_loadbalancer.name]
  vpc_zone_identifier       = [module.create_network.return_id_subnet_private1]
  health_check_type    = "ELB"
  min_size = var.min_size
  max_size = var.max_size
  desired_capacity     = var.min_size
  force_delete         = true

  tag {
    key   = "proyecto"
    value = "marketplace"
    propagate_at_launch = true
  }
  depends_on=[aws_launch_configuration.httpd-asg ,module.create_network]
}

resource "aws_autoscaling_schedule" "night" {
  scheduled_action_name = "night"
  min_size = 0
  max_size = 1
  desired_capacity = 0
  recurrence = "00 20 * * *"
  autoscaling_group_name = "${aws_autoscaling_group.http-asg.name}"
}
resource "aws_autoscaling_schedule" "morning" {
  scheduled_action_name = "morning"
  min_size = 3
  max_size = 3
  desired_capacity = 3
  recurrence = "00 07 * * *"
  autoscaling_group_name = "${aws_autoscaling_group.http-asg.name}"
}


resource "aws_route53_zone" "selected" {
    name = ""
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.selected.zone_id}"
  name    = ""
  type    = "CNAME"
  ttl     = "300"
  records = [module.create_loadbalancer.dns_name]
}