variable "app_name" {
  description = "Name der Anwendung"
  type        = string
  default     = "weather-processor"
}

variable "replica_count" {
  description = "Anzahl der Instanzen"
  type        = number
  default     = 3
}

variable "container_port" {
  description = "Port für den Container"
  type        = number
  default     = 80
}

variable "cluster_context" {
  default = "kind-milad-cluster"
}
