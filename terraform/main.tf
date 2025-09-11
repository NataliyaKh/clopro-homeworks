terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.99"
    }
  }
}

provider "yandex" {
  #  token     = var.yc_token
  cloud_id                 = var.yc_cloud_id
  folder_id                = var.yc_folder_id
  service_account_key_file = "/home/vboxuser/auth-k.json"
  #  zone      = "ru-central1-a"
}

# Облачная сеть (VPC)
resource "yandex_vpc_network" "vpc" {
  name = "clopro-vpc"
}

resource "yandex_vpc_security_group" "default_sg" {
  name       = "allow-ssh-icmp"
  network_id = yandex_vpc_network.vpc.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Публичная подсеть
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# NAT-инстанс
resource "yandex_compute_instance" "nat_instance" {
  name        = "nat-instance"
  hostname    = "nat-instance"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    ip_address         = "192.168.10.254"
    nat                = true
    security_group_ids = [yandex_vpc_security_group.default_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.public_key}"
  }

  scheduling_policy {
    preemptible = true
  }
}

#Публичная ВМ
resource "yandex_compute_instance" "public_vm" {
  name        = "public-vm"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true # дает публичный IP автоматически
    security_group_ids = [yandex_vpc_security_group.default_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.public_key}"
  }

  scheduling_policy {
    preemptible = true
  }
}

# Приватная подсеть
resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private_rt.id
}

# Таблица маршрутов
resource "yandex_vpc_route_table" "private_rt" {
  name       = "private-rt"
  network_id = yandex_vpc_network.vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254" # IP NAT-инстанса
  }
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# ВМ в приватной подсети
resource "yandex_compute_instance" "private_vm" {
  name        = "private-vm"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.default_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.public_key}"
  }

  scheduling_policy {
    preemptible = true
  }
}
