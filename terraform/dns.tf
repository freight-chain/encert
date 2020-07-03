resource "aws_route53_zone" "regnal" {
  name = "regnal.local"
  vpc {
    vpc_id = "${aws_vpc.regnal.id}"
  }
}

resource "aws_route53_record" "puppet" {
  zone_id = "${aws_route53_zone.regnal.zone_id}"
  name    = "puppet.regnal.local"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.puppet.private_ip}"]
}

resource "aws_route53_record" "ca" {
  zone_id = "${aws_route53_zone.regnal.zone_id}"
  name    = "ca.regnal.local"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.ca.private_ip}"]
}

resource "aws_route53_record" "web" {
  zone_id = "${aws_route53_zone.regnal.zone_id}"
  name    = "web.regnal.local"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.web.private_ip}"]
}

resource "aws_route53_record" "rex" {
  zone_id = "${aws_route53_zone.regnal.zone_id}"
  name    = "rex.regnal.local"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.rex.private_ip}"]
}

resource "aws_route53_record" "voting" {
  zone_id = "${aws_route53_zone.regnal.zone_id}"
  name    = "voting.regnal.local"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.voting.private_ip}"]
}
