output "dnsName" {
  value       = "${module.create_loadbalancer.dns_name}"
}

output "db_access_from_ec2" {
  value = "mysql -h ${aws_db_instance.mysql.address} -P ${aws_db_instance.mysql.port} -u ${var.username} -p${var.password}"
}

output "ns_servers" {
  value = "${aws_route53_zone.selected.name_servers}"
}