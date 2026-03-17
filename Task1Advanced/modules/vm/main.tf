terraform {
    required_providers {
        yandex = {
            source = "yandex-cloud/yandex"
        }
    }
    required_version = ">= 0.13"
}

provider "yandex" {
    zone = var.zone
}

data "yandex_compute_image" "ubuntu" {
    family = "ubuntu-2004-lts"
}

resource "yandex_vpc_network" "network" {
    name = "${var.env_name}-net"
}

resource "yandex_vpc_subnet" "subnet" {
    name           = "${var.env_name}-subnet"
    zone           = var.zone
    network_id     = yandex_vpc_network.network.id
    v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_disk" "boot-disk" {
    name     = "${var.env_name}-disk"
    type     = "network-ssd"
    zone     = var.zone
    image_id = data.yandex_compute_image.ubuntu.image_id
    size     = var.disk_size
}

resource "yandex_compute_instance" "app-vm" {
    count = var.instance_count

    name = "${var.env_name}-app-${count.index}"

    platform_id = "standard-v2"

    resources {
        cores  = var.cores
        memory = var.memory
    }

    boot_disk {
        disk_id = yandex_compute_disk.boot-disk.id
    }

    network_interface {
        subnet_id = yandex_vpc_subnet.subnet.id
        nat       = true
    }

    metadata = {
        ssh-keys = "ubuntu:${file(var.ssh_pub_key_path)}"
    }
}



