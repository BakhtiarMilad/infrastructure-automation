resource "kubernetes_namespace_v1" "weather_ns" {
  metadata {
    name = "weather-app-system"
  }
}

terraform {
  backend "s3" {
    bucket  = "iac-project-tfstate-milad"
    key     = "state.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}

# --- 1. PROVIDER KONFIGURATION ---
# Wir sagen Terraform, wie es auf den 'kind'-Cluster zugreifen kann.
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.cluster_context
}

# --- 3. CONFIGMAP (DIE WETTER-KONFIGURATION) ---
# Das simuliert die Einstellungen für Satelliten-Datenströme.
resource "kubernetes_config_map_v1" "weather_settings" {
  metadata {
    name = "weather-config"
    namespace = kubernetes_namespace_v1.weather_ns.metadata[0].name
  }

  data = {
    "weather_config.json" = jsonencode({
      station_id = "EUMETSAT-WEITERSTADT-01"
      frequency  = "5min"
      sensors    = ["temp", "humidity", "cloud_cover"]
      project    = "IaC-Automation"
    })
  }
}

# --- 4. DEPLOYMENT ---
# Das Herzstück: Hier wird die Applikation definiert.
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = var.app_name
    namespace = kubernetes_namespace_v1.weather_ns.metadata[0].name
  }

  spec {
    replicas = var.replica_count
    selector {
      match_labels = {
        app = var.app_name
      }
    }
    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }
      spec {
        # security context auf Pod-Ebene (CKV_K8S_30)
        security_context {
          run_as_non_root = true
          run_as_user = 101 #standard-ID for the Nginx-User
          fs_group = 101
        }
        # Hier binden wir die ConfigMap als virtuelles Laufwerk (Volume) ein
        volume {
          name = "config-volume"
          config_map {
            name = kubernetes_config_map.weather_settings.metadata[0].name
          }
        }

        volume {
          name = "nginx-cashe"
          empty_dir {}
        }
        volume {
          name = "nginx-run"
          empty_dir {}
        }

        container {
          image = "nginx:1.25.3@sha256:2bdc49f2f8ae1d8dbdb68ae9f5f48ef746c0721094031f6aa9ebcb726485749a"
          name  = "nginx-container"

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }

            initial_delay_seconds = 15
            period_seconds = 20
            timeout_seconds = 5
            failure_threshold = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds = 10
          }

          resources {
            requests = {
              cpu = "100m" #100 milliCPUs (0.1 Kerne)
              memory = "128Mi"
            }

            limits = {
              cpu = "500m" #500 milliCPUs (0.5 Kerne)
              memory = "256MI"
            }
          }

          #security context on container level
          security_context {
            read_only_root_filesystem = true
            run_as_non_root = true
            run_as_user = 101
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }

          port {
            container_port = 80
          }

          # Hier sagen wir dem Container, WO er die Datei finden soll
          volume_mount {
            name       = "config-volume"
            mount_path = "/usr/share/nginx/html/wetter.json"
            sub_path   = "weather_config.json"
            read_only  = true
          }
          # Diese Mounts erlauben Nginx das Schreiben trotz Read-Only FS:
          volume_mount {
            name       = "nginx-cache"
            mount_path = "/var/cache/nginx"
          }
          volume_mount {
          name       = "nginx-run"
          mount_path = "/var/run"
          }
        }
      }
    }
  }
}
