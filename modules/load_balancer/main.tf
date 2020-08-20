
module "loadbalancer-sg" {
  source       = "../security_groups"
  name         = "ClassicLBsg"
  description  = "sg allow incomming traffic in ports 80 and 443"
  tags_sg  =  "${var.tags_loadbancer}"
  vpc_id       = "${var.vpc_id}"
  ingress_cidr = ["0.0.0.0/0"]
  ingress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
    },
    {
      from_port   = 80
      to_port     = 80
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

### Creating ELB
resource "aws_elb" "classic-lb" {
  #count = "${var.type_lb = "classic" ? 1 : 0}"
  name = "${var.elb_name}"
  security_groups = [module.loadbalancer-sg.return_id_sg]
  subnets = var.subnets_id
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 10
    target = "HTTP:${var.server_port}/"
  }
  listener {
    lb_port = 443
    lb_protocol = "https"
    instance_port = var.server_port
    instance_protocol = "http"
    ssl_certificate_id = "arn:aws:acm:us-east-1:258187334316:certificate/4d730962-ee06-40e8-8586-76959edd9514"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = var.server_port
    instance_protocol = "http"
  }

}