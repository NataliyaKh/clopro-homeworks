resource "yandex_compute_instance_group" "lamp_group" {
  name               = "lamp-instance-group"
  folder_id          = var.yc_folder_id
  service_account_id = var.yc_instance_service_account_id

  instance_template {
    platform_id = "standard-v1"

    resources {
      cores         = 2
      memory        = 1
      core_fraction = 20
    }

    boot_disk {
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
      }
    }

    network_interface {
      network_id = yandex_vpc_network.vpc.id
      subnet_ids = [yandex_vpc_subnet.public.id]
      nat        = true
    }

    metadata = {
      ssh-keys = "ubuntu:${var.public_key}"

      user-data = <<-EOT
        #!/bin/bash
        echo "<html><body><h1>Hello from LAMP instance!</h1><img src='https://storage.yandexcloud.net/nkh-2025-09-09/trees.jpg' /></body></html>" > /var/www/html/index.html
      EOT
    }

    scheduling_policy {
      preemptible = true
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 1
  }

  health_check {
    http_options {
      port = 80
      path = "/"
    }
  }

#  load_balancer {
#    target_group_name = "lamp-target-group"
#  }

  application_load_balancer {
  target_group_name = "lamp-alb-target-group"
}

  timeouts {
    create = "60m"
    delete = "30m"
  }
}
