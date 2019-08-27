
resource "aws_vpc" "vpc-app" {
  cidr_block            = "${var.cidr}"
  enable_dns_hostnames  = true
  enable_dns_support    = true
  assign_generated_ipv6_cidr_block = false
  tags = {
    Name                  = "vpc-app"
    Resource              = "Network"
    Environment           = "dev"
    Service               = "VPC Main"

  }
}


resource "aws_internet_gateway" "gw-app" {
  vpc_id        = "${aws_vpc.vpc-app.id}"
  tags = {
    Name        = "app-internet-gateway"
    Resource    = "Network"
    Environment = "dev"
    Service     = "Gateway"
  }
}
resource "aws_subnet" "subnet-public" {
  count                   = "${length(var.azs)}"
  vpc_id                  = "${aws_vpc.vpc-app.id}"
  cidr_block              = "${cidrsubnet(var.cidr, 8, count.index)}"
  availability_zone       = "${var.azs[count.index]}"
  map_public_ip_on_launch = false
  tags = {
    Name        = "app-subnet-public"
    Resource    = "Network"
    Environment = "dev"
    Service     = "subnet"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.route-public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw-app.id}"
}

resource "aws_route_table" "route-public" {
  vpc_id        = "${aws_vpc.vpc-app.id}"
  tags = {
    Name        = "app-route-public"
    Resource    = "Network"
    Environment = "dev"
    Service     = "Route Public"
  }
}

resource "aws_route_table_association" "route-public" {
  count          = "${length(var.azs)}"
  subnet_id      = "${element(aws_subnet.subnet-public.*.id, count.index)}"
  route_table_id = "${aws_route_table.route-public.id}"
}


# Subnet (private) FrontEnd
resource "aws_subnet" "subnet-private" {
  count                   = "${var.subnet-private == "true" ? length(var.azs) : 0}"
  vpc_id                  = "${aws_vpc.vpc-app.id}"
  cidr_block              = "${cidrsubnet(var.cidr, 8, count.index + length(var.azs))}"
  availability_zone       = "${var.azs[count.index]}"
  map_public_ip_on_launch = false
  tags = {
    Name        = "app-subnet-private"
    Resource    = "Network"
    Environment = "dev"
    Service     = "subnet-private"
  }
}

resource "aws_route_table" "route-private" {
  count         = "${var.subnet-private == "true" ? length(var.azs) : 0}"
  vpc_id        = "${aws_vpc.vpc-app.id}"
  tags = {
    Name        = "app-private"
    Resource    = "Network"
    Environment = "dev"
    Service     = "Route Private"
  }
}

resource "aws_eip" "ipwan" {
  depends_on = ["aws_internet_gateway.gw-app"]
  vpc        = true
}

resource "aws_nat_gateway" "GW-NAT" {
  allocation_id = "${element(aws_eip.ipwan.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.subnet-public.*.id, count.index)}"
  depends_on    = ["aws_internet_gateway.gw-app"]
}

resource "aws_route_table_association" "route-private" {
  count          = "${var.subnet-private == "true" ? length(var.azs) : 0}"
  subnet_id      = "${element(aws_subnet.subnet-private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.route-private.*.id, count.index)}"
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = "${element(aws_route_table.route-private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.GW-NAT.*.id, count.index)}"
  count                  = "${var.subnet-private == "true" ? length(var.azs) : 0}"
  depends_on             = ["aws_nat_gateway.GW-NAT"]
}