variable ami_id               {default="ami-96666ff5"}
variable vpc_id               {}
variable subnet               {}
variable r53_id               {}
variable r53_domain           {}
variable r53_endpoint_suffix  {}
variable region               {}
variable instance_type        {default="t2.micro"}
variable environment          {}
variable key_name             {default="dd-agent"}
variable owner                {default="ddagent@datadog"}
variable project              {default="metrics"}
variable availability_zones   {default=["ap-southeast-2a, ap-southeast-2b", "ap-southeast-2c"]}
variable build                {default="1"}


terraform { backend "s3" { region = "ap-southeast-2" } }

provider "aws" { region = "${var.region}" }


resource "aws_instance" "ec2" {
    vpc_security_group_ids  = ["${aws_security_group.sg.id}"]
    iam_instance_profile    = "${aws_iam_instance_profile.profile.name}"
    instance_type           = "${var.instance_type}"
    key_name                = "${var.key_name}"
    ami                     = "${var.ami_id}"
    subnet_id               = "${var.subnet}"
    user_data               = "${file("user_data.sh")}"

    tags {
        Name        = "${var.project}"
        Environment = "${var.environment}"
        Owner       = "${var.owner}"
        Build       = "${var.build}"
    }
}

resource "aws_security_group" "sg" {
  name        = "${var.project}-${var.environment}"
  description = "Allow SSH, StatsD & all outbound"
  vpc_id      = "${var.vpc_id}"

  ingress { from_port = 22    to_port = 22    protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 8125  to_port = 8125  protocol = "udp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 8126  to_port = 8126  protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0     to_port = 0     protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_iam_instance_profile" "profile" {
  name  = "${var.project}-instance-profile-${var.environment}"
  roles = ["${aws_iam_role.role.name}"]
}

resource "aws_iam_role" "role" {
  name = "${var.project}-role-${var.environment}"
  assume_role_policy = "${file("iam-role.json")}"
}

resource "aws_iam_role_policy" "policy" {
  name   = "${var.project}-policy-${var.environment}"
  role   = "${aws_iam_role.role.id}"
  policy = "${file("iam-policy.json")}"
}

resource "aws_route53_record" "r53" {
   zone_id  = "${var.r53_id}"
   name     = "statsd-${var.r53_endpoint_suffix}.${var.r53_domain}"
   type     = "A"
   ttl      = "900"
   records  = [ "${aws_instance.ec2.private_ip}" ]
}
