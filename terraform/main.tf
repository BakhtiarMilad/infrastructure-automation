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
  config_context = "kind-milad-for-eumetsat"
}

# --- 3. CONFIGMAP (DIE WETTER-KONFIGURATION) ---
# Das simuliert die Einstellungen für Satelliten-Datenströme.
resource "kubernetes_config_map" "weather_settings" {
  metadata {
    name = "weather-config"
  }

  data = {
    "weather_config.json" = jsonencode({
      station_id = "EUMETSAT-DARMSTADT-01"
      frequency  = "5min"
      sensors    = ["temp", "humidity", "cloud_cover"]
      project    = "VN-26-05-Automation"
    })
  }
}

# --- 4. DEPLOYMENT ---
# Das Herzstück: Hier wird die Applikation definiert.
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = var.app_name
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
        # Hier binden wir die ConfigMap als virtuelles Laufwerk (Volume) ein
        volume {
          name = "config-volume"
          config_map {
            name = kubernetes_config_map.weather_settings.metadata[0].name
          }
        }

        container {
          image = "nginx:latest"
          name  = "nginx-container"

          port {
            container_port = 80
          }

          # Hier sagen wir dem Container, WO er die Datei finden soll
          volume_mount {
            name       = "config-volume"
            mount_path = "/etc/weather"
            read_only  = true
          }
        }
      }
    }
  }
}
