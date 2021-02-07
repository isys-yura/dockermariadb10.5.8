provider "kubernetes" {
  config_path = "kuberAPIConf"
}

resource "kubernetes_service" "mysql" {
  metadata {
    name = "mysql"
    labels = {
      app = "mysql"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.mysql.spec.0.template.0.metadata[0].labels.app
    }
    port {
      port        = 3306
      protocol = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "mysql" {
  metadata {
    name = "mysql"
  }

  spec {
    selector {
      match_labels = {
        app = "mysql"
        tier = "mysql"
      }
    }
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        labels = {
          app = "mysql"
          tier = "mysql"
        }
      }
      spec {
        container {
          image = "yurabes/dockermariadb10.5.8:DOCKER_TAG"
          name  = "mysql"
          port {
            container_port = 3306
          }
          volume_mount {
            name = "db-storage"
            mount_path = "/var/lib/mysql"
          }
        }
        volume { 
          name = "db-storage"
          persistent_volume_claim {
             claim_name = "claim-db"
          } 
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "claim-db-volume" {
  metadata {
    name = "claim-db-volume"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_persistent_volume" "claim-db" {
  metadata {
    name = "claim-db"
  }
  spec {
    capacity = {
      storage = "1Gi"
    }
    storage_class_name = "fast"
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      host_path {
        path = "/mnt/data"
    }
  }
}
