resource "aws_instance" "puppet" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  depends_on = [
    aws_key_pair.terraform,
    aws_vpc.regnal,
    aws_subnet.regnal,
    aws_vpc_dhcp_options.regnal,
    aws_vpc_dhcp_options_association.regnal,
    aws_security_group.regnal,
    aws_internet_gateway.regnal,
    aws_route_table.regnal,
    aws_route_table_association.regnal,
  ]

  # VPC
  subnet_id              = "${aws_subnet.regnal.id}"
  vpc_security_group_ids = ["${aws_security_group.regnal.id}"]

  # Required to use remote-exec
  associate_public_ip_address = true

  # Set hostname using cloud-init
  user_data = "#cloud-config\nhostname: puppet\nfqdn: puppet.regnal.local"

  tags = {
    Name = "regnal-puppet"
  }

  # Install puppet-master
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.puppet.public_ip
      private_key = "${file("~/.ssh/terraform")}"
    }

    inline = [
      "set -x",
      # apt-get update fails often, sometimes writing the cache
      "sudo apt-get update || sudo apt-get update", "sudo apt-get update",
      "sudo apt-get -y install puppet-master puppet-module-puppetlabs-stdlib",
      "sudo puppet config set --section master autosign true",
      "sudo systemctl restart puppet-master",
      "sudo chown ubuntu:ubuntu /etc/puppet/code",
    ]
  }

  # Copy puppet/code folder to /etc/puppet/code
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.puppet.public_ip
      private_key = "${file("~/.ssh/terraform")}"
    }

    source      = "conf/puppet/code/environments"
    destination = "/etc/puppet/code"
  }
}

resource "aws_instance" "ca" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  depends_on = [
    aws_instance.puppet,
    aws_route53_record.puppet,
  ]

  # VPC
  subnet_id              = "${aws_subnet.regnal.id}"
  vpc_security_group_ids = ["${aws_security_group.regnal.id}"]

  # Required to use remote-exec
  associate_public_ip_address = true

  # Set hostname using cloud-init
  user_data = "#cloud-config\nhostname: ca\nfqdn: ca.regnal.local"

  tags = {
    Name = "regnal-ca"
  }

  # Provision with puppet
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.ca.public_ip
      private_key = "${file("~/.ssh/terraform")}"
    }

    inline = [
      "set -x",
      # apt-get update fails often, sometimes writing the cache
      "sudo apt-get update || sudo apt-get update", "sudo apt-get update",
      "sudo apt-get -y install puppet",
      # Run once and daemonize, it will refresh every 30m
      "sudo puppet agent --server puppet.regnal.local --test",
      "sudo puppet agent --server puppet.regnal.local",
    ]
  }

  # Clean puppet certificate on destroy
  provisioner "remote-exec" {
    when       = "destroy"
    on_failure = "continue"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.puppet.public_ip
      private_key = "${file("~/.ssh/terraform")}"
    }
    inline = [
      "sudo rm /var/lib/puppet/ssl/ca/signed/ca.regnal.local.pem"
    ]
  }
}

resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  depends_on = [
    aws_instance.ca,
    aws_instance.rex,
    aws_instance.voting,
    aws_route53_record.ca,
    aws_route53_record.rex,
    aws_route53_record.voting,
  ]

  # VPC
  subnet_id = "${aws_subnet.regnal.id}"
  vpc_security_group_ids = [
    "${aws_security_group.regnal.id}",
    "${aws_security_group.emojivoto_web.id}"
  ]

  # Required to use remote-exec
  associate_public_ip_address = true

  # Set hostname using cloud-init
  user_data = "#cloud-config\nhostname: web\nfqdn: web.regnal.local"

  tags = {
    Name = "regnal-web"
  }

  # Provision with puppet
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.web.public_ip
      private_key = "${file("~/.ssh/terraform")}"
    }

    inline = [
      "set -x",
      # apt-get update fails often, sometimes writing the cache
      "sudo apt-get update || sudo apt-get update", "sudo apt-get update",
      "sudo apt-get -y install puppet",
      # Run once and daemonize, it will refresh every 30m
      "sudo puppet agent --server puppet.regnal.local --test",
      "sudo puppet agent --server puppet.regnal.local",
    ]
  }

  # Clean puppet certificate on destroy
  provisioner "remote-exec" {
    when       = "destroy"
    on_failure = "continue"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.puppet.public_ip
      private_key = "${file("~/.ssh/terraform")}"
    }
    inline = [
      "sudo rm /var/lib/puppet/ssl/ca/signed/web.regnal.local.pem"
    ]
  }
}

resource "aws_instance" "rex" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  depends_on = [
    aws_instance.ca,
    aws_route53_record.ca,
  ]

  # VPC
  subnet_id              = "${aws_subnet.regnal.id}"
  vpc_security_group_ids = ["${aws_security_group.regnal.id}"]

  # Required to use remote-exec
  associate_public_ip_address = true

  # Set hostname using cloud-init
  user_data = "#cloud-config\nhostname: rex\nfqdn: rex.regnal.local"

  tags = {
    Name = "regnal-rex"
  }

  # Provision with puppet
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.rex.public_ip
      private_key = "${file("~/.ssh/terraform")}"
    }

    inline = [
      "set -x",
      # apt-get update fails often, sometimes writing the cache
      "sudo apt-get update || sudo apt-get update", "sudo apt-get update",
      "sudo apt-get -y install puppet",
      # Run once and daemonize, it will refresh every 30m
      "sudo puppet agent --server puppet.regnal.local --test",
      "sudo puppet agent --server puppet.regnal.local",
    ]
  }

  # Clean puppet certificate on destroy
  provisioner "remote-exec" {
    when       = "destroy"
    on_failure = "continue"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.puppet.public_ip
      private_key = "${file("~/.ssh/terraform")}"
    }
    inline = [
      "sudo rm /var/lib/puppet/ssl/ca/signed/rex.regnal.local.pem"
    ]
  }
}

resource "aws_instance" "voting" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  depends_on = [
    aws_instance.ca,
    aws_route53_record.ca,
  ]

  # VPC
  subnet_id              = "${aws_subnet.regnal.id}"
  vpc_security_group_ids = ["${aws_security_group.regnal.id}"]

  # Required to use remote-exec
  associate_public_ip_address = true

  # Set hostname using cloud-init
  user_data = "#cloud-config\nhostname: voting\nfqdn: voting.regnal.local"

  tags = {
    Name = "regnal-voting"
  }

  # Provision with puppet
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.voting.public_ip
      private_key = "${file("~/.ssh/terraform")}"
    }

    inline = [
      "set -x",
      # apt-get update fails often, sometimes writing the cache
      "sudo apt-get update || sudo apt-get update", "sudo apt-get update",
      "sudo apt-get -y install puppet",
      # Run once and daemonize, it will refresh every 30m
      "sudo puppet agent --server puppet.regnal.local --test",
      "sudo puppet agent --server puppet.regnal.local",
    ]
  }

  # Clean puppet certificate on destroy
  provisioner "remote-exec" {
    when       = "destroy"
    on_failure = "continue"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.puppet.public_ip
      private_key = "${file("~/.ssh/terraform")}"
    }
    inline = [
      "sudo rm /var/lib/puppet/ssl/ca/signed/voting.regnal.local.pem"
    ]
  }
}
