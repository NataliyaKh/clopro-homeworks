resource "yandex_alb_load_balancer" "lamp_alb" {
  name       = "lamp-alb"
  folder_id  = var.yc_folder_id
  network_id = yandex_vpc_network.vpc.id

  allocation_policy {
    location {
      subnet_id = yandex_vpc_subnet.public.id
      zone_id   = "ru-central1-a"
    }
  }

  listener {
    name = "http-listener"

    http {
      handler {
        http_router_id = yandex_alb_http_router.http_router.id
      }
    }

    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
  }
}

resource "yandex_alb_http_router" "http_router" {
  name = "lamp-router"
}

resource "yandex_alb_virtual_host" "virtual_host" {
  name           = "lamp-virtual-host"
  http_router_id = yandex_alb_http_router.http_router.id

  route {
    name = "default-route"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.lamp_backend_group.id
      }
    }
  }
}

resource "yandex_alb_backend_group" "lamp_backend_group" {
  name      = "lamp-backend-group"
  folder_id = var.yc_folder_id

  http_backend {
    name             = "lamp-http-backend"
    target_group_ids  = [yandex_compute_instance_group.lamp_group.application_load_balancer[0].target_group_id]
    port             = 80

    healthcheck {
      timeout             = "5s"
      interval            = "10s"
      healthy_threshold   = 2
      unhealthy_threshold = 2

      http_healthcheck {
        path = "/"
      }
    }
  }
}
