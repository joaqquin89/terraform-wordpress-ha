output "return_id_subnet_public1" {
  value = "${element(aws_subnet.subnet_public_create.*.id, 0)}"
}
output "return_id_subnet_public2" {
  value = "${element(aws_subnet.subnet_public_create.*.id, 1)}"
}
output "return_id_subnet_private1" {
  value = "${element(aws_subnet.subnet_private_create.*.id, 0)}"
}
output "return_id_subnet_private2" {
  value = "${element(aws_subnet.subnet_private_create.*.id, 1)}"
}
output "id_vpc" {
  value = "${aws_vpc.default.id}"
}

output "tags" {
    value="${merge(map("Name", format("%s", var.vpc_name)),var.vpc_tags)}"
}