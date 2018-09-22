
provider "aws" {
  profile = "mytest"
  region  = "${var.region}"
}

data "aws_iam_role" "supernova" {
  name = "AWSServiceRoleForECS"
}

resource "aws_vpc" "supernova" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "supernova" {
  vpc_id = "${aws_vpc.supernova.id}"

  tags {
    Name = "Supernova"
  }
}

resource "aws_subnet" "supernova" {
  vpc_id     = "${aws_vpc.supernova.id}"
  cidr_block = "10.0.0.0/24"

  tags {
    Name = "Supernova"
  }

  depends_on = [
    "aws_internet_gateway.supernova"
  ]
}

resource "aws_lb_target_group" "supernova" {
  name     = "supernova-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.supernova.id}"

  depends_on = [
    "aws_subnet.supernova"
  ]
}

resource "aws_elb" "supernova" {
  name               = "supernova-elb"
  security_groups    = ["${aws_lb_target_group.supernova.id}"]
  subnets            = ["${aws_subnet.supernova.id}"]
  # availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  # access_logs {
  #   bucket        = "foo"
  #   bucket_prefix = "bar"
  #   interval      = 60
  # }

  listener {
    instance_port     = 4000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  # listener {
  #   instance_port      = 8000
  #   instance_protocol  = "http"
  #   lb_port            = 443
  #   lb_protocol        = "https"
  #   ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  # }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:4000/"
    interval            = 30
  }

  # instances                   = ["${aws_instance.foo.id}"]
  # cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "supernova-elb"
  }
}

# resource "aws_ecs_cluster" "supernova" {
#   name = "ecs-supernova"
# }

# resource "aws_ecs_task_definition" "supernova" {
#   family                = "service"
#   container_definitions = "${file("task-definitions/service.json")}"

#   # volume {
#   #   name      = "service-storage"
#   #   host_path = "/ecs/service-storage"
#   # }

#   # placement_constraints {
#   #   type       = "memberOf"
#   #   expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
#   # }
# }

# resource "aws_ecs_service" "supernova" {
#   name            = "supernova"
#   cluster         = "${aws_ecs_cluster.supernova.id}"
#   task_definition = "${aws_ecs_task_definition.supernova.arn}"
#   desired_count   = 3
#   iam_role        = "${data.aws_iam_role.supernova.arn}"
#   # depends_on      = ["aws_iam_role.supernova"]

#   # ordered_placement_strategy {
#   #   type  = "binpack"
#   #   field = "cpu"
#   # }

#   load_balancer {
#     target_group_arn = "${aws_lb_target_group.supernova.arn}"
#     container_name   = "supernova"
#     container_port   = 4000
#   }

#   # placement_constraints {
#   #   type       = "memberOf"
#   #   expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
#   # }
# }

# # resource "aws_db_instance" "default" {
# #   allocated_storage    = 10
# #   storage_type         = "gp2"
# #   engine               = "aurora-postgresql"
# #   instance_class       = "db.t2.micro"
# #   name                 = "blackatom"
# #   username             = "foo"
# #   password             = "foobarbaz"
# # }
