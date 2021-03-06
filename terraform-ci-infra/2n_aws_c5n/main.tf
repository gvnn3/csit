provider "aws" {
  region = "eu-central-1"
}

variable "avail_zone" {
  type = string
  default = "eu-central-1a"
}
# Base VPC CIDRs
variable "vpc_cidr_mgmt" {
  type = string
  default = "192.168.0.0/24"
}
variable "vpc_cidr_b" {
  type = string
  default = "192.168.10.0/24"
}
variable "vpc_cidr_c" {
  type = string
  default = "200.0.0.0/24"
}
variable "vpc_cidr_d" {
  type = string
  default = "192.168.20.0/24"
}

# Trex Dummy CIDRs
variable "trex_dummy_cidr_port_0" {
  type = string
  default = "10.0.0.0/24"
}
variable "trex_dummy_cidr_port_1" {
  type = string
  default = "20.0.0.0/24"
}

# IPs
variable "tg_if1_ip" {
  type = string
  default = "192.168.10.254"
}
variable "tg_if2_ip" {
  type = string
  default = "192.168.20.254"
}
variable "dut1_if1_ip" {
  type = string
  default = "192.168.10.11"
}
variable "dut1_if2_ip" {
  type = string
  default = "192.168.20.11"
}
variable "tg_mgmt_ip" {
  type = string
  default = "192.168.0.10"
}
variable "dut1_mgmt_ip" {
  type = string
  default = "192.168.0.11"
}

# Instance Type
variable "instance_type" {
  type = string
  default = "c5n.2xlarge"
}

resource "aws_vpc" "CSIT" {
  cidr_block = var.vpc_cidr_mgmt
}

resource "aws_security_group" "CSIT" {
  name        = "CSIT"
  description = "Allow inbound traffic"
  vpc_id = aws_vpc.CSIT.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = -1
    self = true
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_vpc.CSIT]
}

resource "aws_vpc_ipv4_cidr_block_association" "b" {
  vpc_id = aws_vpc.CSIT.id
  cidr_block = var.vpc_cidr_b
  depends_on = [aws_vpc.CSIT]
}
resource "aws_vpc_ipv4_cidr_block_association" "c" {
  vpc_id = aws_vpc.CSIT.id
  cidr_block = var.vpc_cidr_c
  depends_on = [aws_vpc.CSIT]
}
resource "aws_vpc_ipv4_cidr_block_association" "d" {
  vpc_id = aws_vpc.CSIT.id
  cidr_block = var.vpc_cidr_d
  depends_on = [aws_vpc.CSIT]
}

resource "aws_subnet" "mgmt" {
  vpc_id = aws_vpc.CSIT.id
  cidr_block = var.vpc_cidr_mgmt
  availability_zone = var.avail_zone
  depends_on = [aws_vpc.CSIT]
}

resource "aws_subnet" "b" {
  vpc_id = aws_vpc.CSIT.id
  cidr_block = var.vpc_cidr_b
  availability_zone = var.avail_zone
  depends_on = [aws_vpc.CSIT, aws_vpc_ipv4_cidr_block_association.b]
}

resource "aws_subnet" "c" {
  vpc_id = aws_vpc.CSIT.id
  cidr_block = var.vpc_cidr_c
  availability_zone = var.avail_zone
  depends_on = [aws_vpc.CSIT, aws_vpc_ipv4_cidr_block_association.c]
}

resource "aws_subnet" "d" {
  vpc_id = aws_vpc.CSIT.id
  cidr_block = var.vpc_cidr_d
  availability_zone = var.avail_zone
  depends_on = [aws_vpc.CSIT, aws_vpc_ipv4_cidr_block_association.d]
}

resource "aws_internet_gateway" "CSIT" {
  vpc_id = aws_vpc.CSIT.id
  depends_on = [aws_vpc.CSIT]
}

