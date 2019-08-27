output "vpc_id" {
  value = "${aws_vpc.vpc-app.id}"
}

output "subnet_pub" {
  value = "${aws_subnet.subnet-public.*.id}"
}

output "subnet_priv" {
  value = "${aws_subnet.subnet-private.*.id}"
}


output "cidr-block" {
  value = "${var.cidr}"
}
