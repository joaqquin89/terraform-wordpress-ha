output "name" {
  value = "${aws_elb.classic-lb.name}"
}

output "dns_name" {
  value = "${aws_elb.classic-lb.dns_name}"
}