resource "aws_key_pair" "CSIT" {
  key_name = "CSIT"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["*hvm-ssd/ubuntu-bionic-18.04-amd64*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_placement_group" "CSIT" {
  name = "CSIT"
  strategy = "cluster"
}

resource "aws_instance" "tg" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
#  cpu_threads_per_core = 1
#  cpu_core_count = 18
  key_name = aws_key_pair.CSIT.key_name
  associate_public_ip_address = true
  subnet_id = aws_subnet.mgmt.id
  root_block_device {
    volume_size = 50
  }
  private_ip = var.tg_mgmt_ip
  vpc_security_group_ids = [aws_security_group.CSIT.id]
  depends_on = [aws_vpc.CSIT, aws_placement_group.CSIT]
  placement_group = aws_placement_group.CSIT.id
  source_dest_check = false
}

resource "aws_instance" "dut1" {
  ami = data.aws_ami.ubuntu.id
#  cpu_threads_per_core = 1
#  cpu_core_count = 18
  instance_type = var.instance_type
  key_name = aws_key_pair.CSIT.key_name
  associate_public_ip_address = true
  subnet_id = aws_subnet.mgmt.id
  root_block_device {
    volume_size = 50
  }
  private_ip = var.dut1_mgmt_ip
  vpc_security_group_ids = [aws_security_group.CSIT.id]
  depends_on = [aws_vpc.CSIT, aws_placement_group.CSIT]
  placement_group = aws_placement_group.CSIT.id
  source_dest_check = false
}

resource "aws_route" "CSIT-igw" {
  route_table_id = aws_vpc.CSIT.main_route_table_id
  gateway_id = aws_internet_gateway.CSIT.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on = [aws_vpc.CSIT, aws_internet_gateway.CSIT]
}
resource "aws_route" "dummy-trex-port-0" {
  route_table_id = aws_vpc.CSIT.main_route_table_id
  network_interface_id = aws_instance.tg.primary_network_interface_id
  destination_cidr_block = var.trex_dummy_cidr_port_0
  depends_on = [aws_vpc.CSIT, aws_instance.dut1]
}
resource "aws_route" "dummy-trex-port-1" {
  route_table_id = aws_vpc.CSIT.main_route_table_id
  network_interface_id = aws_instance.tg.primary_network_interface_id
  destination_cidr_block = var.trex_dummy_cidr_port_1
  depends_on = [aws_vpc.CSIT, aws_instance.dut1]
}

resource "null_resource" "deploy_tg" {
  depends_on = [ aws_instance.tg ]
  connection {
    user = "ubuntu"
    host = aws_instance.tg.public_ip
    private_key = file("~/.ssh/id_rsa")
  }
  provisioner "ansible" {
    plays {
      playbook {
        file_path = "../../testbed-setup/ansible/site_aws.yaml"
        force_handlers = true
      }
      hosts = ["tg"]
      extra_vars = {
        ansible_python_interpreter = "/usr/bin/python3"
        aws = true
      }
    }
  }
}
resource "null_resource" "deploy_dut1" {
  depends_on = [ aws_instance.dut1 ]
  connection {
    user = "ubuntu"
    host = aws_instance.dut1.public_ip
    private_key = file("~/.ssh/id_rsa")
  }
  provisioner "ansible" {
    plays {
      playbook {
        file_path = "../../testbed-setup/ansible/site_aws.yaml"
        force_handlers = true
      }
      hosts = ["sut"]
      extra_vars = {
        ansible_python_interpreter = "/usr/bin/python3"
        aws = true
      }
    }
  }
}

resource "null_resource" "deploy_topology" {
  depends_on = [ aws_instance.tg, aws_instance.dut1 ]
  provisioner "ansible" {
    plays {
      playbook {
        file_path = "../../testbed-setup/ansible/cloud_topology.yaml"
      }
      hosts = ["local"]
      extra_vars = {
        ansible_python_interpreter = "/usr/bin/python3"
        cloud_topology = "2n_aws_c5n"
        tg_if1_mac = data.aws_network_interface.tg_if1.mac_address
        tg_if2_mac = data.aws_network_interface.tg_if2.mac_address
        dut1_if1_mac = data.aws_network_interface.dut1_if1.mac_address
        dut1_if2_mac = data.aws_network_interface.dut1_if2.mac_address
        tg_public_ip = aws_instance.tg.public_ip
        dut1_public_ip = aws_instance.dut1.public_ip
      }
    }
  }
}

output "dbg_tg" {
  value = "TG IP: ${aws_instance.tg.public_ip}"
}

output "dbg_dut1" {
  value = "DUT1 IP: ${aws_instance.dut1.public_ip}"
}

